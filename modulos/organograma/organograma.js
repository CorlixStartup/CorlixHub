/* ==========================================================================
   Corlix Hub · Organograma (navegação por níveis + drawer de detalhes)
   ========================================================================== */

/* --------------------------------------------------------------------------
   Page Attributes > JavaScript > Function and Global Variable Declaration
   -------------------------------------------------------------------------- */
const ORG_ITEM_FOCO         = "P10_ID_FOCO";   // item oculto com o colaborador em foco
const ORG_REGIAO            = "organograma";   // Static ID da região Dynamic Content
const ORG_PROCESSO_DETALHES = "ORG_DETALHES";  // Ajax Callback que devolve o HTML do drawer

let orgDrawer = null;
let orgPedido = 0;   // descarta respostas antigas se o usuário clicar rápido

function orgId(valor) {
  const id = Number(valor);
  return Number.isFinite(id) && id > 0 ? id : null;
}

/* Organograma: troca a pessoa em foco e atualiza só a região */
function orgIrPara(valor) {
  const id = orgId(valor);
  if (!id) return;
  apex.item(ORG_ITEM_FOCO).setValue(String(id));
  apex.region(ORG_REGIAO).refresh();
}

/* Drawer: criado uma vez, como <dialog> nativo (scrim, Esc e foco preso) */
function orgObterDrawer() {
  if (orgDrawer) return orgDrawer;

  orgDrawer = document.createElement("dialog");
  orgDrawer.className = "org-drawer";
  orgDrawer.setAttribute("aria-labelledby", "org-drawer-nome");
  orgDrawer.innerHTML = '<div class="org-drawer__painel"></div>';
  orgDrawer.addEventListener("click", orgCliqueNoDrawer);
  document.body.appendChild(orgDrawer);

  return orgDrawer;
}

function orgEstado(html) {
  return '<div class="org-drawer__estado">' + html + "</div>";
}

function orgAbrirDetalhes(valor) {
  const id = orgId(valor);
  if (!id) return;

  const drawer = orgObterDrawer();
  const painel = drawer.firstElementChild;
  const pedido = ++orgPedido;

  painel.setAttribute("aria-busy", "true");
  painel.innerHTML = orgEstado(
    '<span class="org-spinner" aria-hidden="true"></span><p>Carregando detalhes…</p>'
  );
  if (!drawer.open) drawer.showModal();

  apex.server.process(ORG_PROCESSO_DETALHES, { x01: id }, { dataType: "text" })
    .done(function (html) {
      if (pedido !== orgPedido) return;
      painel.innerHTML = html;
      const titulo = painel.querySelector("#org-drawer-nome");
      if (titulo) titulo.focus();
    })
    .fail(function () {
      if (pedido !== orgPedido) return;
      painel.innerHTML = orgEstado(
        "<p>Não foi possível carregar os detalhes.</p>" +
        '<button type="button" class="org-btn org-btn--auto" data-acao="detalhe" data-id="' + id + '">' +
        "Tentar novamente</button>" +
        '<button type="button" class="org-link" data-acao="fechar">Fechar</button>'
      );
    })
    .always(function () {
      if (pedido === orgPedido) painel.removeAttribute("aria-busy");
    });
}

function orgCopiar(botao) {
  if (!navigator.clipboard) return;
  const aviso = botao.parentElement.querySelector(".org-sr");

  navigator.clipboard.writeText(botao.dataset.valor).then(function () {
    botao.classList.add("is-copiado");
    botao.setAttribute("aria-label", "E-mail copiado");
    if (aviso) aviso.textContent = "E-mail copiado.";

    setTimeout(function () {
      botao.classList.remove("is-copiado");
      botao.setAttribute("aria-label", "Copiar e-mail");
      if (aviso) aviso.textContent = "";
    }, 2000);
  });
}

function orgCliqueNoDrawer(ev) {
  const drawer = ev.currentTarget;

  // clique no fundo escurecido fecha
  if (ev.target === drawer) {
    drawer.close();
    return;
  }

  const alvo = ev.target.closest("[data-acao]");
  if (!alvo) return;

  switch (alvo.dataset.acao) {
    case "fechar":
      drawer.close();
      break;
    case "detalhe":            // gestor ou alguém da equipe: troca o conteúdo
      orgAbrirDetalhes(alvo.dataset.id);
      break;
    case "equipe":             // "Ver equipe no organograma"
      drawer.close();
      orgIrPara(alvo.dataset.id);
      break;
    case "copiar":
      orgCopiar(alvo);
      break;
  }
}


/* --------------------------------------------------------------------------
   Page Attributes > JavaScript > Execute when Page Loads
   -------------------------------------------------------------------------- */
// Caminho e "Ver equipe" -> data-acao="foco"; card e "Ver perfil" -> data-acao="detalhe"
$("#" + ORG_REGIAO).on("click", "[data-acao]", function () {
  if (this.dataset.acao === "foco") {
    orgIrPara(this.dataset.id);
  } else if (this.dataset.acao === "detalhe") {
    orgAbrirDetalhes(this.dataset.id);
  }
});

// Após trocar de nível, leva o foco do teclado para o nome da pessoa em foco
$("#" + ORG_REGIAO).on("apexafterrefresh", function () {
  const titulo = document.getElementById("org-foco-nome");
  if (titulo) titulo.focus({ preventScroll: true });
});


/* --------------------------------------------------------------------------
   Dynamic Action: Change em P10_BUSCA (Popup LOV) > Execute JavaScript Code
   -------------------------------------------------------------------------- */
// const id = $v("P10_BUSCA");
// if (id) {
//   orgIrPara(id);
//   apex.item("P10_BUSCA").setValue("", null, true); // limpa sem disparar Change de novo
// }

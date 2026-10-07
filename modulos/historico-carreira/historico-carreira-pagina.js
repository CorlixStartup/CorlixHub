/* =============================================================================
   Corlix Hub · Histórico de carreira (página 13)
   Abas (Tudo / Movimentações / Desenvolvimento), filtro de ano e Exportar PDF.

   Dois blocos:
     1. Page > JavaScript > Function and Global Variable Declaration
     2. Page > JavaScript > Execute when Page Loads

   Os eventos são delegados a partir do document, então continuam funcionando
   depois que a região é atualizada (ex.: ao fechar a modal de movimentação).
   ========================================================================== */


/* --- 1. Function and Global Variable Declaration ------------------------- */

var hc = hc || {};

hc.plural = function (qtd) {
  return qtd + (qtd === 1 ? " registro" : " registros");
};

/** Aplica a aba e o ano escolhidos: esconde eventos e recalcula os cabeçalhos de ano. */
hc.filtrar = function (raiz) {
  var aba   = raiz.querySelector('[role="tab"][aria-selected="true"]');
  var grupo = aba ? aba.getAttribute("data-hc-filtro") : "tudo";
  var seletorAno = raiz.querySelector("[data-hc-ano]");
  var ano   = seletorAno ? seletorAno.value : "";
  var porAno = {};
  var visiveis = [];

  raiz.querySelectorAll(".hc-evento").forEach(function (ev) {
    var mostra = (grupo === "tudo" || ev.getAttribute("data-grupo") === grupo)
              && (!ano || ev.getAttribute("data-ano") === ano);
    ev.hidden = !mostra;
    ev.classList.remove("is-ultimo");
    if (mostra) {
      visiveis.push(ev);
      porAno[ev.getAttribute("data-ano")] = (porAno[ev.getAttribute("data-ano")] || 0) + 1;
    }
  });

  // Último evento visível não puxa a linha vertical para baixo
  if (visiveis.length) {
    visiveis[visiveis.length - 1].classList.add("is-ultimo");
  }

  var primeiroAno = true;
  raiz.querySelectorAll(".hc-ano").forEach(function (cab) {
    var qtd = porAno[cab.getAttribute("data-ano")] || 0;
    cab.hidden = qtd === 0;
    var rotulo = cab.querySelector(".hc-ano__qt");
    if (rotulo) { rotulo.textContent = hc.plural(qtd); }
    cab.classList.toggle("is-primeiro", qtd > 0 && primeiroAno);
    if (qtd > 0) { primeiroAno = false; }
  });

  var vazio = raiz.querySelector("[data-hc-sem-resultado]");
  if (vazio) { vazio.hidden = visiveis.length > 0; }
};

hc.iniciar = function () {
  if (hc.iniciado) { return; }
  hc.iniciado = true;

  document.addEventListener("click", function (evento) {
    var raiz = evento.target.closest("[data-hc]");
    if (!raiz) { return; }

    var aba = evento.target.closest("[data-hc-filtro]");
    if (aba) {
      raiz.querySelectorAll("[data-hc-filtro]").forEach(function (b) {
        b.setAttribute("aria-selected", String(b === aba));
      });
      hc.filtrar(raiz);
      return;
    }

    if (evento.target.closest('[data-hc-acao="exportar"]')) {
      window.print();
    }
  });

  document.addEventListener("change", function (evento) {
    if (evento.target.matches("[data-hc-ano]")) {
      hc.filtrar(evento.target.closest("[data-hc]"));
    }
  });

  // Setas esquerda/direita entre as abas (padrão WAI-ARIA de tablist)
  document.addEventListener("keydown", function (evento) {
    var aba = evento.target.closest && evento.target.closest("[data-hc] [role='tab']");
    if (!aba || (evento.key !== "ArrowRight" && evento.key !== "ArrowLeft")) { return; }
    var abas = Array.prototype.slice.call(aba.parentNode.querySelectorAll("[role='tab']"));
    var i = abas.indexOf(aba) + (evento.key === "ArrowRight" ? 1 : -1);
    var destino = abas[(i + abas.length) % abas.length];
    destino.focus();
    destino.click();
  });

  // Ao imprimir, mostra tudo (sem o filtro da tela)
  window.addEventListener("beforeprint", function () {
    document.querySelectorAll("[data-hc] .hc-evento, [data-hc] .hc-ano").forEach(function (el) {
      el.setAttribute("data-hc-oculto", el.hidden ? "1" : "0");
      el.hidden = false;
    });
  });
  window.addEventListener("afterprint", function () {
    document.querySelectorAll("[data-hc] [data-hc-oculto]").forEach(function (el) {
      el.hidden = el.getAttribute("data-hc-oculto") === "1";
      el.removeAttribute("data-hc-oculto");
    });
  });
};

/** Chamado no carregamento e depois de cada refresh da região. */
hc.preparar = function () {
  document.querySelectorAll("[data-hc]").forEach(hc.filtrar);
};


/* --- 2. Execute when Page Loads ------------------------------------------ */

hc.iniciar();
hc.preparar();
$("#historico_carreira").on("apexafterrefresh", hc.preparar);

/* ==========================================================================
   Corlix Hub · Organograma (navegação por níveis)
   ========================================================================== */

/* --------------------------------------------------------------------------
   Page Attributes > JavaScript > Function and Global Variable Declaration
   -------------------------------------------------------------------------- */
const ORG_ITEM_FOCO = "P10_ID_FOCO";   // item oculto com o colaborador em foco
const ORG_REGIAO    = "organograma";   // Static ID da região Dynamic Content

function orgIrPara(id) {
  if (!id) return;
  apex.item(ORG_ITEM_FOCO).setValue(String(id));
  apex.region(ORG_REGIAO).refresh();
}


/* --------------------------------------------------------------------------
   Page Attributes > JavaScript > Execute when Page Loads
   -------------------------------------------------------------------------- */
// Caminho, nome do subordinado e "Ver equipe" usam a mesma classe
$("#" + ORG_REGIAO).on("click", ".js-org-foco", function () {
  orgIrPara(this.dataset.id);
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

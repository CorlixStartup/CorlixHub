/* =============================================================================
   Corlix Hub · Histórico de Carreira · Modal Nova/Editar Movimentação (página 18)

   Três blocos, cada um em um lugar da página:
     1. Page > JavaScript > Function and Global Variable Declaration
     2. Page > JavaScript > Execute when Page Loads
     3. Dynamic Action "Change" em P18_ID_TIPO_MOVIMENTACAO (ação Execute JavaScript)
   ========================================================================== */


/* --- 1. Function and Global Variable Declaration ------------------------- */

var carreira = carreira || {};

// Em quais tipos cada grupo de campos aparece
carreira.visivelEm = {
  cargo:        ['PROMOCAO', 'MUDANCA_CARGO', 'TRANSFERENCIA_DEPTO', 'ADMISSAO'],
  departamento: ['TRANSFERENCIA_DEPTO', 'ADMISSAO'],
  gestor:       ['PROMOCAO', 'MUDANCA_CARGO', 'TRANSFERENCIA_DEPTO', 'MUDANCA_GESTOR', 'ADMISSAO'],
  salario:      ['PROMOCAO', 'MUDANCA_CARGO', 'MERITO', 'ADMISSAO']
};

// Em quais tipos o grupo é obrigatório (o package valida de novo no servidor)
carreira.obrigatorioEm = {
  cargo:        ['PROMOCAO', 'MUDANCA_CARGO'],
  departamento: ['TRANSFERENCIA_DEPTO'],
  gestor:       ['MUDANCA_GESTOR']
};

carreira.itens = {
  cargo:        ['P18_ID_CARGO_NOVO'],
  departamento: ['P18_ID_DEPARTAMENTO_NOVO'],
  gestor:       ['P18_ID_GESTOR_NOVO'],
  salario:      ['P18_VL_SALARIO_ANTERIOR', 'P18_VL_SALARIO_NOVO']
};

/**
 * Mostra/esconde os campos conforme o tipo escolhido.
 * Campos escondidos são limpos, para não gravar um cargo "fantasma" em um mérito.
 * @param {boolean} limpar  false no carregamento (preserva os valores do rascunho)
 */
carreira.ajustarCampos = function (limpar) {
  var tipo = $v('P18_CD_TIPO');

  Object.keys(carreira.visivelEm).forEach(function (grupo) {
    var visivel     = carreira.visivelEm[grupo].indexOf(tipo) !== -1;
    var obrigatorio = (carreira.obrigatorioEm[grupo] || []).indexOf(tipo) !== -1;

    carreira.itens[grupo].forEach(function (nome) {
      // Item não renderizado (ex.: salário sem ADMIN_RH): ignora
      if (!$x(nome)) { return; }

      var item = apex.item(nome);
      if (visivel) {
        item.show();
      } else {
        item.hide();
        if (limpar !== false && item.getValue()) { item.setValue(''); }
      }
      $('#' + nome + '_CONTAINER').toggleClass('is-required', obrigatorio);
    });
  });
};


/* --- 2. Execute when Page Loads ------------------------------------------ */

carreira.ajustarCampos(false);


/* --- 3. DA Change em P18_ID_TIPO_MOVIMENTACAO ----------------------------
   Ação 1: Set Value (SQL Statement) em P18_CD_TIPO
           select cd_tipo from tipo_movimentacao
            where id_tipo_movimentacao = :P18_ID_TIPO_MOVIMENTACAO
              and id_empresa = :G_ID_EMPRESA
           Items to Submit: P18_ID_TIPO_MOVIMENTACAO
   Ação 2: Execute JavaScript Code com a linha abaixo                        */

carreira.ajustarCampos(true);

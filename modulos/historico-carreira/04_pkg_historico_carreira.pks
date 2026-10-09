--------------------------------------------------------------------------------
-- Corlix Hub · Histórico de Carreira
-- 04 · Package PKG_HISTORICO_CARREIRA (especificação)
--
-- Toda regra de negócio do módulo fica aqui. As páginas APEX nunca fazem DML
-- direto em HISTORICO_CARREIRA: chamam estas rotinas.
--
-- Transação: as rotinas NÃO fazem commit. No APEX o commit acontece ao fim do
-- processamento da página; em scripts, quem chama decide (commit/rollback).
-- A única exceção é REGISTRAR_ACESSO_SALARIAL (transação autônoma).
--------------------------------------------------------------------------------
create or replace package pkg_historico_carreira authid definer as

  ------------------------------------------------------------------------------
  -- Códigos de erro (mensagens amigáveis, ver FN_TRATAR_ERRO)
  ------------------------------------------------------------------------------
  c_err_colaborador     constant pls_integer := -20001;  -- colaborador inexistente ou de outra empresa
  c_err_tipo            constant pls_integer := -20002;  -- tipo de movimentação inválido ou inativo
  c_err_data_admissao   constant pls_integer := -20003;  -- data anterior à admissão / readmissão inválida
  c_err_data_futura     constant pls_integer := -20004;  -- data efetiva além do limite de dias no futuro
  c_err_cargo           constant pls_integer := -20005;  -- cargo novo ausente ou igual ao atual
  c_err_departamento    constant pls_integer := -20006;  -- departamento novo ausente ou igual ao atual
  c_err_desligado       constant pls_integer := -20007;  -- lançamento após desligamento
  c_err_empresa         constant pls_integer := -20008;  -- cargo/departamento/gestor/tipo de outra empresa
  c_err_status          constant pls_integer := -20009;  -- operação incompatível com o status do lançamento
  c_err_retroativo      constant pls_integer := -20010;  -- data anterior à última movimentação efetivada
  c_err_estorno         constant pls_integer := -20011;  -- estorno fora de ordem ou sem situação anterior
  c_err_permissao       constant pls_integer := -20012;  -- usuário sem permissão / sessão sem empresa
  c_err_imutavel        constant pls_integer := -20013;  -- alteração direta de lançamento efetivado (trigger)
  c_err_cargo_depto     constant pls_integer := -20014;  -- cargo não pertence ao departamento
  c_err_motivo          constant pls_integer := -20015;  -- motivo obrigatório
  c_err_admissao        constant pls_integer := -20016;  -- admissão duplicada
  c_err_gestor          constant pls_integer := -20017;  -- gestor inválido
  c_err_registro        constant pls_integer := -20018;  -- lançamento não encontrado
  c_err_solicitacao     constant pls_integer := -20019;  -- solicitação de correção inválida
  c_err_aprovador       constant pls_integer := -20020;  -- aprovador inválido (o próprio colaborador ou outra empresa)

  ------------------------------------------------------------------------------
  -- Domínios
  ------------------------------------------------------------------------------
  c_st_rascunho         constant varchar2(10) := 'RASCUNHO';
  c_st_efetivado        constant varchar2(10) := 'EFETIVADO';
  c_st_estornado        constant varchar2(10) := 'ESTORNADO';

  c_auth_admin_rh       constant varchar2(30) := 'ADMIN_RH';

  -- Padrões usados quando a empresa não tem linha em CONFIG_CARREIRA
  c_dias_futuro_padrao  constant pls_integer  := 30;
  c_fuso_padrao         constant varchar2(64) := 'America/Sao_Paulo';

  ------------------------------------------------------------------------------
  -- Utilitários
  ------------------------------------------------------------------------------

  -- "Hoje" no fuso horário da empresa (o Autonomous Database roda em UTC)
  function fn_hoje (p_id_empresa in number) return date;

  -- Converte um instante (ex.: DT_EFETIVACAO, em UTC) para data/hora local da empresa
  function fn_data_local (p_id_empresa in number, p_momento in timestamp with time zone) return date;

  -- ID do tipo pelo código, dentro da empresa
  function fn_id_tipo (p_id_empresa in number, p_cd_tipo in varchar2) return number;

  ------------------------------------------------------------------------------
  -- Movimentações
  ------------------------------------------------------------------------------

  -- Valida e grava como RASCUNHO. Retorna o ID do lançamento.
  function registrar_movimentacao (
    p_id_colaborador       in number,
    p_id_tipo_movimentacao in number,
    p_dt_efetiva           in date,
    p_id_cargo_novo        in number   default null,
    p_id_departamento_novo in number   default null,
    p_id_gestor_novo       in number   default null,
    p_vl_salario_anterior  in number   default null,
    p_vl_salario_novo      in number   default null,
    p_ds_motivo            in varchar2 default null,
    p_ds_observacao        in clob     default null,
    p_id_aprovador         in number   default null   -- quem aprovou (exibido como "Aprovado por")
  ) return number;

  -- Altera um RASCUNHO (o colaborador não muda)
  procedure atualizar_rascunho (
    p_id_historico_carreira in number,
    p_id_tipo_movimentacao  in number,
    p_dt_efetiva            in date,
    p_id_cargo_novo         in number   default null,
    p_id_departamento_novo  in number   default null,
    p_id_gestor_novo        in number   default null,
    p_vl_salario_anterior   in number   default null,
    p_vl_salario_novo       in number   default null,
    p_ds_motivo             in varchar2 default null,
    p_ds_observacao         in clob     default null,
    p_id_aprovador          in number   default null
  );

  -- Exclui um RASCUNHO (efetivados nunca são excluídos)
  procedure excluir_rascunho (p_id_historico_carreira in number);

  -- RASCUNHO -> EFETIVADO e atualiza cargo, departamento, gestor e status em
  -- COLABORADOR (o organograma passa a refletir a mudança). Admissão, promoção
  -- e transferência publicam um comunicado para a equipe de destino, se
  -- CONFIG_CARREIRA.FL_COMUNICADO_AUTOMATICO estiver ligado. Mesma transação.
  procedure efetivar_movimentacao (p_id in number);

  -- Gera o lançamento de estorno, marca o original como ESTORNADO e devolve o
  -- colaborador à situação do registro válido anterior. Só a última movimentação
  -- válida pode ser estornada.
  procedure estornar_movimentacao (p_id in number, p_motivo in varchar2);

  -- ADMISSAO efetivada a partir dos dados atuais do colaborador. Idempotente:
  -- não faz nada se o colaborador já tiver histórico. Chamada pelo processo de
  -- cadastro de colaborador (página 14, com comunicado de boas-vindas) e pela
  -- carga inicial (sem comunicado).
  procedure registrar_admissao_automatica (
    p_id_colaborador   in number,
    p_gerar_comunicado in boolean default true
  );

  ------------------------------------------------------------------------------
  -- Solicitações de correção
  ------------------------------------------------------------------------------

  -- O próprio colaborador pede ao RH a revisão do histórico. Retorna o ID.
  function solicitar_correcao (
    p_id_colaborador        in number,
    p_ds_mensagem           in varchar2,
    p_id_historico_carreira in number default null
  ) return number;

  -- RH responde: RESOLVIDA (corrigiu por estorno + novo lançamento) ou RECUSADA
  procedure responder_solicitacao (
    p_id_solicitacao in number,
    p_st_solicitacao in varchar2,
    p_ds_resposta    in varchar2 default null
  );

  ------------------------------------------------------------------------------
  -- Consultas
  ------------------------------------------------------------------------------

  -- Período por extenso entre duas datas: "1 ano e 8 meses", "menos de 1 mês"
  function fn_periodo (p_inicio in date, p_fim in date) return varchar2;

  -- Tempo na função atual, por extenso: "2 anos e 3 meses"
  function fn_tempo_no_cargo (p_id_colaborador in number) return varchar2;

  -- Tempo de casa desde a última (re)admissão, por extenso
  function fn_tempo_de_casa (p_id_colaborador in number) return varchar2;

  ------------------------------------------------------------------------------
  -- Segurança e LGPD
  ------------------------------------------------------------------------------

  -- 'S' se o usuário da sessão pode ver o histórico do colaborador:
  -- ADMIN_RH (mesma empresa), o próprio colaborador ou um gestor da cadeia acima dele.
  function fn_pode_ver_colaborador (p_id_colaborador in number) return varchar2;

  -- Registra que dados salariais do colaborador foram exibidos (transação autônoma)
  procedure registrar_acesso_salarial (
    p_id_colaborador in number,
    p_contexto       in varchar2 default null
  );

  -- Empresa do contexto atual: G_ID_EMPRESA em sessão APEX; fora do APEX, o
  -- valor definido por DEFINIR_EMPRESA_CONTEXTO (ou nulo = sem restrição).
  function fn_empresa_contexto return number;

  -- Somente fora do APEX (scripts, jobs e testes). Em sessão APEX gera erro.
  procedure definir_empresa_contexto (p_id_empresa in number);

  -- Função de tratamento de erros do APEX: mostra só a mensagem dos erros
  -- -20001..-20099, sem "ORA-" nem pilha.
  function fn_tratar_erro (p_error in apex_error.t_error) return apex_error.t_error_result;

end pkg_historico_carreira;
/

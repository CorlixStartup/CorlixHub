
  CREATE OR REPLACE EDITIONABLE FUNCTION "CH_GET_CANAL_DIRETO" (
  p_colab_a in number,
  p_colab_b in number
) return number is
  l_id_canal number;
  l_menor    number := least(p_colab_a, p_colab_b);
  l_maior    number := greatest(p_colab_a, p_colab_b);
begin
  select cp1.id_canal into l_id_canal
  from   canal_participante cp1
  join   canal_participante cp2 on cp2.id_canal = cp1.id_canal
  join   canal c                on c.id_canal   = cp1.id_canal
  where  cp1.id_colaborador = p_colab_a
  and    cp2.id_colaborador = p_colab_b
  and    c.tipo = 'DIRETO'
  fetch first 1 row only;

  return l_id_canal;
exception
  when no_data_found then
    insert into canal (nome, tipo, data_criacao, status)
    values ('DM-' || l_menor || '-' || l_maior, 'DIRETO', sysdate, true)
    returning id_canal into l_id_canal;

    insert into canal_participante (id_canal, id_colaborador)
    select l_id_canal, p_colab_a from dual
    union all
    select l_id_canal, p_colab_b from dual;

    return l_id_canal;
end;
/

  CREATE OR REPLACE EDITIONABLE FUNCTION "FN_CARREIRA_VE_SALARIO" return varchar2 is
begin
  if sys_context('APEX$SESSION', 'APP_SESSION') is null then
    return 'N';
  end if;

  return case when apex_authorization.is_authorized('ADMIN_RH') then 'S' else 'N' end;
exception
  when others then
    -- esquema de autorização inexistente ou erro de avaliação: nunca expõe salário
    return 'N';
end fn_carreira_ve_salario;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "LOG_PKG" as
  procedure gravar(p_nivel varchar2, p_msg varchar2, p_origem varchar2 default null, p_detalhe clob default null);
  procedure erro (p_msg varchar2, p_origem varchar2 default null);
  procedure aviso(p_msg varchar2, p_origem varchar2 default null);
  procedure info (p_msg varchar2, p_origem varchar2 default null);
  function apex_error_handler(p_error in apex_error.t_error) return apex_error.t_error_result;
end;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "PKG_COMUNICADO" AS

    -- Cria um comunicado. ID_DEPARTAMENTO NULL = empresa toda.
    FUNCTION CRIAR_COMUNICADO (
        p_id_empresa      IN NUMBER,
        p_id_autor        IN NUMBER,
        p_titulo          IN VARCHAR2,
        p_conteudo        IN CLOB,
        p_id_departamento IN NUMBER DEFAULT NULL,
        p_imagem          IN BLOB DEFAULT NULL,
        p_mime_type       IN VARCHAR2 DEFAULT NULL,
        p_nome_arquivo    IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    -- Marca um comunicado como lido para o colaborador. Idempotente.
    PROCEDURE MARCAR_COMO_LIDO (
        p_id_comunicado  IN NUMBER,
        p_id_colaborador IN NUMBER
    );

    -- Quantidade de comunicados elegíveis (empresa/depto) ainda não lidos.
    FUNCTION QTD_NAO_LIDOS (
        p_id_colaborador IN NUMBER
    ) RETURN NUMBER;

END PKG_COMUNICADO;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "PKG_EQUIPE_CANAL" AS

    -- Cria a equipe e já inclui o criador como ADMIN.
    FUNCTION CRIAR_EQUIPE (
        p_id_empresa      IN NUMBER,
        p_id_criador      IN NUMBER,
        p_nome            IN VARCHAR2,
        p_descricao       IN VARCHAR2 DEFAULT NULL,
        p_id_departamento IN NUMBER DEFAULT NULL
    ) RETURN NUMBER;

    -- Adiciona um colaborador à equipe. Ignora silenciosamente se já for membro.
    PROCEDURE ADICIONAR_MEMBRO (
        p_id_equipe      IN NUMBER,
        p_id_colaborador IN NUMBER,
        p_papel          IN VARCHAR2 DEFAULT 'MEMBRO'
    );

    -- Remove um membro da equipe. Bloqueia se for o único ADMIN restante.
    PROCEDURE REMOVER_MEMBRO (
        p_id_equipe_membro IN NUMBER
    );

    -- Cria um canal dentro de uma equipe.
    FUNCTION CRIAR_CANAL (
        p_id_equipe  IN NUMBER,
        p_nome       IN VARCHAR2,
        p_descricao  IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    -- Envia uma mensagem no canal. Valida que o colaborador é membro da equipe dona do canal.
    FUNCTION ENVIAR_MENSAGEM_CANAL (
        p_id_canal       IN NUMBER,
        p_id_colaborador IN NUMBER,
        p_corpo          IN VARCHAR2
    ) RETURN NUMBER;

    -- Heartbeat de presença — chamado pelo polling do navegador.
    PROCEDURE ATUALIZAR_PRESENCA (
        p_id_colaborador IN NUMBER,
        p_status         IN VARCHAR2 DEFAULT 'ONLINE'
    );

    -- Marca como OFFLINE quem não dá ping há mais de p_minutos_limite minutos.
    -- Chamado por um job DBMS_SCHEDULER a cada 1-2 minutos.
    PROCEDURE ATUALIZAR_OFFLINE (
        p_minutos_limite IN NUMBER DEFAULT 3
    );

END PKG_EQUIPE_CANAL;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "PKG_HISTORICO_CARREIRA" authid definer as

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

  CREATE OR REPLACE EDITIONABLE PACKAGE "PKG_HISTORICO_CARREIRA_UI" authid definer as

  -- Destinos dos links (ajuste para o app). Página nula = o link não aparece.
  c_pagina_organograma constant pls_integer  := 3;
  c_item_organograma   constant varchar2(30) := 'P3_ID_FOCO';
  c_pagina_comunicado  constant pls_integer  := 11;
  c_item_comunicado    constant varchar2(30) := null;   -- ex.: 'P11_ID_COMUNICADO'
  c_pagina_holerite    constant pls_integer  := null;   -- ainda não existe no app
  c_pagina_solicitacao constant pls_integer  := 22;
  c_item_solicitacao   constant varchar2(30) := 'P22_ID_COLABORADOR';
  c_pagina_painel_rh   constant pls_integer  := 20;

  -- HTML completo da página para o colaborador informado.
  -- Gera -20012 se o usuário da sessão não puder ver esse histórico.
  function render (p_id_colaborador in number) return clob;

end pkg_historico_carreira_ui;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "PKG_LOGS" as

end "PKG_LOGS";
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "PKG_ORGANOGRAMA" as
  c_nome_empresa  constant varchar2(100) := 'Corlix';

  c_pagina_perfil constant pls_integer := 20;
  c_item_perfil   constant varchar2(30) := 'P20_ID_COLABORADOR';

  c_pagina_chat   constant pls_integer := 30;
  c_item_chat     constant varchar2(30) := 'P30_ID_COLABORADOR';

  c_max_equipe constant pls_integer := 8;

  function id_raiz return number;

  function render (
    p_id_foco in number,
    p_nome_empresa in varchar2 default c_nome_empresa
  ) return clob;

  function render_detalhes (
    p_id in number,
    p_nome_empresa in varchar2 default c_nome_empresa
  ) return clob;
end pkg_organograma;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "PKG_PERFIS_ACESSO" authid definer as

  c_papel_padrao constant varchar2(30) := 'colaborador';

  -- Static IDs dos papéis do cargo, já com o papel padrão.
  function papeis_do_cargo (p_id_cargo in number) return apex_t_varchar2;

  -- Adiciona ao usuário os papéis do cargo que ele ainda não tem.
  procedure atribuir_papeis (
    p_login          in varchar2,
    p_id_cargo       in number,
    p_application_id in number default to_number(v('APP_ID'))
  );

end pkg_perfis_acesso;
/

  CREATE OR REPLACE EDITIONABLE PROCEDURE "PRC_SEED_TIPO_MOVIMENTACAO" (
  p_id_empresa in number
) is
begin
  merge into tipo_movimentacao t
  using (
    select p_id_empresa as id_empresa, v.cd_tipo, v.ds_tipo, v.ds_icone, v.ds_cor, v.nr_ordem
      from (values
              ('ADMISSAO',            'Admissão',                'fa-sign-in',          'u-color-1',  10),
              ('PROMOCAO',            'Promoção',                'fa-arrow-circle-up',  'u-success',  20),
              ('MUDANCA_CARGO',       'Mudança de cargo',        'fa-exchange',         'u-info',     30),
              ('MUDANCA_GESTOR',      'Mudança de gestão',       'fa-users',            'u-color-2',  35),
              ('TRANSFERENCIA_DEPTO', 'Transferência de área',   'fa-building-o',       'u-color-4',  40),
              ('EFETIVACAO_CONTRATO', 'Efetivação de contrato',  'fa-file-text-o',      'u-color-6',  45),
              ('MERITO',              'Mérito',                  'fa-money',            'u-color-7',  50),
              ('ALTERACAO_JORNADA',   'Alteração de jornada',    'fa-clock-o',          'u-color-8',  60),
              ('AFASTAMENTO',         'Afastamento',             'fa-medkit',           'u-warning',  70),
              ('RETORNO',             'Retorno de afastamento',  'fa-repeat',           'u-color-3',  80),
              ('DESLIGAMENTO',        'Desligamento',            'fa-sign-out',         'u-danger',   90)
           ) v (cd_tipo, ds_tipo, ds_icone, ds_cor, nr_ordem)
  ) s
  on (t.id_empresa = s.id_empresa and t.cd_tipo = s.cd_tipo)
  when not matched then
    insert (id_empresa, cd_tipo, ds_tipo, ds_icone, ds_cor, nr_ordem, fl_ativo)
    values (s.id_empresa, s.cd_tipo, s.ds_tipo, s.ds_icone, s.ds_cor, s.nr_ordem, true);
end prc_seed_tipo_movimentacao;
/

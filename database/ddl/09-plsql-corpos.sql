
  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "LOG_PKG" as

  procedure gravar(p_nivel varchar2, p_msg varchar2, p_origem varchar2 default null, p_detalhe clob default null) is
    pragma autonomous_transaction;   -- grava mesmo se a transação principal der rollback
  begin
    insert into app_log (nivel, app_id, page_id, apex_user, session_id, origem, mensagem, detalhe)
    values (p_nivel, v('APP_ID'), v('APP_PAGE_ID'), v('APP_USER'), v('APP_SESSION'),
            substr(p_origem, 1, 255), substr(p_msg, 1, 4000), p_detalhe);
    commit;
  exception when others then
    rollback;                        -- log nunca pode derrubar a aplicação
    apex_debug.error('LOG_PKG.gravar falhou: %s', sqlerrm);
  end;

  procedure erro (p_msg varchar2, p_origem varchar2 default null) is begin gravar('ERRO',  p_msg, p_origem); end;
  procedure aviso(p_msg varchar2, p_origem varchar2 default null) is begin gravar('AVISO', p_msg, p_origem); end;
  procedure info (p_msg varchar2, p_origem varchar2 default null) is begin gravar('INFO',  p_msg, p_origem); end;

  -- Remove linhas internas do APEX/SYS, mantendo só o que aponta para o seu código
  function limpar_stack(p_stack varchar2) return varchar2 is
    l_linhas apex_t_varchar2;
    l_saida  varchar2(4000);
  begin
    if p_stack is null then return null; end if;
    l_linhas := apex_string.split(p_stack, chr(10));
    for i in 1 .. l_linhas.count loop
      if l_linhas(i) is not null
         and l_linhas(i) not like '%"APEX\_%' escape '\'
         and l_linhas(i) not like '%"SYS.%' then
        l_saida := substr(l_saida || trim(l_linhas(i)) || chr(10), 1, 4000);
      end if;
    end loop;
    return rtrim(l_saida, chr(10));
  end;

  function apex_error_handler(p_error in apex_error.t_error) return apex_error.t_error_result is
    l_result apex_error.t_error_result;
    l_origem varchar2(255);
  begin
    l_result := apex_error.init_error_result(p_error);

    l_origem := case p_error.component.type
                  when 'APEX_APPLICATION_PAGE_DA_ACTS'  then 'Dynamic Action'
                  when 'APEX_APPLICATION_PAGE_PROC'     then 'Processo'
                  when 'APEX_APPLICATION_PAGE_VAL'      then 'Validação'
                  when 'APEX_APPLICATION_PAGE_ITEMS'    then 'Item'
                  when 'APEX_APPLICATION_PAGE_REGIONS'  then 'Região'
                  when 'APEX_APPLICATION_PAGE_COMP'     then 'Computação'
                  when 'APEX_APPLICATION_PROCESSES'     then 'Processo de aplicação'
                  else p_error.component.type
                end
                || case when p_error.component.name is not null
                        then ' – ' || p_error.component.name end;

    gravar(
      p_nivel   => 'ERRO',
      p_msg     => p_error.message,
      p_origem  => l_origem,
      p_detalhe =>
           'Erro Oracle: ' || nvl(regexp_substr(p_error.ora_sqlerrm, 'ORA-\d+:[^' || chr(10) || ']*'), '(nenhum)')
        || chr(10) || chr(10)
        || 'Onde ocorreu:' || chr(10)
        || nvl(limpar_stack(p_error.error_backtrace), '(sem backtrace)')
        || case when p_error.error_statement is not null
                then chr(10) || chr(10) || 'Comando:' || chr(10) || p_error.error_statement end
    );
    return l_result;
  end;

end;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PKG_COMUNICADO" AS

    FUNCTION CRIAR_COMUNICADO (
        p_id_empresa      IN NUMBER,
        p_id_autor        IN NUMBER,
        p_titulo          IN VARCHAR2,
        p_conteudo        IN CLOB,
        p_id_departamento IN NUMBER DEFAULT NULL,
        p_imagem          IN BLOB DEFAULT NULL,
        p_mime_type       IN VARCHAR2 DEFAULT NULL,
        p_nome_arquivo    IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER
    IS
        v_id_comunicado NUMBER;
    BEGIN
        INSERT INTO COMUNICADO (
            ID_EMPRESA, ID_AUTOR, ID_DEPARTAMENTO, TITULO, CONTEUDO,
            DATA_PUBLICACAO, IMAGEM, MIME_TYPE, NOME_ARQUIVO
        ) VALUES (
            p_id_empresa, p_id_autor, p_id_departamento, p_titulo, p_conteudo,
            SYSDATE, p_imagem, p_mime_type, p_nome_arquivo
        )
        RETURNING ID_COMUNICADO INTO v_id_comunicado;

        COMMIT;
        RETURN v_id_comunicado;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END CRIAR_COMUNICADO;


    PROCEDURE MARCAR_COMO_LIDO (
        p_id_comunicado  IN NUMBER,
        p_id_colaborador IN NUMBER
    )
    IS
    BEGIN
        -- MERGE em vez de UPDATE/INSERT separados: cobre "já lido" e "primeira leitura"
        -- num único statement, sem risco de violar a UNIQUE em corrida de cliques duplos.
        MERGE INTO COMUNICADO_LEITURA tgt
        USING (SELECT p_id_comunicado AS ID_COMUNICADO, p_id_colaborador AS ID_COLABORADOR FROM DUAL) src
        ON (tgt.ID_COMUNICADO = src.ID_COMUNICADO AND tgt.ID_COLABORADOR = src.ID_COLABORADOR)
        WHEN NOT MATCHED THEN
            INSERT (ID_COMUNICADO, ID_COLABORADOR, DATA_LEITURA)
            VALUES (src.ID_COMUNICADO, src.ID_COLABORADOR, SYSTIMESTAMP);

        COMMIT;
    END MARCAR_COMO_LIDO;


    FUNCTION QTD_NAO_LIDOS (
        p_id_colaborador IN NUMBER
    ) RETURN NUMBER
    IS
        v_qtd NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_qtd
          FROM COMUNICADO c
          JOIN COLABORADOR col ON col.ID_COLABORADOR = p_id_colaborador
         WHERE c.ID_EMPRESA = col.ID_EMPRESA
           AND (c.ID_DEPARTAMENTO IS NULL OR c.ID_DEPARTAMENTO = col.ID_DEPARTAMENTO)
           AND NOT EXISTS (
                SELECT 1 FROM COMUNICADO_LEITURA l
                 WHERE l.ID_COMUNICADO = c.ID_COMUNICADO
                   AND l.ID_COLABORADOR = p_id_colaborador
           );

        RETURN v_qtd;
    END QTD_NAO_LIDOS;

END PKG_COMUNICADO;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PKG_EQUIPE_CANAL" AS

    FUNCTION CRIAR_EQUIPE (
        p_id_empresa      IN NUMBER,
        p_id_criador      IN NUMBER,
        p_nome            IN VARCHAR2,
        p_descricao       IN VARCHAR2 DEFAULT NULL,
        p_id_departamento IN NUMBER DEFAULT NULL
    ) RETURN NUMBER
    IS
        v_id_equipe NUMBER;
    BEGIN
        INSERT INTO EQUIPE (ID_EMPRESA, ID_DEPARTAMENTO, ID_CRIADOR, NOME, DESCRICAO)
        VALUES (p_id_empresa, p_id_departamento, p_id_criador, p_nome, p_descricao)
        RETURNING ID_EQUIPE INTO v_id_equipe;

        -- O criador entra automaticamente como ADMIN da equipe que criou.
        INSERT INTO EQUIPE_MEMBRO (ID_EQUIPE, ID_COLABORADOR, PAPEL)
        VALUES (v_id_equipe, p_id_criador, 'ADMIN');

        COMMIT;
        RETURN v_id_equipe;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END CRIAR_EQUIPE;


    PROCEDURE ADICIONAR_MEMBRO (
        p_id_equipe      IN NUMBER,
        p_id_colaborador IN NUMBER,
        p_papel          IN VARCHAR2 DEFAULT 'MEMBRO'
    )
    IS
    BEGIN
        MERGE INTO EQUIPE_MEMBRO tgt
        USING (SELECT p_id_equipe AS ID_EQUIPE, p_id_colaborador AS ID_COLABORADOR FROM DUAL) src
        ON (tgt.ID_EQUIPE = src.ID_EQUIPE AND tgt.ID_COLABORADOR = src.ID_COLABORADOR)
        WHEN NOT MATCHED THEN
            INSERT (ID_EQUIPE, ID_COLABORADOR, PAPEL)
            VALUES (src.ID_EQUIPE, src.ID_COLABORADOR, p_papel);

        COMMIT;
    END ADICIONAR_MEMBRO;


    PROCEDURE REMOVER_MEMBRO (
        p_id_equipe_membro IN NUMBER
    )
    IS
        v_id_equipe    EQUIPE_MEMBRO.ID_EQUIPE%TYPE;
        v_papel        EQUIPE_MEMBRO.PAPEL%TYPE;
        v_qtd_admins   NUMBER;
    BEGIN
        SELECT ID_EQUIPE, PAPEL
          INTO v_id_equipe, v_papel
          FROM EQUIPE_MEMBRO
         WHERE ID_EQUIPE_MEMBRO = p_id_equipe_membro;

        IF v_papel = 'ADMIN' THEN
            SELECT COUNT(*)
              INTO v_qtd_admins
              FROM EQUIPE_MEMBRO
             WHERE ID_EQUIPE = v_id_equipe
               AND PAPEL = 'ADMIN';

            IF v_qtd_admins <= 1 THEN
                RAISE_APPLICATION_ERROR(-20011,
                    'Não é possível remover o único administrador da equipe. Promova outro membro a ADMIN antes.');
            END IF;
        END IF;

        DELETE FROM EQUIPE_MEMBRO WHERE ID_EQUIPE_MEMBRO = p_id_equipe_membro;
        COMMIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20012, 'Membro não encontrado.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END REMOVER_MEMBRO;


    FUNCTION CRIAR_CANAL (
        p_id_equipe  IN NUMBER,
        p_nome       IN VARCHAR2,
        p_descricao  IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER
    IS
        v_id_canal NUMBER;
    BEGIN
        INSERT INTO CANAL (ID_EQUIPE, NOME, DESCRICAO)
        VALUES (p_id_equipe, p_nome, p_descricao)
        RETURNING ID_CANAL INTO v_id_canal;

        COMMIT;
        RETURN v_id_canal;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END CRIAR_CANAL;


    FUNCTION ENVIAR_MENSAGEM_CANAL (
        p_id_canal       IN NUMBER,
        p_id_colaborador IN NUMBER,
        p_corpo          IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id_canal_mensagem NUMBER;
        v_qtd_membro        NUMBER;
    BEGIN
        -----------------------------------------------------------------
        -- Validação: só quem é membro da equipe dona do canal pode postar.
        -- Evita que alguém envie mensagem via chamada direta da function
        -- num canal de equipe da qual não faz parte.
        -----------------------------------------------------------------
        SELECT COUNT(*)
          INTO v_qtd_membro
          FROM CANAL c
          JOIN EQUIPE_MEMBRO em ON em.ID_EQUIPE = c.ID_EQUIPE
         WHERE c.ID_CANAL = p_id_canal
           AND em.ID_COLABORADOR = p_id_colaborador;

        IF v_qtd_membro = 0 THEN
            RAISE_APPLICATION_ERROR(-20010,
                'Colaborador não é membro da equipe deste canal.');
        END IF;

        INSERT INTO CANAL_MENSAGEM (ID_CANAL, ID_COLABORADOR, CORPO)
        VALUES (p_id_canal, p_id_colaborador, p_corpo)
        RETURNING ID_CANAL_MENSAGEM INTO v_id_canal_mensagem;

        -- Enviar mensagem também conta como "estar online agora".
        ATUALIZAR_PRESENCA(p_id_colaborador, 'ONLINE');

        COMMIT;
        RETURN v_id_canal_mensagem;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END ENVIAR_MENSAGEM_CANAL;


    PROCEDURE ATUALIZAR_PRESENCA (
        p_id_colaborador IN NUMBER,
        p_status         IN VARCHAR2 DEFAULT 'ONLINE'
    )
    IS
    BEGIN
        MERGE INTO PRESENCA_COLABORADOR tgt
        USING (SELECT p_id_colaborador AS ID_COLABORADOR FROM DUAL) src
        ON (tgt.ID_COLABORADOR = src.ID_COLABORADOR)
        WHEN MATCHED THEN
            UPDATE SET STATUS_PRESENCA = p_status, DATA_ULTIMO_PING = SYSTIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (ID_COLABORADOR, STATUS_PRESENCA, DATA_ULTIMO_PING)
            VALUES (p_id_colaborador, p_status, SYSTIMESTAMP);

        COMMIT;
    END ATUALIZAR_PRESENCA;


    PROCEDURE ATUALIZAR_OFFLINE (
        p_minutos_limite IN NUMBER DEFAULT 3
    )
    IS
    BEGIN
        UPDATE PRESENCA_COLABORADOR
           SET STATUS_PRESENCA = 'OFFLINE'
         WHERE STATUS_PRESENCA <> 'OFFLINE'
           AND DATA_ULTIMO_PING < SYSTIMESTAMP - NUMTODSINTERVAL(p_minutos_limite, 'MINUTE');

        COMMIT;
    END ATUALIZAR_OFFLINE;

END PKG_EQUIPE_CANAL;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PKG_HISTORICO_CARREIRA" as

  ------------------------------------------------------------------------------
  -- Tipos internos
  ------------------------------------------------------------------------------
  type r_colaborador is record (
    id_colaborador  colaborador.id_colaborador%type,
    id_empresa      colaborador.id_empresa%type,
    id_cargo        colaborador.id_cargo%type,
    id_departamento colaborador.id_departamento%type,
    id_gestor       colaborador.id_gestor%type,
    data_admissao   colaborador.data_admissao%type,
    status          colaborador.status%type
  );

  -- Movimentação válida (efetivada, não estornada, não estorno)
  type r_evento is record (
    id_historico_carreira historico_carreira.id_historico_carreira%type,
    cd_tipo               tipo_movimentacao.cd_tipo%type,
    dt_efetiva            historico_carreira.dt_efetiva%type,
    id_cargo_novo         historico_carreira.id_cargo_novo%type,
    id_departamento_novo  historico_carreira.id_departamento_novo%type,
    id_gestor_novo        historico_carreira.id_gestor_novo%type,
    vl_salario_novo       historico_carreira.vl_salario_novo%type
  );

  -- Códigos com comportamento próprio
  c_admissao      constant varchar2(30) := 'ADMISSAO';
  c_promocao      constant varchar2(30) := 'PROMOCAO';
  c_mudanca_cargo constant varchar2(30) := 'MUDANCA_CARGO';
  c_transferencia constant varchar2(30) := 'TRANSFERENCIA_DEPTO';
  c_mudanca_gestor constant varchar2(30) := 'MUDANCA_GESTOR';
  c_desligamento  constant varchar2(30) := 'DESLIGAMENTO';

  -- COMUNICADO.TITULO: confira o tamanho real com o 00_verificar_schema.sql
  c_max_titulo_comunicado constant pls_integer := 100;

  -- Empresa definida para scripts/testes fora do APEX
  g_empresa_batch number;

  ------------------------------------------------------------------------------
  -- Utilitários privados
  ------------------------------------------------------------------------------
  procedure erro (p_codigo in pls_integer, p_mensagem in varchar2) is
  begin
    raise_application_error(p_codigo, p_mensagem);
  end erro;

  function em_sessao_apex return boolean is
  begin
    return sys_context('APEX$SESSION', 'APP_SESSION') is not null;
  end em_sessao_apex;

  function usuario_atual return varchar2 is
  begin
    return coalesce(sys_context('APEX$SESSION', 'APP_USER'), sys_context('USERENV', 'SESSION_USER'));
  end usuario_atual;

  function fmt_data (p_data in date) return varchar2 is
  begin
    return to_char(p_data, 'dd/mm/yyyy');
  end fmt_data;

  -- Tipos que mexem em cargo, departamento e gestor
  function altera_estrutura (p_cd_tipo in varchar2) return boolean is
  begin
    return p_cd_tipo in (c_admissao, c_promocao, c_mudanca_cargo, c_transferencia, c_mudanca_gestor);
  end altera_estrutura;

  -- "2 anos e 3 meses", "5 meses", "menos de 1 mês"
  function formatar_periodo (p_inicio in date, p_fim in date) return varchar2 is
    l_meses pls_integer;
    l_anos  pls_integer;
    l_resto pls_integer;

    function plural (p_qtd in pls_integer, p_singular in varchar2, p_plural in varchar2) return varchar2 is
    begin
      return p_qtd || ' ' || case when p_qtd = 1 then p_singular else p_plural end;
    end plural;
  begin
    if p_inicio is null then
      return null;
    end if;

    l_meses := greatest(floor(months_between(trunc(p_fim), trunc(p_inicio))), 0);
    l_anos  := trunc(l_meses / 12);
    l_resto := mod(l_meses, 12);

    return case
             when l_meses = 0 then 'menos de 1 mês'
             when l_anos  = 0 then plural(l_resto, 'mês', 'meses')
             when l_resto = 0 then plural(l_anos, 'ano', 'anos')
             else plural(l_anos, 'ano', 'anos') || ' e ' || plural(l_resto, 'mês', 'meses')
           end;
  end formatar_periodo;

  function fuso (p_id_empresa in number) return varchar2 is
    l_fuso config_carreira.ds_fuso_horario%type;
  begin
    select ds_fuso_horario into l_fuso from config_carreira where id_empresa = p_id_empresa;
    return l_fuso;
  exception
    when no_data_found then
      return c_fuso_padrao;
  end fuso;

  function comunicado_automatico (p_id_empresa in number) return boolean is
    l_fl config_carreira.fl_comunicado_automatico%type;
  begin
    select fl_comunicado_automatico into l_fl from config_carreira where id_empresa = p_id_empresa;
    return nvl(l_fl, true);
  exception
    when no_data_found then
      return true;
  end comunicado_automatico;

  function qt_dias_futuro (p_id_empresa in number) return pls_integer is
    l_qt config_carreira.qt_dias_futuro%type;
  begin
    select qt_dias_futuro
      into l_qt
      from config_carreira
     where id_empresa = p_id_empresa;
    return l_qt;
  exception
    when no_data_found then
      return c_dias_futuro_padrao;
  end qt_dias_futuro;

  ------------------------------------------------------------------------------
  -- Segurança
  ------------------------------------------------------------------------------
  function fn_empresa_contexto return number is
    l_id number;
  begin
    if em_sessao_apex then
      l_id := to_number(apex_util.get_session_state('G_ID_EMPRESA'));
      if l_id is null then
        erro(c_err_permissao, 'Sua sessão não está vinculada a uma empresa. Saia e entre novamente.');
      end if;
      return l_id;
    end if;
    return g_empresa_batch;
  end fn_empresa_contexto;

  procedure definir_empresa_contexto (p_id_empresa in number) is
  begin
    if em_sessao_apex then
      erro(c_err_permissao, 'Em sessão APEX a empresa vem de G_ID_EMPRESA e não pode ser alterada.');
    end if;
    g_empresa_batch := p_id_empresa;
  end definir_empresa_contexto;

  -- O registro precisa ser da empresa do contexto. A mensagem não revela que
  -- o registro existe em outra empresa.
  procedure assert_empresa (p_id_empresa in number, p_mensagem in varchar2 default null) is
    l_ctx number := fn_empresa_contexto;
  begin
    if l_ctx is not null and l_ctx <> p_id_empresa then
      erro(c_err_colaborador, nvl(p_mensagem, 'Colaborador não encontrado.'));
    end if;
  end assert_empresa;

  procedure assert_admin_rh is
  begin
    if em_sessao_apex and not apex_authorization.is_authorized(c_auth_admin_rh) then
      erro(c_err_permissao, 'Somente o RH pode alterar o histórico de carreira.');
    end if;
  end assert_admin_rh;

  ------------------------------------------------------------------------------
  -- Leitura
  ------------------------------------------------------------------------------
  function carrega_colaborador (p_id in number, p_lock in boolean default false) return r_colaborador is
    l_col r_colaborador;
  begin
    if p_lock then
      select id_colaborador, id_empresa, id_cargo, id_departamento, id_gestor, data_admissao, status
        into l_col
        from colaborador
       where id_colaborador = p_id
         for update;
    else
      select id_colaborador, id_empresa, id_cargo, id_departamento, id_gestor, data_admissao, status
        into l_col
        from colaborador
       where id_colaborador = p_id;
    end if;

    assert_empresa(l_col.id_empresa);
    return l_col;
  exception
    when no_data_found then
      erro(c_err_colaborador, 'Colaborador não encontrado.');
  end carrega_colaborador;

  function carrega_tipo (
    p_id_tipo      in number,
    p_id_empresa   in number,
    p_exigir_ativo in boolean default true
  ) return tipo_movimentacao%rowtype is
    l_tipo tipo_movimentacao%rowtype;
  begin
    if p_id_tipo is null then
      erro(c_err_tipo, 'Informe o tipo de movimentação.');
    end if;

    select *
      into l_tipo
      from tipo_movimentacao
     where id_tipo_movimentacao = p_id_tipo;

    if l_tipo.id_empresa <> p_id_empresa then
      erro(c_err_empresa, 'O tipo de movimentação não pertence à empresa do colaborador.');
    end if;

    if p_exigir_ativo and not nvl(l_tipo.fl_ativo, false) then
      erro(c_err_tipo, 'O tipo "' || l_tipo.ds_tipo || '" está inativo e não pode ser usado.');
    end if;

    return l_tipo;
  exception
    when no_data_found then
      erro(c_err_tipo, 'Tipo de movimentação não encontrado.');
  end carrega_tipo;

  function carrega_movimentacao (p_id in number, p_lock in boolean default false) return historico_carreira%rowtype is
    l_mov historico_carreira%rowtype;
  begin
    if p_lock then
      select * into l_mov from historico_carreira where id_historico_carreira = p_id for update;
    else
      select * into l_mov from historico_carreira where id_historico_carreira = p_id;
    end if;

    assert_empresa(l_mov.id_empresa, 'Lançamento não encontrado.');
    return l_mov;
  exception
    when no_data_found then
      erro(c_err_registro, 'Lançamento não encontrado.');
  end carrega_movimentacao;

  -- Última movimentação válida do colaborador (opcionalmente ignorando uma)
  function ultimo_valido (p_id_colaborador in number, p_ignorar_id in number default null) return r_evento is
    l_ev r_evento;
  begin
    select v.id_historico_carreira, v.cd_tipo, v.dt_efetiva,
           v.id_cargo_novo, v.id_departamento_novo, v.id_gestor_novo, h.vl_salario_novo
      into l_ev
      from vw_movimentacao_valida v
      join historico_carreira     h on h.id_historico_carreira = v.id_historico_carreira
     where v.id_colaborador = p_id_colaborador
       and (p_ignorar_id is null or v.id_historico_carreira <> p_ignorar_id)
     order by v.dt_efetiva desc, v.id_historico_carreira desc
     fetch first 1 row only;
    return l_ev;
  exception
    when no_data_found then
      return l_ev;   -- registro vazio: sem histórico válido
  end ultimo_valido;

  -- Data de referência da admissão: última (re)admissão válida ou o cadastro
  function dt_admissao_referencia (p_col in r_colaborador) return date is
    l_dt date;
  begin
    select max(dt_efetiva)
      into l_dt
      from vw_movimentacao_valida
     where id_colaborador = p_col.id_colaborador
       and cd_tipo        = c_admissao;
    return coalesce(l_dt, p_col.data_admissao);
  end dt_admissao_referencia;

  ------------------------------------------------------------------------------
  -- Validação central (usada no registro, na edição e na efetivação)
  ------------------------------------------------------------------------------
  procedure validar (
    p_mov            in out nocopy historico_carreira%rowtype,
    p_col            in r_colaborador,
    p_tipo           in tipo_movimentacao%rowtype,
    p_validar_futuro in boolean default true
  ) is
    l_ult          r_evento := ultimo_valido(p_col.id_colaborador);
    l_hoje         date     := fn_hoje(p_col.id_empresa);
    l_dias         pls_integer;
    l_dt_admissao  date;
    l_emp          number;
    l_dep_do_cargo number;
    l_cargo_final  number;
    l_dep_final    number;
  begin
    -- Campos que não se aplicam ao tipo são descartados
    if not altera_estrutura(p_tipo.cd_tipo) then
      p_mov.id_cargo_novo        := null;
      p_mov.id_departamento_novo := null;
      p_mov.id_gestor_novo       := null;
    end if;

    if p_mov.dt_efetiva is null then
      erro(c_err_data_admissao, 'Informe a data efetiva.');
    end if;
    p_mov.dt_efetiva := trunc(p_mov.dt_efetiva);

    -- Desligamento e (re)admissão
    if l_ult.cd_tipo = c_desligamento and p_tipo.cd_tipo <> c_admissao then
      erro(c_err_desligado, 'O colaborador foi desligado em ' || fmt_data(l_ult.dt_efetiva)
                            || '. Depois de um desligamento, só é possível lançar uma readmissão.');
    end if;

    if p_tipo.cd_tipo = c_admissao and l_ult.id_historico_carreira is not null
       and l_ult.cd_tipo <> c_desligamento then
      erro(c_err_admissao, 'O colaborador já tem uma admissão ativa. Para readmitir, lance antes o desligamento.');
    end if;

    -- Datas
    if p_tipo.cd_tipo = c_admissao then
      if l_ult.id_historico_carreira is not null and p_mov.dt_efetiva <= l_ult.dt_efetiva then
        erro(c_err_data_admissao, 'A readmissão deve ser posterior ao desligamento de '
                                  || fmt_data(l_ult.dt_efetiva) || '.');
      end if;
    else
      l_dt_admissao := dt_admissao_referencia(p_col);
      if l_dt_admissao is not null and p_mov.dt_efetiva < trunc(l_dt_admissao) then
        erro(c_err_data_admissao, 'A data efetiva não pode ser anterior à admissão ('
                                  || fmt_data(l_dt_admissao) || ').');
      end if;

      if l_ult.id_historico_carreira is not null and p_mov.dt_efetiva < l_ult.dt_efetiva then
        erro(c_err_retroativo, 'A data efetiva não pode ser anterior à última movimentação efetivada ('
                               || fmt_data(l_ult.dt_efetiva) || '). Para corrigir o passado, estorne os lançamentos posteriores.');
      end if;
    end if;

    if p_validar_futuro then
      l_dias := qt_dias_futuro(p_col.id_empresa);
      if p_mov.dt_efetiva > l_hoje + l_dias then
        erro(c_err_data_futura, 'A data efetiva pode ser no máximo ' || fmt_data(l_hoje + l_dias)
                                || ' (' || l_dias || ' dias a partir de hoje).');
      end if;
    end if;

    -- Regras por tipo
    if p_tipo.cd_tipo in (c_promocao, c_mudanca_cargo) then
      if p_mov.id_cargo_novo is null then
        erro(c_err_cargo, 'Informe o novo cargo.');
      elsif p_mov.id_cargo_novo = p_col.id_cargo then
        erro(c_err_cargo, 'O novo cargo deve ser diferente do cargo atual.');
      end if;
    elsif p_tipo.cd_tipo = c_mudanca_gestor then
      if p_mov.id_gestor_novo is null then
        erro(c_err_gestor, 'Informe a nova gestão direta.');
      elsif p_mov.id_gestor_novo = p_col.id_gestor then
        erro(c_err_gestor, 'A nova gestão deve ser diferente da atual.');
      end if;
    elsif p_tipo.cd_tipo = c_transferencia then
      if p_mov.id_departamento_novo is null then
        erro(c_err_departamento, 'Informe o departamento de destino.');
      elsif p_mov.id_departamento_novo = p_col.id_departamento then
        erro(c_err_departamento, 'O departamento de destino deve ser diferente do atual.');
      end if;
    end if;

    -- Tudo precisa ser da mesma empresa do colaborador
    if p_mov.id_cargo_novo is not null then
      begin
        select id_empresa into l_emp from cargo where id_cargo = p_mov.id_cargo_novo;
      exception
        when no_data_found then erro(c_err_empresa, 'Cargo não encontrado.');
      end;
      if l_emp <> p_col.id_empresa then
        erro(c_err_empresa, 'O cargo informado não pertence à empresa do colaborador.');
      end if;
    end if;

    if p_mov.id_departamento_novo is not null then
      begin
        select id_empresa into l_emp from departamento where id_departamento = p_mov.id_departamento_novo;
      exception
        when no_data_found then erro(c_err_empresa, 'Departamento não encontrado.');
      end;
      if l_emp <> p_col.id_empresa then
        erro(c_err_empresa, 'O departamento informado não pertence à empresa do colaborador.');
      end if;
    end if;

    if p_mov.id_gestor_novo is not null then
      if p_mov.id_gestor_novo = p_col.id_colaborador then
        erro(c_err_gestor, 'O colaborador não pode ser gestor de si mesmo.');
      end if;
      begin
        select id_empresa into l_emp from colaborador where id_colaborador = p_mov.id_gestor_novo;
      exception
        when no_data_found then erro(c_err_empresa, 'Gestor não encontrado.');
      end;
      if l_emp <> p_col.id_empresa then
        erro(c_err_empresa, 'O gestor informado não pertence à empresa do colaborador.');
      end if;
    end if;

    -- Aprovador: opcional, da mesma empresa e nunca o próprio colaborador.
    -- Não exige vínculo ativo: lançamentos retroativos podem citar quem já saiu.
    if p_mov.id_aprovador is not null then
      if p_mov.id_aprovador = p_col.id_colaborador then
        erro(c_err_aprovador, 'O colaborador não pode aprovar a própria movimentação.');
      end if;
      begin
        select id_empresa into l_emp from colaborador where id_colaborador = p_mov.id_aprovador;
      exception
        when no_data_found then erro(c_err_aprovador, 'Aprovador não encontrado.');
      end;
      if l_emp <> p_col.id_empresa then
        erro(c_err_aprovador, 'O aprovador informado não pertence à empresa do colaborador.');
      end if;
    end if;

    -- O cargo final precisa ser do departamento final (CARGO.ID_DEPARTAMENTO)
    if p_mov.id_cargo_novo is not null or p_mov.id_departamento_novo is not null then
      l_cargo_final := coalesce(p_mov.id_cargo_novo, p_col.id_cargo);
      l_dep_final   := coalesce(p_mov.id_departamento_novo, p_col.id_departamento);

      if l_cargo_final is not null and l_dep_final is not null then
        select id_departamento into l_dep_do_cargo from cargo where id_cargo = l_cargo_final;
        if l_dep_do_cargo is not null and l_dep_do_cargo <> l_dep_final then
          erro(c_err_cargo_depto, 'O cargo não pertence ao departamento de destino. '
                                  || 'Escolha um cargo do departamento selecionado.');
        end if;
      end if;
    end if;
  end validar;

  ------------------------------------------------------------------------------
  -- Comunicado automático para a equipe de destino (nunca menciona salário)
  ------------------------------------------------------------------------------
  function publicar_comunicado (
    p_id_empresa     in number,
    p_id_colaborador in number,
    p_cd_tipo        in varchar2,
    p_readmissao     in boolean,
    p_dt_efetiva     in date,
    p_id_cargo       in number,
    p_id_departamento in number,
    p_id_gestor      in number
  ) return number is
    l_nome    colaborador.nome_completo%type;
    l_cargo   cargo.nome%type;
    l_depto   departamento.nome%type;
    l_gestor  colaborador.nome_completo%type;
    l_autor   number;
    l_titulo  varchar2(400);
    l_texto   varchar2(4000);
    l_id      number;
    l_usuario constant varchar2(255) := usuario_atual;  -- função privada não pode ser chamada dentro de SQL
  begin
    if not comunicado_automatico(p_id_empresa)
       or p_cd_tipo not in (c_admissao, c_promocao, c_transferencia) then
      return null;
    end if;

    select c.nome_completo into l_nome from colaborador c where c.id_colaborador = p_id_colaborador;
    select max(nome) into l_cargo from cargo where id_cargo = p_id_cargo;
    select max(nome) into l_depto from departamento where id_departamento = p_id_departamento;
    select max(nome_completo) into l_gestor from colaborador where id_colaborador = p_id_gestor;

    if p_cd_tipo = c_admissao and p_readmissao then
      l_titulo := 'De volta à equipe: ' || l_nome;
      l_texto  := l_nome || ' retorna à equipe' || nvl2(l_depto, ' de ' || l_depto, '')
                  || nvl2(l_cargo, ' como ' || l_cargo, '') || ' a partir de ' || fmt_data(p_dt_efetiva) || '.';
    elsif p_cd_tipo = c_admissao then
      l_titulo := 'Boas-vindas a ' || l_nome;
      l_texto  := l_nome || ' entra na equipe' || nvl2(l_depto, ' de ' || l_depto, '')
                  || nvl2(l_cargo, ' como ' || l_cargo, '')
                  || nvl2(l_gestor, ', com gestão de ' || l_gestor, '')
                  || ', a partir de ' || fmt_data(p_dt_efetiva) || '. Desejamos boas-vindas!';
    elsif p_cd_tipo = c_promocao then
      l_titulo := 'Promoção: ' || l_nome;
      l_texto  := l_nome || ' assume o cargo de ' || l_cargo
                  || nvl2(l_depto, ' na equipe de ' || l_depto, '')
                  || ' a partir de ' || fmt_data(p_dt_efetiva) || '. Parabéns!';
    else
      l_titulo := l_nome || ' chega à equipe' || nvl2(l_depto, ' de ' || l_depto, '');
      l_texto  := 'A partir de ' || fmt_data(p_dt_efetiva) || ', ' || l_nome
                  || ' passa a fazer parte da equipe' || nvl2(l_depto, ' de ' || l_depto, '')
                  || nvl2(l_cargo, ' como ' || l_cargo, '') || '.';
    end if;

    -- Autor: o usuário do RH que efetivou; sem cadastro, o gestor; por fim, o próprio colaborador
    begin
      select id_colaborador
        into l_autor
        from colaborador
       where upper(login_apex) = upper(l_usuario)
         and id_empresa        = p_id_empresa;
    exception
      when no_data_found or too_many_rows then
        l_autor := coalesce(p_id_gestor, p_id_colaborador);
    end;

    insert into comunicado (id_empresa, id_departamento, id_autor, titulo, conteudo, data_publicacao)
    values (p_id_empresa, p_id_departamento, l_autor,
            substr(l_titulo, 1, c_max_titulo_comunicado), l_texto,
            fn_data_local(p_id_empresa, systimestamp))
    returning id_comunicado into l_id;

    return l_id;
  end publicar_comunicado;

  ------------------------------------------------------------------------------
  -- Utilitários públicos
  ------------------------------------------------------------------------------
  function fn_hoje (p_id_empresa in number) return date is
  begin
    return trunc(fn_data_local(p_id_empresa, systimestamp));
  end fn_hoje;

  function fn_data_local (p_id_empresa in number, p_momento in timestamp with time zone) return date is
    l_fuso varchar2(64) := fuso(p_id_empresa);
    l_data date;
  begin
    if p_momento is null then
      return null;
    end if;
    -- AT TIME ZONE com variável (bind) dá ORA-02000 (missing AS keyword).
    -- O fuso entra como literal; a validação impede injeção de SQL.
    if l_fuso is null or not regexp_like(l_fuso, '^[A-Za-z0-9_/+:-]{1,64}$') then
      l_fuso := c_fuso_padrao;
    end if;
    execute immediate
      'select cast(:momento at time zone ''' || l_fuso || ''' as date) from dual'
      into l_data
      using p_momento;
    return l_data;
  end fn_data_local;

  function fn_id_tipo (p_id_empresa in number, p_cd_tipo in varchar2) return number is
    l_id number;
  begin
    select id_tipo_movimentacao
      into l_id
      from tipo_movimentacao
     where id_empresa = p_id_empresa
       and cd_tipo    = upper(p_cd_tipo);
    return l_id;
  exception
    when no_data_found then
      erro(c_err_tipo, 'Tipo de movimentação ' || p_cd_tipo || ' não cadastrado para a empresa.');
  end fn_id_tipo;

  ------------------------------------------------------------------------------
  -- Movimentações
  ------------------------------------------------------------------------------
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
    p_id_aprovador         in number   default null
  ) return number is
    l_col  r_colaborador;
    l_tipo tipo_movimentacao%rowtype;
    l_mov  historico_carreira%rowtype;
    l_ult  r_evento;
    l_id   number;
  begin
    assert_admin_rh;
    l_col  := carrega_colaborador(p_id_colaborador);
    l_tipo := carrega_tipo(p_id_tipo_movimentacao, l_col.id_empresa);

    l_mov.id_colaborador       := l_col.id_colaborador;
    l_mov.dt_efetiva           := p_dt_efetiva;
    l_mov.id_cargo_novo        := p_id_cargo_novo;
    l_mov.id_departamento_novo := p_id_departamento_novo;
    l_mov.id_gestor_novo       := p_id_gestor_novo;
    l_mov.id_aprovador         := p_id_aprovador;

    validar(l_mov, l_col, l_tipo);

    -- Sem salário anterior informado, herda o último salário registrado
    l_ult := ultimo_valido(l_col.id_colaborador);

    insert into historico_carreira (
      id_empresa, id_colaborador, id_tipo_movimentacao, dt_efetiva,
      id_cargo_anterior, id_departamento_anterior, id_gestor_anterior,
      id_cargo_novo, id_departamento_novo, id_gestor_novo,
      vl_salario_anterior, vl_salario_novo, ds_motivo, ds_observacao, id_aprovador, st_registro
    ) values (
      l_col.id_empresa, l_col.id_colaborador, l_tipo.id_tipo_movimentacao, l_mov.dt_efetiva,
      l_col.id_cargo, l_col.id_departamento, l_col.id_gestor,
      l_mov.id_cargo_novo, l_mov.id_departamento_novo, l_mov.id_gestor_novo,
      coalesce(p_vl_salario_anterior, l_ult.vl_salario_novo),
      p_vl_salario_novo, p_ds_motivo, p_ds_observacao, l_mov.id_aprovador, c_st_rascunho
    )
    returning id_historico_carreira into l_id;

    return l_id;
  end registrar_movimentacao;

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
  ) is
    l_mov  historico_carreira%rowtype;
    l_col  r_colaborador;
    l_tipo tipo_movimentacao%rowtype;
  begin
    assert_admin_rh;
    l_mov := carrega_movimentacao(p_id_historico_carreira, p_lock => true);

    if l_mov.st_registro <> c_st_rascunho then
      erro(c_err_status, 'Somente rascunhos podem ser editados. Para corrigir um lançamento efetivado, estorne e lance novamente.');
    end if;

    l_col  := carrega_colaborador(l_mov.id_colaborador);
    l_tipo := carrega_tipo(p_id_tipo_movimentacao, l_col.id_empresa);

    l_mov.dt_efetiva           := p_dt_efetiva;
    l_mov.id_cargo_novo        := p_id_cargo_novo;
    l_mov.id_departamento_novo := p_id_departamento_novo;
    l_mov.id_gestor_novo       := p_id_gestor_novo;
    l_mov.id_aprovador         := p_id_aprovador;

    validar(l_mov, l_col, l_tipo);

    update historico_carreira
       set id_tipo_movimentacao     = l_tipo.id_tipo_movimentacao,
           dt_efetiva               = l_mov.dt_efetiva,
           id_cargo_anterior        = l_col.id_cargo,
           id_departamento_anterior = l_col.id_departamento,
           id_gestor_anterior       = l_col.id_gestor,
           id_cargo_novo            = l_mov.id_cargo_novo,
           id_departamento_novo     = l_mov.id_departamento_novo,
           id_gestor_novo           = l_mov.id_gestor_novo,
           vl_salario_anterior      = p_vl_salario_anterior,
           vl_salario_novo          = p_vl_salario_novo,
           ds_motivo                = p_ds_motivo,
           ds_observacao            = p_ds_observacao,
           id_aprovador             = l_mov.id_aprovador
     where id_historico_carreira = p_id_historico_carreira;
  end atualizar_rascunho;

  procedure excluir_rascunho (p_id_historico_carreira in number) is
    l_mov historico_carreira%rowtype;
  begin
    assert_admin_rh;
    l_mov := carrega_movimentacao(p_id_historico_carreira, p_lock => true);

    if l_mov.st_registro <> c_st_rascunho then
      erro(c_err_status, 'Somente rascunhos podem ser excluídos. Lançamentos efetivados são permanentes.');
    end if;

    delete from historico_carreira where id_historico_carreira = p_id_historico_carreira;
  end excluir_rascunho;

  procedure efetivar_movimentacao (p_id in number) is
    l_mov        historico_carreira%rowtype;
    l_col        r_colaborador;
    l_tipo       tipo_movimentacao%rowtype;
    l_ult        r_evento;
    l_readmissao boolean;
    l_status     boolean;
    l_cargo      number;
    l_depto      number;
    l_gestor     number;
    l_comunicado number;
    l_usuario constant varchar2(255) := usuario_atual;  -- função privada não pode ser chamada dentro de SQL
  begin
    assert_admin_rh;
    l_mov := carrega_movimentacao(p_id, p_lock => true);

    if l_mov.st_registro <> c_st_rascunho then
      erro(c_err_status, 'Somente rascunhos podem ser efetivados. Este lançamento está '
                         || lower(l_mov.st_registro) || '.');
    end if;

    -- Trava o colaborador: duas efetivações simultâneas ficam em fila
    l_col  := carrega_colaborador(l_mov.id_colaborador, p_lock => true);
    l_tipo := carrega_tipo(l_mov.id_tipo_movimentacao, l_col.id_empresa);
    l_ult  := ultimo_valido(l_col.id_colaborador);

    -- A situação pode ter mudado desde o rascunho: valida de novo
    validar(l_mov, l_col, l_tipo);

    l_readmissao := l_tipo.cd_tipo = c_admissao and l_ult.cd_tipo = c_desligamento;
    l_cargo      := coalesce(l_mov.id_cargo_novo, l_col.id_cargo);
    l_depto      := coalesce(l_mov.id_departamento_novo, l_col.id_departamento);
    l_gestor     := coalesce(l_mov.id_gestor_novo, l_col.id_gestor);
    l_status     := case
                      when l_tipo.cd_tipo = c_desligamento then false
                      when l_readmissao                    then true
                      else l_col.status
                    end;

    -- Antes do UPDATE: depois de efetivado, o lançamento não aceita mais alterações
    l_comunicado := publicar_comunicado(l_col.id_empresa, l_col.id_colaborador, l_tipo.cd_tipo,
                                        l_readmissao, l_mov.dt_efetiva, l_cargo, l_depto, l_gestor);

    -- Snapshot completo: anterior = situação no momento da efetivação,
    -- novo = situação resultante (mesmo que não tenha mudado)
    update historico_carreira
       set st_registro              = c_st_efetivado,
           dt_efetiva               = l_mov.dt_efetiva,
           id_cargo_anterior        = l_col.id_cargo,
           id_departamento_anterior = l_col.id_departamento,
           id_gestor_anterior       = l_col.id_gestor,
           id_cargo_novo            = l_cargo,
           id_departamento_novo     = l_depto,
           id_gestor_novo           = l_gestor,
           vl_salario_novo          = coalesce(vl_salario_novo, vl_salario_anterior),
           id_comunicado            = l_comunicado,
           dt_efetivacao            = systimestamp,
           usr_efetivacao           = l_usuario
     where id_historico_carreira = p_id;

    update colaborador
       set id_cargo        = l_cargo,
           id_departamento = l_depto,
           id_gestor       = l_gestor,
           status          = l_status,
           data_admissao   = case when l_readmissao then l_mov.dt_efetiva else data_admissao end
     where id_colaborador = l_col.id_colaborador;
  end efetivar_movimentacao;

  procedure estornar_movimentacao (p_id in number, p_motivo in varchar2) is
    l_mov    historico_carreira%rowtype;
    l_col    r_colaborador;
    l_tipo   tipo_movimentacao%rowtype;
    l_ult    r_evento;
    l_ant    r_evento;
    l_status boolean;
    l_dt_adm date;
    l_usuario constant varchar2(255) := usuario_atual;  -- função privada não pode ser chamada dentro de SQL
  begin
    assert_admin_rh;

    if trim(p_motivo) is null then
      erro(c_err_motivo, 'Informe o motivo do estorno.');
    end if;

    l_mov := carrega_movimentacao(p_id, p_lock => true);

    if l_mov.st_registro <> c_st_efetivado or l_mov.id_registro_estornado is not null then
      erro(c_err_status, 'Somente movimentações efetivadas podem ser estornadas.');
    end if;

    l_col  := carrega_colaborador(l_mov.id_colaborador, p_lock => true);
    l_tipo := carrega_tipo(l_mov.id_tipo_movimentacao, l_col.id_empresa, p_exigir_ativo => false);
    l_ult  := ultimo_valido(l_col.id_colaborador);

    if l_ult.id_historico_carreira <> p_id then
      erro(c_err_estorno, 'Só é possível estornar a última movimentação efetivada do colaborador ('
                          || fmt_data(l_ult.dt_efetiva) || '). Estorne antes os lançamentos posteriores.');
    end if;

    l_ant := ultimo_valido(l_col.id_colaborador, p_ignorar_id => p_id);
    if l_ant.id_historico_carreira is null then
      erro(c_err_estorno, 'Não há situação anterior para restaurar: a admissão inicial não pode ser estornada.');
    end if;

    -- Lançamento de estorno: registra a reversão de forma permanente
    insert into historico_carreira (
      id_empresa, id_colaborador, id_tipo_movimentacao, dt_efetiva,
      id_cargo_anterior, id_departamento_anterior, id_gestor_anterior,
      id_cargo_novo, id_departamento_novo, id_gestor_novo,
      vl_salario_anterior, vl_salario_novo, ds_motivo,
      st_registro, id_registro_estornado, dt_efetivacao, usr_efetivacao
    ) values (
      l_col.id_empresa, l_col.id_colaborador, l_mov.id_tipo_movimentacao, fn_hoje(l_col.id_empresa),
      l_mov.id_cargo_novo, l_mov.id_departamento_novo, l_mov.id_gestor_novo,
      l_ant.id_cargo_novo, l_ant.id_departamento_novo, l_ant.id_gestor_novo,
      l_mov.vl_salario_novo, l_ant.vl_salario_novo, p_motivo,
      c_st_efetivado, p_id, systimestamp, l_usuario
    );

    -- Única alteração permitida em um efetivado (a trigger confere)
    update historico_carreira
       set st_registro = c_st_estornado
     where id_historico_carreira = p_id;

    -- Status: desfazer desligamento reativa; desfazer readmissão desativa
    l_status := case
                  when l_tipo.cd_tipo = c_desligamento then true
                  when l_ant.cd_tipo  = c_desligamento then false
                  else l_col.status
                end;

    -- Desfazer uma readmissão devolve a data de admissão anterior
    if l_tipo.cd_tipo = c_admissao then
      l_dt_adm := dt_admissao_referencia(l_col);
    else
      l_dt_adm := l_col.data_admissao;
    end if;

    update colaborador
       set id_cargo        = l_ant.id_cargo_novo,
           id_departamento = l_ant.id_departamento_novo,
           id_gestor       = l_ant.id_gestor_novo,
           status          = l_status,
           data_admissao   = l_dt_adm
     where id_colaborador = l_col.id_colaborador;
  end estornar_movimentacao;

  procedure registrar_admissao_automatica (
    p_id_colaborador   in number,
    p_gerar_comunicado in boolean default true
  ) is
    l_col        r_colaborador;
    l_qt         pls_integer;
    l_id_tipo    number;
    l_dt         date;
    l_comunicado number;
    l_usuario constant varchar2(255) := usuario_atual;  -- função privada não pode ser chamada dentro de SQL
  begin
    l_col := carrega_colaborador(p_id_colaborador, p_lock => true);

    select count(*) into l_qt from historico_carreira where id_colaborador = l_col.id_colaborador;
    if l_qt > 0 then
      return;   -- já tem histórico: nada a fazer
    end if;

    -- Empresa nova ainda sem tipos cadastrados
    select count(*) into l_qt
      from tipo_movimentacao
     where id_empresa = l_col.id_empresa
       and cd_tipo    = c_admissao;
    if l_qt = 0 then
      prc_seed_tipo_movimentacao(l_col.id_empresa);
    end if;

    l_id_tipo := fn_id_tipo(l_col.id_empresa, c_admissao);
    l_dt      := trunc(coalesce(l_col.data_admissao, fn_hoje(l_col.id_empresa)));

    if p_gerar_comunicado then
      l_comunicado := publicar_comunicado(l_col.id_empresa, l_col.id_colaborador, c_admissao, false,
                                          l_dt, l_col.id_cargo, l_col.id_departamento, l_col.id_gestor);
    end if;

    -- Espelha o cadastro atual: não valida limite de data futura, porque a
    -- admissão pode ter sido cadastrada com antecedência
    insert into historico_carreira (
      id_empresa, id_colaborador, id_tipo_movimentacao, dt_efetiva,
      id_cargo_novo, id_departamento_novo, id_gestor_novo,
      ds_motivo, st_registro, id_comunicado, dt_efetivacao, usr_efetivacao
    ) values (
      l_col.id_empresa, l_col.id_colaborador, l_id_tipo, l_dt,
      l_col.id_cargo, l_col.id_departamento, l_col.id_gestor,
      'Admissão registrada automaticamente a partir do cadastro.',
      c_st_efetivado, l_comunicado, systimestamp, l_usuario
    );
  end registrar_admissao_automatica;

  ------------------------------------------------------------------------------
  -- Solicitações de correção
  ------------------------------------------------------------------------------
  function solicitar_correcao (
    p_id_colaborador        in number,
    p_ds_mensagem           in varchar2,
    p_id_historico_carreira in number default null
  ) return number is
    l_col   r_colaborador := carrega_colaborador(p_id_colaborador);
    l_login colaborador.login_apex%type;
    l_qt    pls_integer;
    l_id    number;
  begin
    if em_sessao_apex then
      select login_apex into l_login from colaborador where id_colaborador = p_id_colaborador;
      if upper(l_login) <> upper(usuario_atual) or l_login is null then
        erro(c_err_permissao, 'Só o próprio colaborador pode pedir a correção do histórico.');
      end if;
    end if;

    if trim(p_ds_mensagem) is null then
      erro(c_err_solicitacao, 'Descreva o que está incorreto.');
    end if;

    if p_id_historico_carreira is not null then
      select count(*)
        into l_qt
        from historico_carreira
       where id_historico_carreira = p_id_historico_carreira
         and id_colaborador        = p_id_colaborador;
      if l_qt = 0 then
        erro(c_err_registro, 'Lançamento não encontrado.');
      end if;
    end if;

    insert into solicitacao_correcao (id_empresa, id_colaborador, id_historico_carreira, ds_mensagem)
    values (l_col.id_empresa, l_col.id_colaborador, p_id_historico_carreira, substr(trim(p_ds_mensagem), 1, 2000))
    returning id_solicitacao into l_id;

    return l_id;
  end solicitar_correcao;

  procedure responder_solicitacao (
    p_id_solicitacao in number,
    p_st_solicitacao in varchar2,
    p_ds_resposta    in varchar2 default null
  ) is
    l_sol solicitacao_correcao%rowtype;
    l_usuario constant varchar2(255) := usuario_atual;  -- função privada não pode ser chamada dentro de SQL
  begin
    assert_admin_rh;

    begin
      select * into l_sol from solicitacao_correcao where id_solicitacao = p_id_solicitacao for update;
    exception
      when no_data_found then erro(c_err_solicitacao, 'Solicitação não encontrada.');
    end;
    assert_empresa(l_sol.id_empresa, 'Solicitação não encontrada.');

    if l_sol.st_solicitacao <> 'ABERTA' then
      erro(c_err_status, 'Esta solicitação já foi respondida.');
    end if;

    if p_st_solicitacao not in ('RESOLVIDA', 'RECUSADA') then
      erro(c_err_solicitacao, 'Responda com RESOLVIDA ou RECUSADA.');
    end if;

    if p_st_solicitacao = 'RECUSADA' and trim(p_ds_resposta) is null then
      erro(c_err_solicitacao, 'Explique ao colaborador por que a solicitação foi recusada.');
    end if;

    update solicitacao_correcao
       set st_solicitacao = p_st_solicitacao,
           ds_resposta    = p_ds_resposta,
           dt_resolucao   = systimestamp,
           usr_resolucao  = l_usuario
     where id_solicitacao = p_id_solicitacao;
  end responder_solicitacao;

  ------------------------------------------------------------------------------
  -- Consultas
  ------------------------------------------------------------------------------
  function fn_periodo (p_inicio in date, p_fim in date) return varchar2 is
  begin
    return formatar_periodo(p_inicio, p_fim);
  end fn_periodo;

  function fn_tempo_no_cargo (p_id_colaborador in number) return varchar2 is
    l_col    r_colaborador := carrega_colaborador(p_id_colaborador);
    l_inicio date;
  begin
    begin
      select dt_inicio_funcao
        into l_inicio
        from vw_situacao_atual_colaborador
       where id_colaborador = p_id_colaborador;
    exception
      when no_data_found then l_inicio := l_col.data_admissao;
    end;

    return formatar_periodo(l_inicio, fn_hoje(l_col.id_empresa));
  end fn_tempo_no_cargo;

  function fn_tempo_de_casa (p_id_colaborador in number) return varchar2 is
    l_col r_colaborador := carrega_colaborador(p_id_colaborador);
  begin
    return formatar_periodo(l_col.data_admissao, fn_hoje(l_col.id_empresa));
  end fn_tempo_de_casa;

  ------------------------------------------------------------------------------
  -- Segurança e LGPD
  ------------------------------------------------------------------------------
  function fn_pode_ver_colaborador (p_id_colaborador in number) return varchar2 is
    l_emp number;
    l_ctx number;
    l_eu  number;
    l_qt  pls_integer;
    l_usuario constant varchar2(255) := usuario_atual;  -- função privada não pode ser chamada dentro de SQL
  begin
    select id_empresa into l_emp from colaborador where id_colaborador = p_id_colaborador;

    l_ctx := fn_empresa_contexto;
    if l_ctx is not null and l_ctx <> l_emp then
      return 'N';
    end if;

    if not em_sessao_apex then
      return 'S';   -- scripts e jobs do dono do schema
    end if;

    if apex_authorization.is_authorized(c_auth_admin_rh) then
      return 'S';
    end if;

    select id_colaborador
      into l_eu
      from colaborador
     where upper(login_apex) = upper(l_usuario)
       and id_empresa        = l_emp;

    if l_eu = p_id_colaborador then
      return 'S';
    end if;

    -- Gestor: o colaborador está em qualquer nível abaixo dele
    select count(*)
      into l_qt
      from (select id_colaborador
              from colaborador
             where id_empresa = l_emp
             start with id_gestor = l_eu
           connect by nocycle prior id_colaborador = id_gestor)
     where id_colaborador = p_id_colaborador;

    return case when l_qt > 0 then 'S' else 'N' end;
  exception
    when no_data_found or too_many_rows then
      return 'N';
  end fn_pode_ver_colaborador;

  procedure registrar_acesso_salarial (
    p_id_colaborador in number,
    p_contexto       in varchar2 default null
  ) is
    pragma autonomous_transaction;
    l_ip varchar2(100);
    l_usuario constant varchar2(255) := usuario_atual;  -- função privada não pode ser chamada dentro de SQL
  begin
    begin
      l_ip := substr(coalesce(owa_util.get_cgi_env('X-FORWARDED-FOR'),
                              owa_util.get_cgi_env('REMOTE_ADDR')), 1, 100);
    exception
      when others then l_ip := null;   -- fora de requisição web
    end;

    insert into log_acesso_salarial (
      id_empresa, id_colaborador, ds_contexto, nr_aplicacao, nr_pagina, ds_ip, usr_criacao
    )
    select c.id_empresa, c.id_colaborador, substr(p_contexto, 1, 400),
           to_number(v('APP_ID')),
           to_number(v('APP_PAGE_ID')),
           l_ip, l_usuario
      from colaborador c
     where c.id_colaborador = p_id_colaborador;

    commit;
  exception
    when others then
      rollback;
      raise;
  end registrar_acesso_salarial;

  function fn_tratar_erro (p_error in apex_error.t_error) return apex_error.t_error_result is
    l_result apex_error.t_error_result;
  begin
    l_result := apex_error.init_error_result(p_error => p_error);

    if p_error.ora_sqlcode between -20099 and -20001 then
      l_result.message          := apex_error.get_first_ora_error_text(p_error => p_error);
      l_result.additional_info  := null;
      l_result.display_location := apex_error.c_inline_in_notification;
    end if;

    return l_result;
  end fn_tratar_erro;

end pkg_historico_carreira;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PKG_HISTORICO_CARREIRA_UI" as

  c_nls_data constant varchar2(60) := 'NLS_DATE_LANGUAGE=''BRAZILIAN PORTUGUESE''';
  c_nls_num  constant varchar2(60) := 'NLS_NUMERIC_CHARACTERS=''.,''';
  c_auto_adm constant varchar2(60) := 'Admissão registrada automaticamente';

  -- Ícones Lucide (stroke), herdam a cor do texto via currentColor
  c_svg constant varchar2(200) :=
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" '
    || 'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">';

  ------------------------------------------------------------------------------
  -- Eventos da linha do tempo: movimentações, formações e marcos de tempo de casa
  ------------------------------------------------------------------------------
  cursor c_eventos (p_id number, p_hoje date, p_admissao date) is
    with valida as (
      select v.id_historico_carreira,
             v.dt_efetiva,
             case
               when v.cd_tipo = 'ADMISSAO' then 1
               when lag(v.id_cargo_novo) over (order by v.dt_efetiva, v.id_historico_carreira) is null then 1
               when lag(v.id_cargo_novo) over (order by v.dt_efetiva, v.id_historico_carreira) <> v.id_cargo_novo then 1
               else 0
             end as fl_marco
        from vw_movimentacao_valida v
       where v.id_colaborador = p_id
    )
    select 'MOV'                     as ds_grupo,
           h.id_historico_carreira   as id_evento,
           h.dt_efetiva              as dt_evento,
           t.cd_tipo,
           t.ds_tipo,
           cast(null as varchar2(300)) as ds_titulo,
           h.st_registro,
           h.id_registro_estornado,
           eo.dt_efetiva             as dt_estornado,
           ca.nome                   as nm_cargo_ant,
           cn.nome                   as nm_cargo_novo,
           da.nome                   as nm_dep_ant,
           dn.nome                   as nm_dep_novo,
           ga.nome_completo          as nm_gestor_ant,
           gn.nome_completo          as nm_gestor_novo,
           h.id_gestor_novo,
           h.ds_motivo,
           h.usr_efetivacao,
           h.dt_efetivacao,
           h.id_comunicado,
           (select max(x.dt_efetiva)
              from valida x
             where x.fl_marco = 1
               and (   x.dt_efetiva < h.dt_efetiva
                    or (x.dt_efetiva = h.dt_efetiva and x.id_historico_carreira < h.id_historico_carreira)))
                                     as dt_inicio_cargo_ant,
           (select count(*)
              from vw_movimentacao_valida d
             where d.id_colaborador = h.id_colaborador
               and d.cd_tipo        = 'DESLIGAMENTO'
               and d.dt_efetiva     < h.dt_efetiva) as qt_desligamentos_antes,
           cast(null as varchar2(200))  as ds_instituicao,
           cast(null as number)         as nr_carga_horaria,
           cast(null as date)           as dt_conclusao,
           cast(null as date)           as dt_validade,
           cast(null as varchar2(1000)) as ds_link,
           cast(null as number)         as nr_anos,
           ap.nome_completo             as nm_aprovador
      from historico_carreira h
      join tipo_movimentacao  t  on t.id_tipo_movimentacao   = h.id_tipo_movimentacao
      left join cargo         ca on ca.id_cargo              = h.id_cargo_anterior
      left join cargo         cn on cn.id_cargo              = h.id_cargo_novo
      left join departamento  da on da.id_departamento       = h.id_departamento_anterior
      left join departamento  dn on dn.id_departamento       = h.id_departamento_novo
      left join colaborador   ga on ga.id_colaborador        = h.id_gestor_anterior
      left join colaborador   gn on gn.id_colaborador        = h.id_gestor_novo
      left join colaborador   ap on ap.id_colaborador        = h.id_aprovador
      left join historico_carreira eo on eo.id_historico_carreira = h.id_registro_estornado
     where h.id_colaborador = p_id
       and h.st_registro in ('EFETIVADO', 'ESTORNADO')
    union all
    select 'DEV', f.id_formacao, coalesce(f.dt_conclusao, f.dt_inicio), f.tp_formacao, null,
           f.ds_titulo, null, null, null, null, null, null, null, null, null, null, null, null,
           null, null, null, 0,
           f.ds_instituicao, f.nr_carga_horaria, f.dt_conclusao, f.dt_validade, f.ds_link, null, null
      from formacao_colaborador f
     where f.id_colaborador = p_id
    union all
    select 'MARCO', level, add_months(p_admissao, 12 * level), 'MARCO', null,
           null, null, null, null, null, null, null, null, null, null, null, null, null,
           null, null, null, 0,
           null, null, null, null, null, level, null
      from dual
     where p_admissao is not null
       and add_months(p_admissao, 12 * level) <= p_hoje
   connect by level <= greatest(floor(months_between(p_hoje, p_admissao) / 12), 1)
     order by 3 desc, 1, 2 desc;

  type t_eventos is table of c_eventos%rowtype;

  type r_segmento is record (
    nm_cargo varchar2(400),
    dt_ini   date,
    dt_fim   date,
    fl_atual boolean,
    fl_vazio boolean
  );
  type t_segmentos is table of r_segmento index by pls_integer;

  type t_qt_ano is table of pls_integer index by pls_integer;

  -- Contexto da renderização atual
  g_html              clob;
  g_id_empresa        number;
  g_nm_empresa        varchar2(400);
  g_hoje              date;
  g_rh                boolean;
  g_proprio           boolean;
  g_id_gestor_atual   number;
  g_id_evento_cargo   number;   -- evento que iniciou o cargo atual
  g_vinculo_ativo     boolean;

  ------------------------------------------------------------------------------
  -- Utilitários
  ------------------------------------------------------------------------------
  procedure inicia is
  begin
    dbms_lob.createtemporary(g_html, true, dbms_lob.call);
  end inicia;

  procedure p (p_txt in varchar2) is
  begin
    if p_txt is not null then
      dbms_lob.writeappend(g_html, length(p_txt), p_txt);
    end if;
  end p;

  function e (p_txt in varchar2) return varchar2 is
  begin
    return apex_escape.html(p_txt);
  end e;

  function a (p_txt in varchar2) return varchar2 is
  begin
    return apex_escape.html_attribute(p_txt);
  end a;

  function url (p_pagina in pls_integer, p_item in varchar2 default null, p_valor in varchar2 default null) return varchar2 is
  begin
    if p_pagina is null then
      return null;
    elsif sys_context('APEX$SESSION', 'APP_SESSION') is null then
      return '#';   -- fora do APEX (testes): não há aplicação para montar a URL
    end if;
    if p_item is null then
      return apex_page.get_url(p_page => p_pagina);
    end if;
    return apex_page.get_url(p_page => p_pagina, p_items => p_item, p_values => p_valor);
  end url;

  function plural (p_qtd in number, p_singular in varchar2, p_plural in varchar2) return varchar2 is
  begin
    return p_qtd || ' ' || case when p_qtd = 1 then p_singular else p_plural end;
  end plural;

  function juntar (p_a in varchar2, p_b in varchar2, p_sep in varchar2 default ' · ') return varchar2 is
  begin
    if p_a is null then return p_b; end if;
    if p_b is null then return p_a; end if;
    return p_a || p_sep || p_b;
  end juntar;

  function iniciais (p_nome in varchar2) return varchar2 is
    l_nome varchar2(400) := trim(regexp_replace(p_nome, '\s+', ' '));
  begin
    if l_nome is null then
      return '?';
    elsif instr(l_nome, ' ') = 0 then
      return upper(substr(l_nome, 1, 2));
    end if;
    return upper(substr(l_nome, 1, 1) || substr(l_nome, instr(l_nome, ' ', -1) + 1, 1));
  end iniciais;

  function fmt (p_data in date) return varchar2 is
  begin
    return to_char(p_data, 'dd/mm/yyyy');
  end fmt;

  -- "24 set"
  function data_curta (p_data in date) return varchar2 is
  begin
    return to_char(p_data, 'fmdd') || ' ' || to_char(p_data, 'mon', c_nls_data);
  end data_curta;

  -- "13 de junho de 2022"
  function data_longa (p_data in date) return varchar2 is
  begin
    return to_char(p_data, 'fmdd') || ' de ' || to_char(p_data, 'fmmonth', c_nls_data)
           || ' de ' || to_char(p_data, 'yyyy');
  end data_longa;

  -- "março de 2024"
  function mes_ano (p_data in date) return varchar2 is
  begin
    return to_char(p_data, 'fmmonth', c_nls_data) || ' de ' || to_char(p_data, 'yyyy');
  end mes_ano;

  -- "jun/2022"
  function mes_abrev (p_data in date) return varchar2 is
  begin
    return to_char(p_data, 'mon', c_nls_data) || '/' || to_char(p_data, 'yyyy');
  end mes_abrev;

  function pct (p_valor in number) return varchar2 is
  begin
    return to_char(round(p_valor, 2), 'fm990.00', c_nls_num);
  end pct;

  function periodo (p_ini in date, p_fim in date) return varchar2 is
  begin
    return pkg_historico_carreira.fn_periodo(p_ini, p_fim);
  end periodo;

  function nome_por_login (p_login in varchar2) return varchar2 is
    l_nome colaborador.nome_completo%type;
  begin
    if p_login is null then
      return null;
    end if;
    select max(nome_completo)
      into l_nome
      from colaborador
     where upper(login_apex) = upper(p_login)
       and id_empresa        = g_id_empresa;
    return l_nome;
  end nome_por_login;

  function ico (p_nome in varchar2) return varchar2 is
    l_corpo varchar2(2000);
  begin
    l_corpo := case p_nome
      when 'download'    then '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/>'
      when 'seta'        then '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>'
      when 'cadeado'     then '<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>'
      when 'aprovador'   then '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><polyline points="16 11 18 13 22 9"/>'
      when 'registro'    then '<rect width="8" height="4" x="8" y="2" rx="1" ry="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><path d="m9 14 2 2 4-4"/>'
      when 'megafone'    then '<path d="m3 11 18-5v12L3 14v-3z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/>'
      when 'alerta'      then '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/><path d="M12 7v2"/><path d="M12 13h.01"/>'
      when 'ADMISSAO'    then '<path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" x2="3" y1="12" y2="12"/>'
      when 'DESLIGAMENTO' then '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/>'
      when 'PROMOCAO'    then '<polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/><polyline points="16 7 22 7 22 13"/>'
      when 'MUDANCA_CARGO' then '<rect width="20" height="14" x="2" y="7" rx="2" ry="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>'
      when 'TRANSFERENCIA_DEPTO' then '<path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z"/><path d="M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2"/><path d="M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2"/><path d="M10 6h4"/><path d="M10 10h4"/><path d="M10 14h4"/>'
      when 'MUDANCA_GESTOR' then '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>'
      when 'EFETIVACAO_CONTRATO' then '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="m9 15 2 2 4-4"/>'
      when 'MERITO'      then '<rect width="20" height="12" x="2" y="6" rx="2"/><circle cx="12" cy="12" r="2"/><path d="M6 12h.01M18 12h.01"/>'
      when 'ALTERACAO_JORNADA' then '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>'
      when 'AFASTAMENTO' then '<circle cx="12" cy="12" r="10"/><line x1="10" x2="10" y1="15" y2="9"/><line x1="14" x2="14" y1="15" y2="9"/>'
      when 'RETORNO'     then '<circle cx="12" cy="12" r="10"/><polygon points="10 8 16 12 10 16 10 8"/>'
      when 'ESTORNO'     then '<path d="M9 14 4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 5.5 5.5v0a5.5 5.5 0 0 1-5.5 5.5H11"/>'
      when 'CERTIFICACAO' then '<circle cx="12" cy="8" r="6"/><path d="M15.477 12.89 17 22l-5-3-5 3 1.523-9.11"/>'
      when 'IDIOMA'      then '<path d="m5 8 6 6"/><path d="m4 14 6-6 2-3"/><path d="M2 5h12"/><path d="M7 2h1"/><path d="m22 22-5-10-5 10"/><path d="M14 18h6"/>'
      when 'CURSO'       then '<path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/>'
      when 'GRADUACAO'   then '<path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/>'
      when 'POS'         then '<path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/>'
      when 'MBA'         then '<path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/>'
      when 'MARCO'       then '<path d="M5.8 11.3 2 22l10.7-3.79"/><path d="M4 3h.01"/><path d="M22 8h.01"/><path d="M15 2h.01"/><path d="M22 20h.01"/><path d="M11 13c1.93 1.93 2.83 4.17 2 5-.83.83-3.07-.07-5-2-1.93-1.93-2.83-4.17-2-5 .83-.83 3.07.07 5 2Z"/>'
      else '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="1"/>'
    end;
    return c_svg || l_corpo || '</svg>';
  end ico;

  ------------------------------------------------------------------------------
  -- Textos por tipo
  ------------------------------------------------------------------------------
  function categoria (p_cd in varchar2, p_ds_tipo in varchar2) return varchar2 is
  begin
    return case p_cd
             when 'ADMISSAO'            then 'Admissão'
             when 'PROMOCAO'            then 'Promoção'
             when 'MUDANCA_CARGO'       then 'Cargo'
             when 'TRANSFERENCIA_DEPTO' then 'Área'
             when 'MUDANCA_GESTOR'      then 'Gestão'
             when 'EFETIVACAO_CONTRATO' then 'Contrato'
             when 'MERITO'              then 'Remuneração'
             when 'ALTERACAO_JORNADA'   then 'Jornada'
             when 'AFASTAMENTO'         then 'Afastamento'
             when 'RETORNO'             then 'Afastamento'
             when 'DESLIGAMENTO'        then 'Desligamento'
             when 'GRADUACAO'           then 'Graduação'
             when 'POS'                 then 'Pós-graduação'
             when 'MBA'                 then 'MBA'
             when 'CURSO'               then 'Curso'
             when 'CERTIFICACAO'        then 'Certificação'
             when 'IDIOMA'              then 'Idioma'
             when 'MARCO'               then 'Tempo de casa'
             else p_ds_tipo
           end;
  end categoria;

  function titulo_movimentacao (r in c_eventos%rowtype) return varchar2 is
  begin
    return case r.cd_tipo
             when 'ADMISSAO' then
               case when r.qt_desligamentos_antes > 0 then 'Retorno à ' else 'Entrada na ' end || g_nm_empresa
             when 'PROMOCAO'            then 'Promoção a ' || nvl(r.nm_cargo_novo, 'novo cargo')
             when 'MUDANCA_CARGO'       then 'Mudança para ' || nvl(r.nm_cargo_novo, 'novo cargo')
             when 'TRANSFERENCIA_DEPTO' then 'Transferência para ' || nvl(r.nm_dep_novo, 'nova área')
             when 'MUDANCA_GESTOR'      then 'Mudança de gestão direta'
             when 'EFETIVACAO_CONTRATO' then 'Período de experiência concluído'
             when 'MERITO'              then 'Reajuste por mérito'
             when 'DESLIGAMENTO'        then 'Saída da ' || g_nm_empresa
             else r.ds_tipo
           end;
  end titulo_movimentacao;

  function descricao_movimentacao (r in c_eventos%rowtype) return varchar2 is
    l_txt varchar2(4000);
  begin
    if r.cd_tipo = 'MERITO' then
      return 'Os valores ficam no holerite digital. Registros de remuneração não geram comunicado à equipe.';
    end if;

    -- Motivo de afastamento pode ter dado de saúde: só o próprio e o RH leem
    if r.cd_tipo in ('AFASTAMENTO', 'RETORNO') and not (g_proprio or g_rh) then
      return null;
    end if;

    if r.cd_tipo = 'ADMISSAO' then
      l_txt := 'Início como ' || nvl(r.nm_cargo_novo, 'cargo não informado')
               || nvl2(r.nm_dep_novo, ', na área de ' || r.nm_dep_novo, '')
               || nvl2(r.nm_gestor_novo, ', com gestão de ' || r.nm_gestor_novo, '') || '.';
      if r.ds_motivo is not null and r.ds_motivo not like c_auto_adm || '%' then
        l_txt := l_txt || ' ' || r.ds_motivo;
      end if;
      return l_txt;
    end if;

    if r.cd_tipo = 'MUDANCA_GESTOR' and r.ds_motivo is null then
      return r.nm_gestor_novo || ' assumiu a gestão direta.';
    end if;

    return r.ds_motivo;
  end descricao_movimentacao;

  ------------------------------------------------------------------------------
  -- Blocos de um evento
  ------------------------------------------------------------------------------
  procedure meta (p_icone in varchar2, p_texto in varchar2) is
  begin
    if p_texto is not null then
      p('<span class="hc-meta">' || ico(p_icone) || '<span>' || e(p_texto) || '</span></span>');
    end if;
  end meta;

  procedure link_seta (p_href in varchar2, p_texto in varchar2, p_externo in boolean default false) is
  begin
    if p_href is not null then
      p('<a class="hc-link" href="' || a(p_href) || '"'
        || case when p_externo then ' target="_blank" rel="noopener noreferrer"' end
        || '>' || e(p_texto) || ico('seta') || '</a>');
    end if;
  end link_seta;

  procedure antes_depois (r in c_eventos%rowtype) is
    l_atual boolean := r.id_evento = g_id_evento_cargo;
  begin
    if r.cd_tipo in ('PROMOCAO', 'MUDANCA_CARGO') and r.nm_cargo_ant is not null then
      p('<div class="hc-antes-depois">'
        || '<div><span class="hc-rotulo">Antes</span><strong>' || e(r.nm_cargo_ant) || '</strong>'
        || '<span>' || e(juntar(r.nm_dep_ant,
                                 case when r.dt_inicio_cargo_ant is not null
                                      then periodo(r.dt_inicio_cargo_ant, r.dt_evento) || ' no cargo' end)) || '</span></div>'
        || ico('seta')
        || '<div><span class="hc-rotulo">Depois</span><strong>' || e(r.nm_cargo_novo) || '</strong>'
        || '<span>' || e(juntar(r.nm_dep_novo,
                                 case when l_atual then 'vigente desde ' else 'a partir de ' end || fmt(r.dt_evento)))
        || '</span></div></div>');

    elsif r.cd_tipo = 'TRANSFERENCIA_DEPTO' and r.nm_dep_ant is not null then
      p('<div class="hc-antes-depois">'
        || '<div><span class="hc-rotulo">Antes</span><strong>' || e(r.nm_dep_ant) || '</strong>'
        || '<span>' || e(r.nm_cargo_ant) || '</span></div>'
        || ico('seta')
        || '<div><span class="hc-rotulo">Depois</span><strong>' || e(r.nm_dep_novo) || '</strong>'
        || '<span>' || e(juntar(r.nm_cargo_novo, 'a partir de ' || fmt(r.dt_evento))) || '</span></div></div>');

    elsif r.cd_tipo = 'MUDANCA_GESTOR' and r.nm_gestor_novo is not null then
      p('<div class="hc-pessoas">');
      if r.nm_gestor_ant is not null then
        p('<div class="hc-pessoa"><span class="hc-avatar">' || e(iniciais(r.nm_gestor_ant)) || '</span>'
          || '<span><strong>' || e(r.nm_gestor_ant) || '</strong><span>Gestão anterior</span></span></div>'
          || ico('seta'));
      end if;
      p('<div class="hc-pessoa"><span class="hc-avatar hc-avatar--destaque">' || e(iniciais(r.nm_gestor_novo)) || '</span>'
        || '<span><strong>' || e(r.nm_gestor_novo) || '</strong><span>'
        || case
             when r.st_registro = 'EFETIVADO' and r.id_gestor_novo = g_id_gestor_atual then 'Gestão atual'
             else 'Nova gestão'
           end
        || '</span></span></div></div>');
    end if;
  end antes_depois;

  procedure evento (r in c_eventos%rowtype) is
    l_estorno   boolean := r.id_registro_estornado is not null;
    l_estornado boolean := r.st_registro = 'ESTORNADO';
    l_ponto     varchar2(30);
    l_icone     varchar2(30);
    l_titulo    varchar2(1000);
    l_desc      varchar2(4000);
    l_tag       varchar2(100) := categoria(r.cd_tipo, r.ds_tipo);
    l_nome_rh   varchar2(400);
    l_dt_reg    date;
    l_link_href varchar2(4000);
    l_link_txt  varchar2(100);
    l_link_ext  boolean := false;
  begin
    -- Título, descrição, ícone e cor do ponto
    if r.ds_grupo = 'MOV' then
      if l_estorno then
        l_titulo := 'Correção de lançamento';
        l_desc   := juntar('O RH reverteu o lançamento de ' || lower(r.ds_tipo) || ' de ' || fmt(r.dt_estornado) || '.',
                           r.ds_motivo, ' ');
        l_icone  := 'ESTORNO';
        l_ponto  := 'alerta';
      else
        l_titulo := titulo_movimentacao(r);
        l_desc   := descricao_movimentacao(r);
        l_icone  := r.cd_tipo;
        l_ponto  := case when r.cd_tipo = 'PROMOCAO' then 'forte' else 'suave' end;
      end if;

    elsif r.ds_grupo = 'DEV' then
      l_titulo := r.ds_titulo;
      l_desc   := juntar(r.ds_instituicao,
                    juntar(case when r.dt_conclusao is null then 'em andamento' end,
                      case when r.nr_carga_horaria is not null
                           then to_char(r.nr_carga_horaria, 'fm99990') || 'h' end));
      if r.dt_validade is not null then
        l_desc := juntar(l_desc, case when r.dt_validade < g_hoje then 'vencida em ' else 'válida até ' end
                                 || fmt(r.dt_validade));
      end if;
      l_icone  := r.cd_tipo;
      l_ponto  := 'neutro';

    else  -- MARCO
      l_titulo := plural(r.nr_anos, 'ano', 'anos') || ' de ' || g_nm_empresa;
      l_icone  := 'MARCO';
      l_ponto  := 'neutro';
    end if;

    p('<li class="hc-evento' || case when l_estornado then ' is-estornado' end
      || '" data-grupo="' || lower(r.ds_grupo) || '" data-ano="' || to_char(r.dt_evento, 'yyyy') || '">');
    p('<time class="hc-evento__data" datetime="' || to_char(r.dt_evento, 'yyyy-mm-dd') || '">'
      || e(data_curta(r.dt_evento)) || '</time>');
    p('<div class="hc-evento__corpo">');
    p('<span class="hc-ponto hc-ponto--' || l_ponto || '">' || ico(l_icone) || '</span>');

    -- Título + tags
    p('<div class="hc-evento__titulo"><h3>' || e(l_titulo) || '</h3>'
      || '<span class="hc-tag">' || e(l_tag) || '</span>');
    if l_estornado then
      p('<span class="hc-tag hc-tag--alerta">Estornado</span>');
    end if;
    if r.ds_grupo = 'MOV' and not l_estorno and r.id_evento = g_id_evento_cargo then
      p('<span class="hc-pill">Cargo atual</span>');
    end if;
    if r.ds_grupo = 'DEV' and r.dt_validade is not null and r.dt_validade < g_hoje then
      p('<span class="hc-tag hc-tag--alerta">Vencida</span>');
    elsif r.ds_grupo = 'DEV' and r.dt_validade is not null and r.dt_validade <= g_hoje + 60 then
      p('<span class="hc-tag hc-tag--aviso">Vence em breve</span>');
    end if;
    p('</div>');

    if l_desc is not null then
      p('<p class="hc-evento__desc">' || e(l_desc) || '</p>');
    end if;

    if r.ds_grupo = 'MOV' and not l_estorno then
      antes_depois(r);
    end if;

    -- Rodapé: quem registrou, visibilidade e link
    if r.ds_grupo = 'MOV' then
      l_nome_rh := nome_por_login(r.usr_efetivacao);
      l_dt_reg  := trunc(pkg_historico_carreira.fn_data_local(g_id_empresa, r.dt_efetivacao));
      if r.cd_tipo = 'MERITO' then
        l_link_href := url(c_pagina_holerite);
        l_link_txt  := 'Ver holerite';
      end if;
    elsif r.ds_grupo = 'DEV' and r.ds_link is not null then
      l_link_href := r.ds_link;
      l_link_txt  := 'Ver certificado';
      l_link_ext  := true;
    end if;

    if r.ds_grupo = 'MOV' or l_link_href is not null then
      p('<div class="hc-evento__rodape"><div class="hc-evento__metas">');
      if r.ds_grupo = 'MOV' then
        if r.cd_tipo = 'MERITO' then
          meta('cadeado', 'Visível só para você e o RH');
        end if;
        meta('registro', case
                           when l_nome_rh is not null then 'Registrado por ' || l_nome_rh || ' (RH) em ' || fmt(l_dt_reg)
                           when l_dt_reg  is not null then 'Registrado pelo RH em ' || fmt(l_dt_reg)
                         end);
        meta('aprovador', nvl2(r.nm_aprovador, 'Aprovado por ' || r.nm_aprovador, null));
      end if;
      p('</div>');
      link_seta(l_link_href, l_link_txt, l_link_ext);
      p('</div>');
    end if;

    -- Comunicado automático
    if r.id_comunicado is not null and not l_estorno then
      p('<div class="hc-aviso">' || ico('megafone') || '<span>'
        || e(case
               when r.cd_tipo = 'ADMISSAO' then
                 'Boas-vindas enviadas automaticamente' || nvl2(r.nm_dep_novo, ' à equipe de ' || r.nm_dep_novo, ' à equipe') || '.'
               else
                 nvl2(r.nm_dep_novo, 'Equipe de ' || r.nm_dep_novo, 'Equipe') || ' avisada automaticamente em ' || fmt(l_dt_reg) || '.'
             end)
        || '</span>');
      link_seta(url(c_pagina_comunicado, c_item_comunicado, r.id_comunicado), 'Ver comunicado');
      p('</div>');
    end if;

    p('</div></li>');
  end evento;

  ------------------------------------------------------------------------------
  -- Seções
  ------------------------------------------------------------------------------
  procedure cargos_no_tempo (p_id in number) is
    l_seg     t_segmentos;
    l_n       pls_integer := 0;
    l_aberto  boolean := false;
    l_marco   number;
    l_ini     date;
    l_fim     date;
    l_total   number;
    l_d       date;
    l_pos     number;
  begin
    g_id_evento_cargo := null;

    for r in (
      select v.id_historico_carreira, v.dt_efetiva, v.cd_tipo, cg.nome as nm_cargo,
             case
               when v.cd_tipo = 'ADMISSAO' then 1
               when lag(v.id_cargo_novo) over (order by v.dt_efetiva, v.id_historico_carreira) is null then 1
               when lag(v.id_cargo_novo) over (order by v.dt_efetiva, v.id_historico_carreira) <> v.id_cargo_novo then 1
               else 0
             end as fl_marco
        from vw_movimentacao_valida v
        left join cargo cg on cg.id_cargo = v.id_cargo_novo
       where v.id_colaborador = p_id
       order by v.dt_efetiva, v.id_historico_carreira
    ) loop
      if r.cd_tipo = 'DESLIGAMENTO' then
        if l_aberto then
          l_seg(l_n).dt_fim := r.dt_efetiva;
          l_aberto := false;
        end if;
      elsif r.fl_marco = 1 then
        if l_aberto then
          l_seg(l_n).dt_fim := r.dt_efetiva;
        elsif l_n > 0 and l_seg(l_n).dt_fim < r.dt_efetiva then
          -- período fora da empresa (entre desligamento e readmissão)
          l_n := l_n + 1;
          l_seg(l_n).dt_ini   := l_seg(l_n - 1).dt_fim;
          l_seg(l_n).dt_fim   := r.dt_efetiva;
          l_seg(l_n).fl_vazio := true;
          l_seg(l_n).fl_atual := false;
        end if;
        l_n := l_n + 1;
        l_seg(l_n).nm_cargo := nvl(r.nm_cargo, 'Cargo não informado');
        l_seg(l_n).dt_ini   := r.dt_efetiva;
        l_seg(l_n).fl_atual := false;
        l_seg(l_n).fl_vazio := false;
        l_aberto := true;
        l_marco  := r.id_historico_carreira;
      end if;
    end loop;

    if l_n = 0 then
      return;
    end if;

    if l_aberto then
      l_seg(l_n).dt_fim   := greatest(g_hoje, l_seg(l_n).dt_ini);
      l_seg(l_n).fl_atual := true;
      g_id_evento_cargo   := l_marco;
    end if;

    l_ini   := l_seg(1).dt_ini;
    l_fim   := l_seg(l_n).dt_fim;
    l_total := greatest(l_fim - l_ini, 1);

    p('<div class="hc-cargos"><h2 class="hc-subtitulo">Cargos ao longo do tempo</h2>');
    p('<div class="hc-faixa" role="list">');
    for i in 1 .. l_n loop
      if l_seg(i).fl_vazio then
        p('<div class="hc-faixa__seg hc-faixa__seg--vazio" style="flex-grow:'
          || greatest(l_seg(i).dt_fim - l_seg(i).dt_ini, 1) || '" title="Fora da empresa"></div>');
      else
        p('<div class="hc-faixa__seg' || case when l_seg(i).fl_atual then ' is-atual' end
          || '" role="listitem" style="flex-grow:' || greatest(l_seg(i).dt_fim - l_seg(i).dt_ini, 1)
          || '" title="' || a(l_seg(i).nm_cargo) || '">'
          || '<strong>' || e(l_seg(i).nm_cargo) || case when l_seg(i).fl_atual then ' · atual' end || '</strong>'
          || '<span>' || e(mes_abrev(l_seg(i).dt_ini) || ' – '
                           || case when l_seg(i).fl_atual then 'hoje' else mes_abrev(l_seg(i).dt_fim) end
                           || ' · ' || periodo(l_seg(i).dt_ini, l_seg(i).dt_fim)) || '</span></div>');
      end if;
    end loop;
    p('</div>');

    -- Eixo: início, viradas de ano e "hoje"
    p('<div class="hc-eixo" aria-hidden="true">');
    p('<span style="left:0%">' || e(mes_abrev(l_ini)) || '</span>');
    for y in to_number(to_char(l_ini, 'yyyy')) + 1 .. to_number(to_char(l_fim, 'yyyy')) loop
      l_d   := to_date(y || '-01-01', 'yyyy-mm-dd');
      l_pos := (l_d - l_ini) / l_total * 100;
      if l_pos between 10 and 88 then
        p('<span style="left:' || pct(l_pos) || '%">' || y || '</span>');
      end if;
    end loop;
    p('<span class="hc-eixo__fim">'
      || case when l_seg(l_n).fl_atual then 'hoje' else e(mes_abrev(l_fim)) end || '</span>');
    p('</div></div>');
  end cargos_no_tempo;

  procedure indicador (p_rotulo in varchar2, p_valor in varchar2, p_detalhe in varchar2) is
  begin
    p('<div class="hc-indicador"><span class="hc-indicador__rotulo">' || e(p_rotulo) || '</span>'
      || '<strong class="hc-indicador__valor">' || e(nvl(p_valor, '—')) || '</strong>'
      || '<span class="hc-indicador__detalhe">' || e(p_detalhe) || '</span></div>');
  end indicador;

  procedure item_posicao (p_chave in varchar2, p_valor in varchar2) is
  begin
    if p_valor is not null then
      p('<div><dt>' || e(p_chave) || '</dt><dd>' || e(p_valor) || '</dd></div>');
    end if;
  end item_posicao;

  procedure item_sobre (p_icone in varchar2, p_titulo in varchar2, p_texto in varchar2) is
  begin
    p('<li><span class="hc-sobre__icone">' || ico(p_icone) || '</span>'
      || '<span><strong>' || e(p_titulo) || '</strong><span>' || e(p_texto) || '</span></span></li>');
  end item_sobre;

  ------------------------------------------------------------------------------
  -- Página
  ------------------------------------------------------------------------------
  function render (p_id_colaborador in number) return clob is
    l_nome       colaborador.nome_completo%type;
    l_login      colaborador.login_apex%type;
    l_admissao   date;
    l_cargo      varchar2(400);
    l_depto      varchar2(400);
    l_gestor     varchar2(400);
    l_ini_funcao date;
    l_qt_promo   pls_integer;
    l_ult_promo  date;
    l_dt_efetiv  date;
    l_dt_deslig  date;
    l_qt_abertas pls_integer;
    l_auto       boolean;
    l_fl_ativo   varchar2(1);
    l_ev         t_eventos;
    l_visiveis   t_eventos := t_eventos();
    l_qt_ano     t_qt_ano;
    l_qt_mov     pls_integer := 0;
    l_qt_dev     pls_integer := 0;
    l_ano        pls_integer;
    l_ano_ant    pls_integer;
    l_anos       varchar2(4000);
  begin
    if pkg_historico_carreira.fn_pode_ver_colaborador(p_id_colaborador) = 'N' then
      raise_application_error(pkg_historico_carreira.c_err_permissao,
                              'Você não tem acesso ao histórico deste colaborador.');
    end if;

    -- Colaborador, empresa e quem está vendo
    select c.nome_completo, c.login_apex, c.data_admissao, c.id_empresa,
           coalesce(em.nome_fantasia, em.nome)
      into l_nome, l_login, l_admissao, g_id_empresa, g_nm_empresa
      from colaborador c
      join empresa em on em.id_empresa = c.id_empresa
     where c.id_colaborador = p_id_colaborador;

    g_hoje    := pkg_historico_carreira.fn_hoje(g_id_empresa);
    g_proprio := nvl(upper(l_login) = upper(sys_context('APEX$SESSION', 'APP_USER')), false);
    g_rh      := sys_context('APEX$SESSION', 'APP_SESSION') is null
                 or apex_authorization.is_authorized(pkg_historico_carreira.c_auth_admin_rh);

    -- Situação atual (com fallback para o cadastro, se ainda não houver histórico)
    begin
      select s.nm_cargo, s.nm_departamento, s.nm_gestor, s.id_gestor, s.dt_inicio_funcao,
             s.fl_vinculo_ativo,
             case when s.cd_ultimo_tipo = 'DESLIGAMENTO' then s.dt_ultima_movimentacao end
        into l_cargo, l_depto, l_gestor, g_id_gestor_atual, l_ini_funcao, l_fl_ativo, l_dt_deslig
        from vw_situacao_atual_colaborador s
       where s.id_colaborador = p_id_colaborador;
      g_vinculo_ativo := l_fl_ativo = 'S';
    exception
      when no_data_found then
        select cg.nome, d.nome, g.nome_completo, c.id_gestor
          into l_cargo, l_depto, l_gestor, g_id_gestor_atual
          from colaborador c
          left join cargo        cg on cg.id_cargo       = c.id_cargo
          left join departamento d  on d.id_departamento = c.id_departamento
          left join colaborador  g  on g.id_colaborador  = c.id_gestor
         where c.id_colaborador = p_id_colaborador;
        l_ini_funcao    := l_admissao;
        g_vinculo_ativo := true;
    end;

    select count(*), max(dt_efetiva)
      into l_qt_promo, l_ult_promo
      from vw_movimentacao_valida
     where id_colaborador = p_id_colaborador
       and cd_tipo        = 'PROMOCAO';

    select max(dt_efetiva)
      into l_dt_efetiv
      from vw_movimentacao_valida
     where id_colaborador = p_id_colaborador
       and cd_tipo        = 'EFETIVACAO_CONTRATO';

    begin
      select fl_comunicado_automatico into l_auto from config_carreira where id_empresa = g_id_empresa;
    exception
      when no_data_found then l_auto := true;
    end;

    -- Eventos visíveis para quem está vendo
    open c_eventos(p_id_colaborador, g_hoje, l_admissao);
    fetch c_eventos bulk collect into l_ev;
    close c_eventos;

    for i in 1 .. l_ev.count loop
      if not (l_ev(i).cd_tipo = 'MERITO' and not (g_proprio or g_rh)) then
        l_visiveis.extend;
        l_visiveis(l_visiveis.count) := l_ev(i);
        l_ano := to_number(to_char(l_ev(i).dt_evento, 'yyyy'));
        l_qt_ano(l_ano) := case when l_qt_ano.exists(l_ano) then l_qt_ano(l_ano) else 0 end + 1;
        if l_ev(i).ds_grupo = 'MOV' then
          l_qt_mov := l_qt_mov + 1;
        elsif l_ev(i).ds_grupo = 'DEV' then
          l_qt_dev := l_qt_dev + 1;
        end if;
      end if;
    end loop;

    inicia;
    p('<div class="hc" data-hc>');

    -- Título
    p('<header class="hc-titulo"><div><h1>Histórico de carreira</h1><p>'
      || e(case
             when g_proprio then 'Cargos, promoções e mudanças de gestão registrados pelo RH desde a sua entrada na '
                                 || g_nm_empresa || '.'
             else 'Cargos, promoções e mudanças de gestão de ' || l_nome
                  || ', registrados pelo RH desde a entrada na ' || g_nm_empresa || '.'
           end)
      || '</p></div>'
      || '<button type="button" class="hc-btn" data-hc-acao="exportar">' || ico('download')
      || '<span>Exportar PDF</span></button></header>');

    p('<div class="hc-conteudo"><div class="hc-principal">');

    -- Resumo
    p('<section class="hc-card hc-resumo" aria-label="Resumo da trajetória"><div class="hc-indicadores">');
    indicador('Tempo de casa', pkg_historico_carreira.fn_periodo(l_admissao, coalesce(l_dt_deslig, g_hoje)),
              case when l_admissao is not null then 'Desde ' || data_longa(l_admissao) end);
    indicador(case when g_vinculo_ativo then 'No cargo atual' else 'No último cargo' end,
              pkg_historico_carreira.fn_periodo(l_ini_funcao, coalesce(l_dt_deslig, g_hoje)), l_cargo);
    indicador('Promoções', to_char(l_qt_promo),
              case
                when l_qt_promo = 0 then 'Nenhuma até agora'
                when l_qt_promo = 1 then 'Em ' || mes_ano(l_ult_promo)
                else 'A última em ' || mes_ano(l_ult_promo)
              end);
    p('</div>');
    cargos_no_tempo(p_id_colaborador);
    p('</section>');

    -- Linha do tempo
    p('<section class="hc-card hc-linha-tempo" aria-label="Linha do tempo">');
    p('<div class="hc-abas"><div class="hc-abas__lista" role="tablist" aria-label="Tipo de registro">'
      || '<button type="button" role="tab" aria-selected="true" data-hc-filtro="tudo">Tudo · '
      || l_visiveis.count || '</button>'
      || '<button type="button" role="tab" aria-selected="false" data-hc-filtro="mov">Movimentações · '
      || l_qt_mov || '</button>'
      || '<button type="button" role="tab" aria-selected="false" data-hc-filtro="dev">Desenvolvimento · '
      || l_qt_dev || '</button></div>');

    l_ano := l_qt_ano.last;
    while l_ano is not null loop
      l_anos := l_anos || '<option value="' || l_ano || '">' || l_ano || '</option>';
      l_ano  := l_qt_ano.prior(l_ano);
    end loop;
    p('<label class="hc-filtro"><span>Ano:</span><select data-hc-ano>'
      || '<option value="">Todos</option>' || l_anos || '</select></label></div>');

    if l_visiveis.count = 0 then
      p('<p class="hc-vazio">Ainda não há registros no histórico.</p>');
    else
      p('<ol class="hc-linha">');
      l_ano_ant := null;
      for i in 1 .. l_visiveis.count loop
        l_ano := to_number(to_char(l_visiveis(i).dt_evento, 'yyyy'));
        if l_ano_ant is null or l_ano <> l_ano_ant then
          p('<li class="hc-ano" data-ano="' || l_ano || '"><span class="hc-ano__rotulo">' || l_ano || '</span>'
            || '<span class="hc-ano__divisor"><span class="hc-ano__qt">'
            || plural(l_qt_ano(l_ano), 'registro', 'registros') || '</span></span></li>');
          l_ano_ant := l_ano;
        end if;
        evento(l_visiveis(i));
      end loop;
      p('</ol>');
      p('<p class="hc-vazio" data-hc-sem-resultado hidden>Nenhum registro para este filtro.</p>');
    end if;
    p('</section></div>');

    -- Lateral
    p('<aside class="hc-lateral">');

    p('<section class="hc-card"><h2 class="hc-card__titulo">'
      || case when g_vinculo_ativo then 'Posição atual' else 'Última posição' end || '</h2><dl class="hc-posicao">');
    item_posicao('Cargo', l_cargo);
    item_posicao('Área', l_depto);
    item_posicao('Gestão direta', l_gestor);
    item_posicao('No cargo desde', fmt(l_ini_funcao));
    item_posicao('Contrato', case when l_dt_efetiv is not null then 'Efetivado em ' || fmt(l_dt_efetiv) end);
    item_posicao('Situação', case when l_dt_deslig is not null then 'Desligado em ' || fmt(l_dt_deslig) end);
    p('</dl>');
    if c_pagina_organograma is not null and g_vinculo_ativo then
      p('<div class="hc-card__rodape">');
      link_seta(url(c_pagina_organograma, c_item_organograma, p_id_colaborador), 'Ver no organograma');
      p('</div>');
    end if;
    p('</section>');

    p('<section class="hc-card"><h2 class="hc-card__titulo">Sobre este histórico</h2><div class="hc-sobre"><ul>');
    item_sobre('registro', 'Registrado pelo RH', 'Cada mudança entra com data de vigência e quem registrou.');
    if l_auto then
      item_sobre('megafone', 'Equipe avisada', 'Admissões, promoções e mudanças de área geram um comunicado automático.');
    end if;
    item_sobre('cadeado', 'Remuneração é confidencial', 'Reajustes aparecem só para você e o RH, sem comunicado.');
    p('</ul>');

    if g_proprio and c_pagina_solicitacao is not null then
      select count(*) into l_qt_abertas
        from solicitacao_correcao
       where id_colaborador = p_id_colaborador and st_solicitacao = 'ABERTA';
      p('<hr><div class="hc-sobre__correcao"><strong>Algo incorreto?</strong>'
        || '<span>Peça uma revisão ao RH. A correção também fica registrada no histórico.</span></div>');
      if l_qt_abertas > 0 then
        p('<p class="hc-sobre__status">' || e(plural(l_qt_abertas, 'solicitação em análise pelo RH',
                                                       'solicitações em análise pelo RH')) || '</p>');
      end if;
      p('<a class="hc-btn hc-btn--bloco" href="'
        || a(url(c_pagina_solicitacao, c_item_solicitacao, p_id_colaborador)) || '">'
        || ico('alerta') || '<span>Solicitar correção</span></a>');
    elsif g_rh and not g_proprio then
      select count(*) into l_qt_abertas
        from solicitacao_correcao
       where id_colaborador = p_id_colaborador and st_solicitacao = 'ABERTA';
      if l_qt_abertas > 0 then
        p('<hr><p class="hc-sobre__status">' || e(plural(l_qt_abertas, 'solicitação de correção aberta',
                                                           'solicitações de correção abertas')) || '</p>');
        link_seta(url(c_pagina_painel_rh), 'Ver no painel do RH');
      end if;
    end if;
    p('</div></section></aside>');

    p('</div></div>');
    return g_html;
  end render;

end pkg_historico_carreira_ui;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PKG_ORGANOGRAMA" as

  c_ponto constant varchar2(10) := unistr(' \00B7 ');   -- " · " (texto que será escapado)

  -- Ícones Lucide (stroke), herdam a cor do texto via currentColor
  c_svg constant varchar2(200) :=
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" '
    || 'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">';

  c_ico_rede    constant varchar2(1000) := c_svg
    || '<rect x="16" y="16" width="6" height="6" rx="1"/><rect x="2" y="16" width="6" height="6" rx="1"/>'
    || '<rect x="9" y="2" width="6" height="6" rx="1"/><path d="M5 16v-3a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v3"/>'
    || '<path d="M12 12V8"/></svg>';
  c_ico_chevron constant varchar2(400)  := c_svg || '<path d="m9 18 6-6-6-6"/></svg>';
  c_ico_perfil  constant varchar2(600)  := c_svg
    || '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="10" r="3"/>'
    || '<path d="M7 20.662V19a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v1.662"/></svg>';
  c_ico_chat    constant varchar2(400)  := c_svg || '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/></svg>';
  c_ico_seta    constant varchar2(400)  := c_svg || '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>';
  c_ico_x       constant varchar2(400)  := c_svg || '<path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>';
  c_ico_mail    constant varchar2(600)  := c_svg
    || '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>';
  c_ico_copiar  constant varchar2(600)  := c_svg
    || '<rect width="14" height="14" x="8" y="8" rx="2" ry="2"/>'
    || '<path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></svg>';
  c_ico_ok      constant varchar2(400)  := c_svg || '<path d="M20 6 9 17l-5-5"/></svg>';
  c_ico_cadeado constant varchar2(600)  := c_svg
    || '<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>';

  c_nls_data constant varchar2(60) := 'NLS_DATE_LANGUAGE=''BRAZILIAN PORTUGUESE''';

  g_html clob;

  ------------------------------------------------------------------------------
  -- Utilitários
  ------------------------------------------------------------------------------
  procedure inicia is
  begin
    dbms_lob.createtemporary(g_html, true, dbms_lob.call);
  end inicia;

  procedure p (p_txt in varchar2) is
  begin
    if p_txt is not null then
      dbms_lob.writeappend(g_html, length(p_txt), p_txt);
    end if;
  end p;

  function e (p_txt in varchar2) return varchar2 is
  begin
    return apex_escape.html(p_txt);
  end e;

  function a (p_txt in varchar2) return varchar2 is
  begin
    return apex_escape.html_attribute(p_txt);
  end a;

  function iniciais (p_nome in varchar2) return varchar2 is
    l_nome varchar2(400) := trim(regexp_replace(p_nome, '\s+', ' '));
  begin
    if l_nome is null then
      return '?';
    elsif instr(l_nome, ' ') = 0 then
      return upper(substr(l_nome, 1, 2));
    end if;
    -- primeira letra do primeiro nome + primeira letra do último sobrenome
    return upper(substr(l_nome, 1, 1) || substr(l_nome, instr(l_nome, ' ', -1) + 1, 1));
  end iniciais;

  function plural (p_qtd in number, p_singular in varchar2, p_plural in varchar2) return varchar2 is
  begin
    return p_qtd || ' ' || case when p_qtd = 1 then p_singular else p_plural end;
  end plural;

  function url (p_pagina in pls_integer, p_item in varchar2, p_id in number) return varchar2 is
  begin
    return a(apex_page.get_url(p_page => p_pagina, p_items => p_item, p_values => to_char(p_id)));
  end url;

  function eh_usuario_atual (p_login in varchar2) return boolean is
  begin
    return upper(p_login) = upper(v('APP_USER'));
  end eh_usuario_atual;

  function mes_por_extenso (p_data in date) return varchar2 is
  begin
    return to_char(p_data, 'fmmonth', c_nls_data);
  end mes_por_extenso;

  -- "fevereiro de 2026 · 7 meses"
  function tempo_de_casa (p_data in date) return varchar2 is
    l_meses   pls_integer;
    l_anos    pls_integer;
    l_resto   pls_integer;
    l_duracao varchar2(200);
  begin
    if p_data is null then
      return null;
    elsif trunc(p_data) > trunc(current_date) then
      return 'admiss&atilde;o em ' || to_char(p_data, 'fmdd') || ' de ' || mes_por_extenso(p_data)
             || ' de ' || to_char(p_data, 'yyyy');
    end if;

    l_meses := floor(months_between(trunc(current_date), trunc(p_data)));
    l_anos  := trunc(l_meses / 12);
    l_resto := mod(l_meses, 12);

    l_duracao := case
                   when l_meses < 1 then 'menos de 1 m&ecirc;s'
                   when l_anos  = 0 then plural(l_resto, 'm&ecirc;s', 'meses')
                   when l_resto = 0 then plural(l_anos,  'ano', 'anos')
                   else plural(l_anos, 'ano', 'anos') || ' e ' || plural(l_resto, 'm&ecirc;s', 'meses')
                 end;

    return mes_por_extenso(p_data) || ' de ' || to_char(p_data, 'yyyy') || ' &middot; ' || l_duracao;
  end tempo_de_casa;

  -- Só dia e mês: o ano de nascimento não é exibido
  function aniversario (p_data in date) return varchar2 is
  begin
    if p_data is null then
      return null;
    end if;
    return to_char(p_data, 'fmdd') || ' de ' || mes_por_extenso(p_data);
  end aniversario;

  -- Foto (FOTO_URL ou BLOB) quando existir; senão, iniciais
  function avatar (
  p_id         in number,
  p_nome       in varchar2,
  p_foto_url   in varchar2,
  p_tem_imagem in varchar2,
  p_tamanho    in varchar2
) return varchar2 is
  l_src varchar2(4000);
begin

  if p_foto_url is not null then
    l_src := '#APP_FILES#Fotos Colaboradores/' || p_foto_url;

  elsif p_tem_imagem = 'S' then
    l_src := apex_page.get_url(
               p_request => 'APPLICATION_PROCESS=DOWNLOAD_FOTO',
               p_items   => 'ID_COLABORADOR',
               p_values  => to_char(p_id));
  end if;

  if l_src is not null then
    return '<span class="org-avatar org-avatar--' || p_tamanho || '">'
        || '' || a(l_src) || '</span>';
  end if;

  return '<span class="org-avatar org-avatar--' || p_tamanho || '" aria-hidden="true">'
      || e(iniciais(p_nome)) || '</span>';

end avatar;

  -- Linha clicável das listas do drawer (gestor / equipe direta)
  function linha_pessoa (
    p_id         in number,
    p_nome       in varchar2,
    p_subtitulo  in varchar2,
    p_foto_url   in varchar2,
    p_tem_imagem in varchar2
  ) return varchar2 is
  begin
    return '<li><button type="button" class="org-linha" data-acao="detalhe" data-id="' || p_id || '">'
        || avatar(p_id, p_nome, p_foto_url, p_tem_imagem, 'row')
        || '<span class="org-linha__texto">'
        || '<span class="org-linha__nome">' || e(p_nome) || '</span>'
        || '<span class="org-linha__sub">' || e(p_subtitulo) || '</span>'
        || '</span>' || c_ico_chevron || '</button></li>';
  end linha_pessoa;

  function dado (p_rotulo in varchar2, p_valor_html in varchar2) return varchar2 is
  begin
    return '<div><dt>' || p_rotulo || '</dt><dd>' || nvl(p_valor_html, '&mdash;') || '</dd></div>';
  end dado;

  ------------------------------------------------------------------------------
  -- Topo da hierarquia
  ------------------------------------------------------------------------------
  function id_raiz return number is
    l_id number;
  begin
    select min(id_colaborador)
      into l_id
      from vw_org_colaborador
     where id_gestor is null;
    return l_id;
  end id_raiz;

  ------------------------------------------------------------------------------
  -- ORGANOGRAMA · caminho: Empresa > ... > Pessoa em foco
  ------------------------------------------------------------------------------
  procedure render_caminho (p_id_foco in number, p_nome_empresa in varchar2) is
    l_primeiro boolean := true;
  begin
    p('<nav class="org-caminho" aria-label="Caminho na hierarquia">' || c_ico_rede || '<ol>');

    for r in (select id_colaborador, nome_completo, level as nivel
                from vw_org_colaborador
               start with id_colaborador = p_id_foco
             connect by nocycle prior id_gestor = id_colaborador
               order by level desc)
    loop
      if l_primeiro then
        -- o nome da empresa leva ao topo da cadeia
        p('<li><button type="button" class="org-link" data-acao="foco" data-id="' || r.id_colaborador || '">'
          || e(p_nome_empresa) || '</button></li>');
        l_primeiro := false;
      end if;

      p('<li><span class="org-caminho__sep">' || c_ico_chevron || '</span>');
      if r.nivel = 1 then
        p('<span aria-current="page">' || e(r.nome_completo) || '</span>');
      else
        p('<button type="button" class="org-link" data-acao="foco" data-id="' || r.id_colaborador || '">'
          || e(r.nome_completo) || '</button>');
      end if;
      p('</li>');
    end loop;

    p('</ol></nav>');
  end render_caminho;

  ------------------------------------------------------------------------------
  -- ORGANOGRAMA · card da pessoa em foco
  ------------------------------------------------------------------------------
  procedure render_foco (p_foco in vw_org_colaborador%rowtype, p_diretos in pls_integer) is
    l_estrutura pls_integer;
  begin
    -- todos os descendentes ativos (exclui a própria pessoa)
    select count(*) - 1
      into l_estrutura
      from vw_org_colaborador
     start with id_colaborador = p_foco.id_colaborador
   connect by nocycle prior id_colaborador = id_gestor;

    p('<section class="org-foco" aria-labelledby="org-foco-nome">');
    p('<div class="org-foco__id">');
    p(avatar(p_foco.id_colaborador, p_foco.nome_completo, p_foco.foto_url, p_foco.tem_imagem, 'lg'));
    p('<div class="org-foco__texto">'
      || '<h2 id="org-foco-nome" class="org-foco__nome" tabindex="-1">' || e(p_foco.nome_completo) || '</h2>'
      || '<p class="org-foco__cargo">' || e(p_foco.cargo) || ' &middot; ' || e(p_foco.departamento) || '</p>'
      || '</div>');
    if p_foco.id_gestor is null then
      p('<span class="org-tag">Topo da hierarquia</span>');
    end if;
    p('</div>');

    p('<p class="org-foco__resumo">'
      || plural(p_diretos,   'subordinado direto',  'subordinados diretos') || ' &middot; '
      || plural(l_estrutura, 'pessoa na estrutura', 'pessoas na estrutura') || '</p>');

    p('<div class="org-foco__acoes">');
    -- "Ver perfil" abre o drawer; o perfil completo fica no rodapé dele
    p('<button type="button" class="org-btn" data-acao="detalhe" data-id="' || p_foco.id_colaborador || '">'
      || c_ico_perfil || '<span>Ver perfil</span></button>');
    if not eh_usuario_atual(p_foco.login_apex) then
      p('<a class="org-btn" href="' || url(c_pagina_chat, c_item_chat, p_foco.id_colaborador) || '">'
        || c_ico_chat || '<span>Conversar</span></a>');
    end if;
    p('</div></section>');
  end render_foco;

  ------------------------------------------------------------------------------
  -- ORGANOGRAMA · subordinados diretos (cards com prévia da equipe)
  ------------------------------------------------------------------------------
  procedure render_filhos (p_foco in vw_org_colaborador%rowtype, p_diretos in pls_integer) is
    type t_textos is table of varchar2(4000) index by pls_integer;
    l_nomes    t_textos;
    l_avatares varchar2(32767);
    l_resumo   varchar2(4000);
  begin
    if p_diretos = 0 then
      p('<p class="org-vazio">' || e(p_foco.nome_completo) || ' n&atilde;o tem subordinados diretos.</p>');
      return;
    end if;

    p('<div class="org-conectores org-conectores--' || case when p_diretos = 1 then 'um' else 'varios' end
      || '" aria-hidden="true"></div>');
    p('<ul class="org-filhos' || case when p_diretos = 1 then ' org-filhos--um' end || '">');

    for f in (select v.id_colaborador, v.nome_completo, v.cargo, v.departamento, v.foto_url, v.tem_imagem,
                     (select count(*) from vw_org_colaborador s where s.id_gestor = v.id_colaborador) as qtd_equipe
                from vw_org_colaborador v
               where v.id_gestor = p_foco.id_colaborador
               order by v.nome_completo)
    loop
      p('<li class="org-card">');
      -- o botão do nome se estende sobre o card inteiro (clique abre o drawer)
      p('<div class="org-card__id">'
        || avatar(f.id_colaborador, f.nome_completo, f.foto_url, f.tem_imagem, 'md')
        || '<div class="org-card__texto">'
        || '<button type="button" class="org-card__nome" data-acao="detalhe" data-id="' || f.id_colaborador || '"'
        || ' aria-label="Ver detalhes de ' || e(f.nome_completo) || '">'
        || e(f.nome_completo) || '</button>'
        || '<p class="org-card__cargo">' || e(f.cargo) || ' &middot; ' || e(f.departamento) || '</p>'
        || '</div></div>');

      p('<div class="org-card__equipe">');
      if f.qtd_equipe = 0 then
        p('<p class="org-card__sem">Sem equipe direta</p>');
      else
        l_nomes.delete;
        l_avatares := null;

        for s in (select id_colaborador, nome_completo, foto_url, tem_imagem
                    from vw_org_colaborador
                   where id_gestor = f.id_colaborador
                   order by nome_completo
                   fetch first 3 rows only)
        loop
          l_nomes(l_nomes.count + 1) := e(s.nome_completo);
          l_avatares := l_avatares
                        || avatar(s.id_colaborador, s.nome_completo, s.foto_url, s.tem_imagem, 'sm');
        end loop;

        if f.qtd_equipe > 3 then
          l_avatares := l_avatares
                        || '<span class="org-avatar org-avatar--sm org-avatar--mais" aria-hidden="true">+'
                        || (f.qtd_equipe - 3) || '</span>';
        end if;

        l_resumo := case
                      when f.qtd_equipe = 1 then l_nomes(1)
                      when f.qtd_equipe = 2 then l_nomes(1) || ' e ' || l_nomes(2)
                      when f.qtd_equipe = 3 then l_nomes(1) || ', ' || l_nomes(2) || ' e ' || l_nomes(3)
                      else l_nomes(1) || ', ' || l_nomes(2) || ', ' || l_nomes(3)
                           || ' e mais ' || (f.qtd_equipe - 3)
                    end;

        p('<div class="org-avatares">' || l_avatares || '</div>'
          || '<div class="org-card__equipe-texto">'
          || '<span class="org-card__rotulo">Equipe &middot; ' || plural(f.qtd_equipe, 'pessoa', 'pessoas') || '</span>'
          || '<span class="org-card__nomes" title="' || l_resumo || '">' || l_resumo || '</span>'
          || '</div>'
          || '<button type="button" class="org-ver-equipe" data-acao="foco" data-id="' || f.id_colaborador || '"'
          || ' aria-label="Ver equipe de ' || e(f.nome_completo) || '">'
          || '<span>Ver equipe</span>' || c_ico_seta || '</button>');
      end if;
      p('</div></li>');
    end loop;

    p('</ul>');
  end render_filhos;

  ------------------------------------------------------------------------------
  -- ORGANOGRAMA · entrada principal
  ------------------------------------------------------------------------------
  function render (
    p_id_foco      in number,
    p_nome_empresa in varchar2 default c_nome_empresa
  ) return clob is
    l_foco    vw_org_colaborador%rowtype;
    l_id      number;
    l_diretos pls_integer;
  begin
    inicia;

    -- foco inválido, inativo ou nulo => topo da hierarquia
    begin
      select * into l_foco from vw_org_colaborador where id_colaborador = p_id_foco;
    exception
      when no_data_found then
        l_id := id_raiz;
        begin
          select * into l_foco from vw_org_colaborador where id_colaborador = l_id;
        exception
          when no_data_found then
            p('<div class="org"><p class="org-vazio">Nenhum colaborador ativo encontrado.</p></div>');
            return g_html;
        end;
    end;

    select count(*)
      into l_diretos
      from vw_org_colaborador
     where id_gestor = l_foco.id_colaborador;

    p('<div class="org">');
    render_caminho(l_foco.id_colaborador, p_nome_empresa);
    p('<div class="org-arvore">');
    render_foco(l_foco, l_diretos);
    render_filhos(l_foco, l_diretos);
    p('</div>');
    p('<p class="org-ajuda">Clique em um card para ver os detalhes da pessoa ou em &ldquo;Ver equipe&rdquo; '
      || 'para descer um n&iacute;vel. Use o caminho acima para voltar. Contas inativas n&atilde;o aparecem.</p>');
    p('</div>');

    return g_html;
  end render;

  ------------------------------------------------------------------------------
  -- DRAWER · detalhes da pessoa
  ------------------------------------------------------------------------------
  function render_detalhes (
    p_id           in number,
    p_nome_empresa in varchar2 default c_nome_empresa
  ) return clob is
    l_p      vw_org_colaborador%rowtype;
    l_gestor vw_org_colaborador%rowtype;
    l_equipe pls_integer;
  begin
    inicia;

    begin
      select * into l_p from vw_org_colaborador where id_colaborador = p_id;
    exception
      when no_data_found then
        p('<div class="org-drawer__estado">'
          || '<p>Esta pessoa n&atilde;o est&aacute; mais dispon&iacute;vel no organograma.</p>'
          || '<button type="button" class="org-btn org-btn--auto" data-acao="fechar">Fechar</button></div>');
        return g_html;
    end;

    -- Cabeçalho -------------------------------------------------------------
    p('<header class="org-drawer__cab">'
      || avatar(l_p.id_colaborador, l_p.nome_completo, l_p.foto_url, l_p.tem_imagem, 'lg')
      || '<div class="org-drawer__ident">'
      || '<h2 id="org-drawer-nome" class="org-drawer__nome" tabindex="-1">' || e(l_p.nome_completo) || '</h2>'
      || '<p class="org-drawer__cargo">' || e(l_p.cargo) || ' &middot; ' || e(l_p.departamento) || '</p>'
      || '</div>'
      || '<button type="button" class="org-icone-btn" data-acao="fechar" aria-label="Fechar detalhes">'
      || c_ico_x || '</button>'
      || '</header>');

    p('<div class="org-drawer__corpo">');

    -- Contato ---------------------------------------------------------------
    if l_p.email is not null then
      p('<section class="org-secao" aria-labelledby="org-sec-contato">'
        || '<h3 id="org-sec-contato" class="org-secao__titulo">Contato</h3>'
        || '<div class="org-contato">' || c_ico_mail
        || '<div class="org-campo"><span class="org-campo__rotulo">E-mail corporativo</span>'
        || '<a class="org-campo__valor" href="mailto:' || a(l_p.email) || '">' || e(l_p.email) || '</a></div>'
        || '<button type="button" class="org-icone-btn org-copiar" data-acao="copiar" data-valor="'
        || a(l_p.email) || '" aria-label="Copiar e-mail">'
        || '<span class="org-ico-copiar">' || c_ico_copiar || '</span>'
        || '<span class="org-ico-ok">' || c_ico_ok || '</span></button>'
        || '<span class="org-sr" aria-live="polite"></span>'
        || '</div></section>');
    end if;

    -- Na estrutura ----------------------------------------------------------
    p('<section class="org-secao" aria-labelledby="org-sec-estrutura">'
      || '<h3 id="org-sec-estrutura" class="org-secao__titulo">Na estrutura</h3>');

    p('<div class="org-grupo"><span class="org-campo__rotulo">Reporta-se a</span>');
    if l_p.id_gestor is null then
      p('<p class="org-grupo__vazio">Topo da hierarquia</p>');
    else
      begin
        select * into l_gestor from vw_org_colaborador where id_colaborador = l_p.id_gestor;
        p('<ul class="org-lista">'
          || linha_pessoa(l_gestor.id_colaborador, l_gestor.nome_completo,
                          l_gestor.cargo || c_ponto || l_gestor.departamento,
                          l_gestor.foto_url, l_gestor.tem_imagem)
          || '</ul>');
      exception
        when no_data_found then
          p('<p class="org-grupo__vazio">Gestor inativo ou n&atilde;o encontrado</p>');
      end;
    end if;
    p('</div>');

    select count(*)
      into l_equipe
      from vw_org_colaborador
     where id_gestor = l_p.id_colaborador;

    p('<div class="org-grupo"><span class="org-campo__rotulo">Equipe direta &middot; '
      || plural(l_equipe, 'pessoa', 'pessoas') || '</span>');
    if l_equipe = 0 then
      p('<p class="org-grupo__vazio">Sem equipe direta</p>');
    else
      p('<ul class="org-lista">');
      for s in (select id_colaborador, nome_completo, cargo, foto_url, tem_imagem
                  from vw_org_colaborador
                 where id_gestor = l_p.id_colaborador
                 order by nome_completo
                 fetch first c_max_equipe rows only)
      loop
        p(linha_pessoa(s.id_colaborador, s.nome_completo, s.cargo, s.foto_url, s.tem_imagem));
      end loop;
      p('</ul>');

      if l_equipe > c_max_equipe then
        p('<p class="org-grupo__mais">e mais ' || (l_equipe - c_max_equipe) || ' na equipe</p>');
      end if;

      p('<button type="button" class="org-ver-equipe" data-acao="equipe" data-id="' || l_p.id_colaborador || '">'
        || '<span>Ver equipe no organograma</span>' || c_ico_seta || '</button>');
    end if;
    p('</div></section>');

    -- Sobre -----------------------------------------------------------------
    p('<section class="org-secao" aria-labelledby="org-sec-sobre">'
      || '<h3 id="org-sec-sobre" class="org-secao__titulo">Sobre</h3>'
      || '<dl class="org-dados">'
      || dado('Departamento', e(l_p.departamento))
      || dado('Empresa', e(p_nome_empresa))
      || dado('Na ' || e(p_nome_empresa) || ' desde', tempo_de_casa(l_p.data_admissao))
      || dado('Anivers&aacute;rio', aniversario(l_p.data_de_nascimento))
      || '</dl></section>');

    p('<p class="org-privacidade">' || c_ico_cadeado
      || '<span>Voc&ecirc; v&ecirc; s&oacute; os dados vis&iacute;veis para todos os colegas. Os demais ficam '
      || 'com a pessoa, a linha de gest&atilde;o e a administra&ccedil;&atilde;o.</span></p>');

    p('</div>');   -- corpo

    -- Rodapé ----------------------------------------------------------------
    p('<footer class="org-drawer__rodape">');
    if not eh_usuario_atual(l_p.login_apex) then
      p('<a class="org-btn org-btn--auto" href="' || url(c_pagina_chat, c_item_chat, l_p.id_colaborador) || '">'
        || c_ico_chat || '<span>Conversar</span></a>');
    end if;
    p('<a class="org-btn org-btn--auto org-btn--primario" href="'
      || url(c_pagina_perfil, c_item_perfil, l_p.id_colaborador) || '">Ver perfil completo</a>');
    p('</footer>');

    return g_html;
  end render_detalhes;

end pkg_organograma;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PKG_PERFIS_ACESSO" as

  function papeis_do_cargo (p_id_cargo in number) return apex_t_varchar2 is
    l_papeis apex_t_varchar2 := apex_t_varchar2(c_papel_padrao);
  begin
    for r in (
      select cd_papel
        from cargo_papel
       where id_cargo = p_id_cargo
         and cd_papel <> c_papel_padrao
       order by cd_papel
    ) loop
      apex_string.push(l_papeis, r.cd_papel);
    end loop;
    return l_papeis;
  end papeis_do_cargo;


  procedure atribuir_papeis (
    p_login          in varchar2,
    p_id_cargo       in number,
    p_application_id in number default to_number(v('APP_ID'))
  ) is
    l_login  varchar2(255) := upper(trim(p_login));
    l_papeis apex_t_varchar2 := papeis_do_cargo(p_id_cargo);
    l_existe pls_integer;
  begin
    if l_login is null then
      raise_application_error(-20101, 'Informe o login do usuário para atribuir os papéis.');
    end if;

    for i in 1 .. l_papeis.count loop
      select count(*)
        into l_existe
        from apex_appl_acl_roles
       where application_id = p_application_id
         and role_static_id = l_papeis(i);

      if l_existe = 0 then
        raise_application_error(-20102,
          'O papel "' || l_papeis(i) || '" não existe na aplicação ' || p_application_id
          || '. Crie-o em Application Access Control ou corrija CARGO_PAPEL.');
      end if;

      if not apex_acl.has_user_role(
               p_role_static_id => l_papeis(i),
               p_application_id => p_application_id,
               p_user_name      => l_login) then
        apex_acl.add_user_role(
          p_application_id => p_application_id,
          p_user_name      => l_login,
          p_role_static_id => l_papeis(i));
      end if;
    end loop;
  end atribuir_papeis;

end pkg_perfis_acesso;
/

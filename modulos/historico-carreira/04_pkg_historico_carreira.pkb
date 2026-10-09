--------------------------------------------------------------------------------
-- Corlix Hub · Histórico de Carreira
-- 04 · Package PKG_HISTORICO_CARREIRA (corpo)
--------------------------------------------------------------------------------
create or replace package body pkg_historico_carreira as

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

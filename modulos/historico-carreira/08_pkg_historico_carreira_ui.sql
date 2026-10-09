--------------------------------------------------------------------------------
-- Corlix Hub · Histórico de Carreira
-- 08 · Package PKG_HISTORICO_CARREIRA_UI
--
-- Renderiza a página "Histórico de carreira" (página 13) no layout do protótipo:
--   título + Exportar PDF
--   resumo (tempo de casa, no cargo atual, promoções) + cargos ao longo do tempo
--   linha do tempo com abas (Tudo / Movimentações / Desenvolvimento) e filtro de ano;
--   cada movimentação mostra quem registrou (RH) e, se houver, quem aprovou
--   lateral: posição atual e "Sobre este histórico"
--
-- Mesmo padrão do PKG_ORGANOGRAMA: região Dynamic Content que retorna o HTML.
-- Nunca exibe salário. Reajustes por mérito só aparecem para o próprio
-- colaborador e para o RH.
--------------------------------------------------------------------------------

create or replace package pkg_historico_carreira_ui authid definer as

  -- Destinos dos links (ajuste para o app). Página nula = o link não aparece.
  c_pagina_organograma constant pls_integer  := null;  -- organograma ainda não instalado; volte para 3 depois
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

create or replace package body pkg_historico_carreira_ui as

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

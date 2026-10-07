--------------------------------------------------------------------------------
-- Corlix Hub · Organograma (navegação por níveis + drawer de detalhes)
-- View + package que renderiza:
--   render          -> caminho na hierarquia, pessoa em foco e subordinados
--   render_detalhes -> conteúdo do drawer "Detalhes da pessoa"
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. View: somente colaboradores ativos, já com cargo e departamento
--------------------------------------------------------------------------------
create or replace view vw_org_colaborador as
select c.id_colaborador,
       c.id_gestor,
       c.nome_completo,
       c.email,
       c.login_apex,
       c.data_admissao,
       c.data_de_nascimento,
       cg.nome as cargo,
       d.nome  as departamento,
       c.foto_url,
       case when c.imagem_perfil is not null then 'S' else 'N' end as tem_imagem
  from colaborador  c
  join cargo        cg on cg.id_cargo       = c.id_cargo
  join departamento d  on d.id_departamento = c.id_departamento
 where c.status = true;   -- STATUS nulo ou FALSE = conta inativa (não aparece)


--------------------------------------------------------------------------------
-- 2. Package
--------------------------------------------------------------------------------
create or replace package pkg_organograma as

  -- Um app por cliente: ajuste o nome da empresa neste schema
  c_nome_empresa  constant varchar2(100) := 'Corlix';

  -- Destinos de "Ver perfil completo" e "Conversar" (ajuste para o seu app)
  c_pagina_perfil constant pls_integer  := 20;
  c_item_perfil   constant varchar2(30) := 'P20_ID_COLABORADOR';
  c_pagina_chat   constant pls_integer  := 30;
  c_item_chat     constant varchar2(30) := 'P30_ID_COLABORADOR';

  -- Quantas pessoas da equipe direta listar no drawer
  c_max_equipe    constant pls_integer  := 8;

  -- Primeiro colaborador ativo sem gestor (topo da hierarquia)
  function id_raiz return number;

  -- Região do organograma. p_id_foco nulo/inválido => topo da hierarquia
  function render (
    p_id_foco      in number,
    p_nome_empresa in varchar2 default c_nome_empresa
  ) return clob;

  -- Conteúdo do drawer de detalhes (cabeçalho, corpo e rodapé)
  function render_detalhes (
    p_id           in number,
    p_nome_empresa in varchar2 default c_nome_empresa
  ) return clob;

end pkg_organograma;
/

create or replace package body pkg_organograma as

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
    p_tamanho    in varchar2   -- lg | md | row | sm
  ) return varchar2 is
    l_src varchar2(4000);
  begin
    if p_foto_url is not null then
      l_src := p_foto_url;
    elsif p_tem_imagem = 'S' then
      l_src := apex_page.get_url(
                 p_request => 'APPLICATION_PROCESS=DOWNLOAD_FOTO',
                 p_items   => 'ID_COLABORADOR',
                 p_values  => to_char(p_id));
    end if;

    if l_src is not null then
      return '<span class="org-avatar org-avatar--' || p_tamanho || '">'
          || '<img src="' || a(l_src) || '" alt="" loading="lazy"></span>';
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

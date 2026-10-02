--------------------------------------------------------------------------------
-- Corlix Hub · Organograma (navegação por níveis)
-- View + package que renderiza: caminho na hierarquia, pessoa em foco e
-- subordinados diretos (com prévia da equipe de cada um).
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. View: somente colaboradores ativos, já com cargo e departamento
--------------------------------------------------------------------------------
create or replace view vw_org_colaborador as
select c.id_colaborador,
       c.id_gestor,
       c.nome_completo,
       c.login_apex,
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

  -- Destinos dos botões "Ver perfil" e "Conversar" (ajuste para o seu app)
  c_pagina_perfil constant pls_integer  := 20;
  c_item_perfil   constant varchar2(30) := 'P20_ID_COLABORADOR';
  c_pagina_chat   constant pls_integer  := 30;
  c_item_chat     constant varchar2(30) := 'P30_ID_COLABORADOR';

  -- Primeiro colaborador ativo sem gestor (topo da hierarquia)
  function id_raiz return number;

  -- HTML completo da região. p_id_foco nulo/inválido => topo da hierarquia
  function render (
    p_id_foco      in number,
    p_nome_empresa in varchar2 default 'Corlix'
  ) return clob;

end pkg_organograma;
/

create or replace package body pkg_organograma as

  type t_textos is table of varchar2(4000) index by pls_integer;

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

  g_html clob;

  ------------------------------------------------------------------------------
  -- Utilitários
  ------------------------------------------------------------------------------
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
    return apex_escape.html_attribute(
             apex_page.get_url(p_page => p_pagina, p_items => p_item, p_values => to_char(p_id)));
  end url;

  -- Foto (FOTO_URL ou BLOB) quando existir; senão, iniciais
  function avatar (
    p_id         in number,
    p_nome       in varchar2,
    p_foto_url   in varchar2,
    p_tem_imagem in varchar2,
    p_tamanho    in varchar2   -- lg | md | sm
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
          || '<img src="' || apex_escape.html_attribute(l_src) || '" alt="" loading="lazy"></span>';
    end if;

    return '<span class="org-avatar org-avatar--' || p_tamanho || '" aria-hidden="true">'
        || e(iniciais(p_nome)) || '</span>';
  end avatar;

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
  -- Caminho: Empresa > ... > Pessoa em foco
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
        p('<li><button type="button" class="org-link js-org-foco" data-id="' || r.id_colaborador || '">'
          || e(p_nome_empresa) || '</button></li>');
        l_primeiro := false;
      end if;

      p('<li><span class="org-caminho__sep">' || c_ico_chevron || '</span>');
      if r.nivel = 1 then
        p('<span aria-current="page">' || e(r.nome_completo) || '</span>');
      else
        p('<button type="button" class="org-link js-org-foco" data-id="' || r.id_colaborador || '">'
          || e(r.nome_completo) || '</button>');
      end if;
      p('</li>');
    end loop;

    p('</ol></nav>');
  end render_caminho;

  ------------------------------------------------------------------------------
  -- Card da pessoa em foco
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
    p('<a class="org-btn" href="' || url(c_pagina_perfil, c_item_perfil, p_foco.id_colaborador) || '">'
      || c_ico_perfil || '<span>Ver perfil</span></a>');
    -- não oferece "Conversar" consigo mesmo
    if nvl(upper(p_foco.login_apex), '#') <> upper(v('APP_USER')) then
      p('<a class="org-btn" href="' || url(c_pagina_chat, c_item_chat, p_foco.id_colaborador) || '">'
        || c_ico_chat || '<span>Conversar</span></a>');
    end if;
    p('</div></section>');
  end render_foco;

  ------------------------------------------------------------------------------
  -- Subordinados diretos (cards com prévia da equipe)
  ------------------------------------------------------------------------------
  procedure render_filhos (p_foco in vw_org_colaborador%rowtype, p_diretos in pls_integer) is
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

    for f in (select v.*,
                     (select count(*) from vw_org_colaborador s where s.id_gestor = v.id_colaborador) as qtd_equipe
                from vw_org_colaborador v
               where v.id_gestor = p_foco.id_colaborador
               order by v.nome_completo)
    loop
      p('<li class="org-card">');
      p('<div class="org-card__id">'
        || avatar(f.id_colaborador, f.nome_completo, f.foto_url, f.tem_imagem, 'md')
        || '<div class="org-card__texto">'
        || '<button type="button" class="org-card__nome js-org-foco" data-id="' || f.id_colaborador || '">'
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
          || '<button type="button" class="org-ver-equipe js-org-foco" data-id="' || f.id_colaborador || '"'
          || ' aria-label="Ver equipe de ' || e(f.nome_completo) || '">'
          || '<span>Ver equipe</span>' || c_ico_seta || '</button>');
      end if;
      p('</div></li>');
    end loop;

    p('</ul>');
  end render_filhos;

  ------------------------------------------------------------------------------
  -- Entrada principal
  ------------------------------------------------------------------------------
  function render (
    p_id_foco      in number,
    p_nome_empresa in varchar2 default 'Corlix'
  ) return clob is
    l_foco    vw_org_colaborador%rowtype;
    l_id      number;
    l_diretos pls_integer;
  begin
    dbms_lob.createtemporary(g_html, true, dbms_lob.call);

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
    p('<p class="org-ajuda">Selecione &ldquo;Ver equipe&rdquo; para descer um n&iacute;vel ou use o caminho '
      || 'acima para voltar. Contas inativas n&atilde;o aparecem.</p>');
    p('</div>');

    return g_html;
  end render;

end pkg_organograma;
/

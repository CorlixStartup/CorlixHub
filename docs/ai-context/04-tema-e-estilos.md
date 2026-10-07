# 04 · Tema e estilos (sistema visual do Corlix Hub)

> Contexto para IAs. Fontes lidas: `modulos/tema/README.md`, `modulos/tema/Etapas-tema-paginas.md`,
> `corlixhub/shared-components/static-files/{corlix-tema,custom}.css` (+ `.min.css`),
> `corlixhub/shared-components/themes/universal-theme/theme.apx`,
> `.../page-templates/corlix-standard-page.apx`, `corlixhub/application.apx`,
> `figma/Design System · Redwood Light (CorlixHub).png` e o grep das páginas `corlixhub/pages/*.apx`.
> Estado descrito: working tree do branch `DEV` em 2026-10-06 (com mudanças **não commitadas**: ver §11).

---

## 1. Visão geral

- O app usa o **Universal Theme 42** (`baseTheme: ut-26.1`) com o estilo **Redwood Light** como *Current*
  (`theme.apx` → `currentThemeStyle: @/redwood-light`). Não existe tema próprio nem estilo de Theme Roller salvo.
- O "Tema Corlix" é **só uma camada CSS** por cima do Redwood Light: redefine variáveis do UT
  (`--ut-*`, `--a-*`, `--u-color-*`) a partir de tokens próprios `--cx-*`, mais alguns ajustes de componente.
  Regra da prancha do Figma: *"use componentes nativos, Template Options e Theme Roller correspondentes;
  CSS próprio só onde o nativo não chega"*.
- Fonte: **Oracle Sans** (a do Redwood, via `--a-base-font-family`). O Figma usa Figtree só como substituta — **não** importe Figtree.
- **Dark mode: não existe.** Nenhum arquivo tem `prefers-color-scheme` nem variante escura; a prancha só tem versão clara (README: "fora do escopo").

---

## 2. Como o CSS é carregado

### 2.1 Onde está configurado

| O quê | Onde (APEXlang) | Valor |
|---|---|---|
| CSS do app (Application CSS) | `corlixhub/application.apx` → `css { fileUrls: [...] }` (UI Attributes > CSS > File URLs) | `#APP_FILES#corlix-tema#MIN#.css` **e depois** `#APP_FILES#custom#MIN#.css` |
| CSS do tema | `theme.apx` → `css.fileUrls` | `#THEME_FILES#css/Core#MIN#.css?v=#APEX_VERSION#` (nativo) |
| Arquivos estáticos | `corlixhub/shared-components/static-files/` + manifesto `shared-components/static-files.apx` (`file corlix-tema.css (mimeType: text/css ...)`) | `corlix-tema.css`, `corlix-tema.min.css`, `custom.css`, `custom.min.css`, `default-user.jpeg`, `icons/`, `Fotos Colaboradores/` |
| CSS inline de página | `page { css { inline: ... } }` em cada `pXXXXX-*.apx` | ex.: Chat (p4) define `:root { --ch-* }` |
| Theme static files | `themes/universal-theme/static-files/1024*.css` | só cabeçalho de copyright da Oracle (68 bytes); irrelevantes |

### 2.2 Ordem no `<head>` (page template `corlix-standard-page`)

O template padrão do app (`componentDefaults.page: @corlix-standard-page`) emite, nesta ordem:

```
#APEX_CSS#  →  #THEME_CSS# (Core.css)  →  #TEMPLATE_CSS#  →  #THEME_STYLE_CSS# (Redwood Light)
→  #APPLICATION_CSS# (corlix-tema → custom)  →  #PAGE_CSS# (CSS inline da página)
```

Consequências:
1. `corlix-tema` vem **depois** do Redwood Light → suas variáveis em `:root` vencem as do estilo por ordem de cascata.
2. `custom` vem **depois** de `corlix-tema` → enxerga os tokens `--cx-*`. Se a ordem for invertida, o `custom` ainda funciona em runtime (variáveis CSS são resolvidas no uso), mas a convenção documentada exige esta ordem; regras de mesmo seletor/especificidade passariam a perder para o tema.
3. CSS inline de página vem por último → pode sobrescrever tudo (e o Chat usa isso para mapear `--ch-*` → `--cx-*`).
4. `#GENERATED_CSS#` fica no footer (após o body).

Outros pontos do template: `<body class="t-PageBody t-PageBody--hideLeft t-PageBody--hideActions no-anim t-PageTemplate--standard ...">`;
slots `AFTER_LOGO` (busca do cabeçalho), `AFTER_NAVIGATION_BAR` (ícones + usuário), `REGION_POSITION_01` = **Breadcrumb Bar**
dentro de `.t-Body-title`, `REGION_POSITION_04` = diálogos/drawers, `REGION_POSITION_05` = footer (oculto por CSS), `REGION_POSITION_07` = banner, `REGION_POSITION_08` = full width. JS on load: `apex.theme42.initializePage.noSideCol();`.

### 2.3 `#MIN#`

APEX substitui `#MIN#` por `.min` quando a sessão **não** está em debug, e por string vazia em debug.
Logo: usuário normal recebe `corlix-tema.min.css`/`custom.min.css`; com `?p_debug=YES` (ou debug ligado no builder) recebe os `.css` fonte.
**Se o `.min` estiver desatualizado, o app fica diferente entre debug e não-debug.**

### 2.4 Sincronia dos `.min` (verificado)

Comparação feita removendo comentários e espaços: **ambos os pares estão em sincronia**.

| Par | Seletores fonte / min | Custom properties | Declarações (sem espaços) |
|---|---|---|---|
| `corlix-tema.css` ↔ `.min.css` | 20 / 20, mesma ordem | idênticas | idênticas |
| `custom.css` ↔ `.min.css` | 123 / 123 (única diferença: `@media (max-width: 768px)` vs `(max-width:768px)`) | idênticas | idênticas |

Observações: não há script de minificação no repo (sem `package.json`, nada em `scripts/`). O `corlix-tema.min.css` mantém o espaçamento de alinhamento do `:root` (minificador "fraco", só tira comentários/quebras) — inofensivo. `custom.min.css` é uma linha só (`wc -l` = 0).

---

## 3. Design tokens `--cx-*` (fonte da verdade — `corlix-tema.css`, `:root`)

Os tokens apontam para a paleta do Redwood (`--rw-palette-*`) com fallback hex. Se uma atualização do APEX renomear a variável `--rw-*`, vale o fallback.

### 3.1 Cores

| Token | Definição | Valor efetivo | Uso |
|---|---|---|---|
| `--cx-primaria` | `var(--rw-palette-sky-120, #00688C)` | `#00688C` azul-petróleo | links, foco, abas, item atual do menu, botão terciário, ícones de links rápidos |
| `--cx-primaria-hover` | `var(--rw-palette-sky-130, #025E7E)` | `#025E7E` | hover de link/terciário |
| `--cx-primaria-suave` | `var(--rw-palette-sky-30, #E4F1F7)` | `#E4F1F7` | avatar de iniciais, badge info, ícone de componente |
| `--cx-primaria-texto` | `#1D5F84` | `#1D5F84` | texto sobre fundo suave (avisos, pílulas, badge info) |
| `--cx-fundo` | `var(--rw-palette-neutral-30, #F1EFED)` | `#F1EFED` | fundo das páginas |
| `--cx-superficie` | `var(--rw-palette-neutral-0, #FFFFFF)` | `#FFFFFF` | regiões, cards, cabeçalho, menu lateral |
| `--cx-superficie-2` | `var(--rw-palette-neutral-10, #FBF9F8)` | `#FBF9F8` | rodapés de drawer, superfície do chat |
| `--cx-tag` | `var(--rw-palette-neutral-20, #F5F4F2)` | `#F5F4F2` | etiquetas, busca do cabeçalho, links rápidos, bolha recebida do chat |
| `--cx-borda` | `var(--rw-palette-neutral-40, #E4E1DD)` | `#E4E1DD` | bordas/divisórias |
| `--cx-borda-campo` | `#8A857F` | `#8A857F` | borda forte de campo (usado em `historico-carreira.css`) |
| `--cx-selecionado` | `#EDEBE8` | `#EDEBE8` | item selecionado/atual do menu lateral |
| `--cx-texto` | `var(--rw-palette-neutral-190, #161513)` | `#161513` | texto principal/títulos |
| `--cx-texto-2` | `#57534F` | `#57534F` | texto secundário, labels |
| `--cx-texto-3` | `#6B6661` | `#6B6661` | metadados, placeholders |
| `--cx-btn` | `#EAE7E3` | `#EAE7E3` | botão secundário |
| `--cx-btn-hover` | `#DEDAD5` | `#DEDAD5` | hover do secundário |
| `--cx-escuro` | `var(--rw-palette-neutral-170, #312D2A)` | `#312D2A` | botão primário (Hot) |
| `--cx-sucesso` | `#2F7D4F` | `#2F7D4F` | sucesso (organograma) |
| `--cx-alerta` | `#B3261E` | `#B3261E` | erro/alerta (histórico de carreira) |

Cores fixas fora de token (não viraram `--cx-*`): `#D2CDC7` (active do botão), `rgba(22,21,19,.04)` (hover do menu), `rgba(22,21,19,.06)` (hover dos ícones do header), `--rw-palette-sky-10 #F6FAFC` (primary-shade), cores dos badges (§5.1).

### 3.2 Fonte, raios, espaçamentos, sombras

| Token / var | Valor | Uso |
|---|---|---|
| `--cx-fonte` | `var(--a-base-font-family)` (Oracle Sans) | referência; o CSS usa `font-family: inherit` |
| `--cx-raio` | `.375rem` (6px) | busca do header, menus, chips, componentes UT, botão "Sair" |
| `--cx-raio-card` | `.5rem` (8px) | regiões e cards |
| Espaçamentos | não há tokens `--cx-*` de espaço; ficam nas vars do UT (§4): conteúdo 32px (2rem), região 20×16px, breadcrumb 32×24px, nav 240px, header 56px |
| Sombras | política "**sem sombra**": `--ut-region-box-shadow`, `--ut-body-title-box-shadow`, `--a-cv-shadow`, `--ut-cardlist-box-shadow` = `none`. Exceção legada: `.a-CardView-item` em `custom.css` ainda tem `box-shadow: 0 3px 12px rgba(0,0,0,.08)` e `border-radius: 14px` |

Tipografia efetiva (da prancha + CSS): título de página 26px/32px bold; título de região 15px/20px bold, sem caixa alta; nome do app no header 18px bold; menu 14px/20px (itens de 40px); botões peso 600; badge/etiqueta 12px peso 600.

---

## 4. Mapeamento para variáveis do Universal Theme

Todas em `:root` de `corlix-tema.css`. Nomes extraídos do CSS do UT 26.1.5; se renomeados numa atualização, perde-se só aquele ajuste.

| Grupo | Variável UT | Valor Corlix |
|---|---|---|
| Tipografia | `--ut-breadcrumb-title-font-size` / `-line-height` | `1.625rem` / `2rem` |
| Primária | `--ut-palette-primary` | `var(--cx-primaria)` |
| | `--ut-palette-primary-contrast` | `#FFFFFF` |
| | `--ut-palette-primary-shade` | `var(--rw-palette-sky-10, #F6FAFC)` |
| | `--ut-link-text-color` | `var(--cx-primaria)` |
| | `--ut-component-icon-background-color` / `--ut-component-icon-color` | `--cx-primaria-suave` / `--cx-primaria` |
| | `--u-color-5` / `--u-color-5-contrast` | `--cx-primaria` / `#FFFFFF` |
| Foco | `--ut-focus-outline` | `2px solid var(--cx-primaria)` (Redwood: tracejado 1px) |
| | `--ut-focus-outline-color` / `-offset` | `--cx-primaria` / `2px` |
| Página | `--ut-body-background-color` / `--ut-body-text-color` | `--cx-fundo` / `--cx-texto` |
| | `--ut-body-content-padding-x` / `-y` | `2rem` / `2rem` |
| Header | `--ut-header-background-color` / `-text-color` / `-border-color` | `--cx-superficie` / `--cx-texto` / `--cx-borda` |
| | `--ut-header-height` / `--ut-header-padding-x` | `3.5rem` / `.5rem` |
| Menu lateral | `--ut-nav-width` | `15rem` (240px) |
| | `--ut-body-nav-background-color` / `-border-color` / `-text-color` | `--cx-superficie` / `--cx-borda` / `--cx-texto` |
| | `--a-treeview-node-font-size` / `-line-height` / `-padding-y` | `.875rem` / `1.25rem` / `.625rem` |
| | `--a-treeview-node-text-color` | `--cx-texto` |
| | `--a-treeview-node-hover-background-color` | `rgba(22,21,19,.04)` |
| | `--a-treeview-node-selected-background-color` / `-selected-text-color` | `--cx-selecionado` / `--cx-texto` |
| | `--ut-treeview-node-current-text-color` | `--cx-texto` |
| Título da página | `--ut-body-title-background-color` / `-border-color` / `-border-width` / `-box-shadow` | `--cx-superficie` / `--cx-borda` / `1px` / `none` |
| Componentes | `--ut-component-background-color` / `-border-color` / `-border-radius` | `--cx-superficie` / `--cx-borda` / `--cx-raio` |
| | `--ut-component-text-title-color` / `-text-muted-color` | `--cx-texto` / `--cx-texto-2` |
| Regiões | `--ut-region-border-color` / `-border-radius` / `-box-shadow` | `--cx-borda` / `--cx-raio-card` / `none` |
| | `--ut-region-header-border-color` | `--cx-borda` |
| | `--ut-region-header-font-size` / `-line-height` | `.9375rem` / `1.25rem` |
| | `--ut-region-header-padding-x/-y`, `--ut-region-body-padding-x/-y` | `1.25rem` / `1rem` |
| Cards | `--a-cv-shadow` / `--a-cv-border-radius` / `--ut-cardlist-box-shadow` | `none` / `--cx-raio-card` / `none` |
| Botões | `--a-button-background-color` / `-hover-` / `-active-` | `--cx-btn` / `--cx-btn-hover` / `#D2CDC7` |
| | `--a-button-text-color` / `--a-button-font-weight` | `--cx-texto` / `600` |
| Campos | `--a-field-input-focus-border-color` | `--cx-primaria` |
| | `--ut-field-label-text-color` / `--ut-field-fl-label-text-color` | `--cx-texto-2` |
| Abas | `--ut-tabs-item-active-highlight-color` / `--ut-navtabs-item-active-highlight-color` | `--cx-primaria` |
| Badge UT | `--ut-badge-border-radius` / `-font-size` / `-font-weight` / `-padding-x` | `999px` / `.75rem` / `600` / `.5rem` |
| Menus/chips | `--a-menu-border-radius` / `--a-chip-border-radius` | `--cx-raio` |

O botão **Hot** não é redefinido: o escuro `#312D2A` já é o do Redwood.

### 4.1 Ajustes de componente em `corlix-tema.css` (o que variável não alcança)

| Seletor | Efeito |
|---|---|
| `.t-Header-logo-link, .t-Header-logo-label` | nome do app 18px, 700, `--cx-texto` |
| `.t-TreeNav .a-TreeView-node.is-current > .a-TreeView-row`, `.is-current--top > .a-TreeView-row`, `.a-TreeView-row.is-selected` | fundo `--cx-selecionado` + `box-shadow: inset 3px 0 0 var(--cx-primaria)` (barra azul de 3px) |
| `.t-TreeNav .is-current, .is-current--top` | `--a-treeview-node-font-weight: 700` |
| `.t-TreeNav .a-TreeView-node .a-Icon/.fa` | ícones do menu em `--cx-texto-2` |
| `.t-Body-title` / `::after` | borda 1px; remove faixa de textura do Redwood (`content: none`) |
| `.t-Body-title .t-BreadcrumbRegion` (+ `.t-PageBody--showLeft`) | `--ut-breadcrumb-padding-x: 2rem; -y: 1.5rem` |
| `.t-BreadcrumbRegion-titleText` | bold |
| `.t-Region-title` | 700, `text-transform: none` |
| `.t-Button--link`, `.t-Button--noUI` (exceto `--noLabel`, `--header`, `--closeAlert`) | texto primário/hover primário → botão terciário azul; ícone-só e header ficam neutros |
| `.a-CardView-initials, .t-Avatar--initials` | fundo `--cx-primaria-suave`, texto `--cx-primaria` |
| `.cx-badge*`, `.cx-etiqueta` | ver §5.1 |

---

## 5. Catálogo de classes customizadas

Prefixos e onde vivem:

| Prefixo | Arquivo | Escopo / página |
|---|---|---|
| `cx-` | `corlix-tema.css` (badge/etiqueta) e `custom.css` §11 (layout) | design system, reutilizável. Usado em p1, p4 (só tokens), p14, p16 |
| `corlix-header__` | `custom.css` §2 | p0 Global Page (cabeçalho) |
| `card-*`, `link-item`, `links-rapidos-card`, `cmt-*`, `figma-*`, `popup-todos-aniversariantes`, `lista-de-comunicados`, `emitir-comunicado`, `imagem-capa-comunicado`, `titulo-lista-de-comunicados`, `botao-emitir-comunicado` | `custom.css` §3–§10 | p1 Home (legado da Home; `emitir-comunicado` também aparece em p17) |
| `log-*` (`log-detalhe`, `log-descricao`, `log-tag`) | `custom.css` (após §8) | p7 Monitor de logs. Atenção: `log-size600x400`, `log-autoheight`, `log-cancel`, `log-closed` encontrados por grep são falsos positivos (substrings de `dialog-*`) |
| `ch-*` | CSS **inline** da página 4 | p4 Chat (tokens `--ch-*` + classes `ch-shell`, `ch-list`, `ch-contact`, `ch-bubble`, `ch-msg--in/--out`, `ch-dot--online/ausente/offline`...) |
| `org-*` / `.org`, `.org-drawer` | `modulos/organograma/organograma.css` | p3 Organograma (tokens locais `--org-*` → `--cx-*` com fallback) |
| `hc-*` / `.hc` | `modulos/historico-carreira/historico-carreira.css` | p13 Histórico de carreira (tokens `--hc-*` → `--cx-*`) |

`organograma.css` e `historico-carreira.css` **ainda não estão** em `corlixhub/shared-components/static-files/` nem referenciados no app exportado: precisam ser subidos (ver `Etapas-*.md` de cada módulo).

### 5.1 Componentes do design system (`corlix-tema.css`)

**`.cx-badge` + variante** — pílula de status, sempre com texto (ponto colorido via `::before` em `currentColor`). Pílula 999px, 12px/16px, 600, padding `.125rem .5rem`.

| Variante | Fundo | Texto |
|---|---|---|
| (base) | `--cx-tag` | `--cx-texto-2` |
| `--sucesso` | `--rw-palette-green-30 #E4F5D3` | `--rw-palette-green-140 #355617` |
| `--neutro` | `--rw-palette-neutral-30 #F1EFED` | `--cx-texto-2` |
| `--erro` | `--rw-palette-red-30 #FFEBE8` | `--rw-palette-red-140 #8F2719` |
| `--aviso` | `--rw-palette-orange-30 #FCEDDC` | `--rw-palette-orange-140 #724108` |
| `--info` | `--cx-primaria-suave` | `--cx-primaria-texto` |

**`.cx-etiqueta`** — etiqueta neutra de departamento (cor não pode sugerir status): raio 4px, fundo `--cx-tag`, borda interna 1px `--cx-borda`, 12px/600, `--cx-texto-2`.

```html
<span class="cx-badge cx-badge--sucesso">Ativa</span>
<span class="cx-etiqueta">Operações</span>
```
Uso: p1 Home (`cx-badge--info` no mês dos aniversariantes; `cx-etiqueta` no departamento dos comunicados).

### 5.2 Layout do design system (`custom.css` §11)

| Classe | O que faz | Página |
|---|---|---|
| `.cx-cabecalho-card` (+ `h3`) | flex título + badge, `padding: 16px 16px 12px` | p1 região `card_aniversariantes` |
| `.figma-badge-mes` | `text-transform: capitalize`; **hook do JS** que preenche o mês | p1 |
| `.cx-acoes-card` (+ `.t-Button { flex:1 }`) | botões secundários lado a lado, padding 0 16px | p1 `card_meu_gestor` (footer) |
| `.cx-pessoa`, `__foto` (52px redonda), `__nome` (14px), `__detalhe` (12px `--cx-texto-3`) | foto + nome + cargo | p1 `card_meu_gestor` (HTML Expression) |
| `.cx-titulo` (26px/32px bold) / `.cx-descricao` (14px `--cx-texto-2`) | título + descrição de página montados em região | p14 região `cadastrar-colaborador-header` |
| `.cx-titulo-secao` (16px bold, margin-bottom 12px) | título de seção em formulário | p16 `headerText` das 3 regiões |

```html
<div class="cx-cabecalho-card">
  <h3>Aniversariantes</h3>
  <span class="figma-badge-mes cx-badge cx-badge--info"></span>
</div>

<div class="cx-pessoa">
  <img src="&FOTO_GESTOR." alt="" class="cx-pessoa__foto"
       onerror="this.onerror=null; this.src='#APP_FILES#default-user.jpeg';">
  <div>
    <strong class="cx-pessoa__nome">&NOME_GESTOR.</strong>
    <span class="cx-pessoa__detalhe">&NOME_CARGO.</span>
  </div>
</div>

<div class="cx-acoes-card">
  <a class="t-Button t-Button--icon t-Button--iconLeft" href="#">
    <span class="t-Icon t-Icon--left fa fa-comment-o" aria-hidden="true"></span>
    <span class="t-Button-label">Chat</span>
  </a>
</div>
```

### 5.3 Cabeçalho (`custom.css` §2, p0 Global Page)

`.corlix-header__search` (360px, max 40vw, margin-left 24px; some < 768px) › `__search-icon` (absoluto, centralizado, `--cx-texto-3`) + `__search-input` (36px, padding-left 36px, fundo `--cx-tag`, raio `--cx-raio`; foco: fundo branco + outline 2px primária) — região no slot *After Logo*.
`.corlix-header__actions` (flex, gap 8) › `__icon-btn` (36×36, transparente, hover `rgba(22,21,19,.06)`) e `__user` (borda esquerda) › `__user-info` (`__user-name` 14px/600, `__user-role` 12px) + `__avatar` (32px redondo) — slot *After Navigation Bar*. `.t-Header-navBar--end` vira flex.

### 5.4 Ajustes globais / Home legados (`custom.css` §1, §3–§10)

| Seletor | Efeito / nota |
|---|---|
| `.t-NavigationBar-item.has-username .t-Button-label` | sem caixa alta no nome do usuário |
| `.t-Footer { display:none !important }` | rodapé do APEX escondido em todas as páginas |
| `.t-Region--noUI { margin-bottom:0 !important }` | |
| `#t_TreeNav>ul[role="group"]>li:last-child ...` | transforma o **último item do menu lateral** ("Sair") em botão de rodapé (fundo `--cx-btn`). **Apagar quando "Sair" for para o menu do usuário** |
| `.t-Cards { gap:24px }` | global |
| `.card-default` (+ `h1/h2/h3`) | card branco com borda 1px e raio 8px (Home, 5 usos) |
| `.a-CardView-item` / `-media img` / `-body` / `-title` / `-subTitle` / `-desc` | **globais** (afetam todo Cards nativo do app): raio 14px, sombra, hover `translateY(-3px)`, imagem 260px, título 1.5rem |
| `.card-boas-vindas`, `.link-empresa` | card de boas-vindas |
| `.card-comunicados-oficiais`, `.lista-de-comunicados`, `.cmt-meta/.cmt-date/.cmt-title`, `.imagem-capa-comunicado`, `.emitir-comunicado`, `.botao-emitir-comunicado`, `.titulo-lista-de-comunicados` (lowercase!) | lista de comunicados da Home |
| `.card-meu-gestor` | remove sombra/hover do CardView (com `!important`) |
| `.links-rapidos-card`, `.link-item` (`.icon` primária, `.text`, `.arrow`) | links rápidos; SVGs usam `currentColor` |
| `.card-aniversariantes`, `.figma-row(.is-normal-day/.is-birthday-today)`, `.figma-avatar-wrapper/-img` (54px), `.figma-info-wrapper`, `.figma-name-text`, `.figma-date-text`, `.figma-cake-icon`, `.figma-footer-link` | aniversariantes; uso pesado de `!important`; aniversariante do dia = borda 3px primária e data azul. `.figma-footer-link` é a CSS class do botão `B_VER_TODOS` (posição absoluta no rodapé do card) |
| `.popup-todos-aniversariantes ...` | mesmo visual dentro do diálogo; esconde rodapé/"Ver todos" duplicados |
| `.ui-dialog .ui-dialog-titlebar(:before)` | **global**: remove textura do topo de **todos** os diálogos, fundo branco + borda |
| `.log-detalhe`, `.log-descricao`, `.log-tag` | p7; ainda usam `--ut-*` com fallbacks antigos (`#056ac8`, `rgba(5,106,200,.1)`) — não migrados para `--cx-*` |
| `.figma-footer-link:focus:not(:focus-visible)` ... | esconde outline só no clique (teclado continua com foco visível) |

---

## 6. Diferenças `corlix-tema.css` × `custom.css`

| | `corlix-tema.css` | `custom.css` |
|---|---|---|
| Papel | tema global: tokens `--cx-*` + redefinição de variáveis UT + poucos ajustes de componente nativo + `cx-badge`/`cx-etiqueta` | ajustes de páginas/regiões específicas (header, Home, logs) + classes de layout `cx-*` |
| Ordem | 1º | 2º (depende dos tokens) |
| Tamanho | 273 linhas, 20 regras | 985 linhas, 123 regras |
| Estilo | só variáveis; zero `!important` | muito `!important`, seletores profundos (legado da Home) |
| Novo? | arquivo novo (não commitado) | existente, refatorado para tokens |
| Comentário de cabeçalho | cita `#APP_FILES#corlix-tema.css` (sem `#MIN#`) — desatualizado; o real é `corlix-tema#MIN#.css` | §2 ainda diz "Cole em corlix-header.css" — desatualizado; o header está dentro do `custom.css` |

---

## 7. Regras de uso do design system no APEX (prancha + README)

| Na prancha | No APEX |
|---|---|
| Botão primário (escuro) | **Hot = Yes**; **uma única** ação primária por tela/contexto |
| Secundário (cinza) | template *Text* (padrão: `componentDefaults.button: @/text`) |
| Terciário ("Ver todos →") | *Text with Icon*, `fa-arrow-right`, *Icon Position: Right*, *Style: Remove UI Decoration* |
| Somente ícone | template *Icon* (fica neutro) |
| Excluir | *Template Options > Type: Danger*, sem Hot |
| Campos | label **Optional - Floating** / **Required - Floating** (defaults do tema); orientação em *Inline Help Text*; erro *Inline with Field* |
| Badge de status | Template Component Badge ou `cx-badge cx-badge--*`; sempre com texto |
| Etiqueta de departamento | `cx-etiqueta` |
| Feedback | *Success Message* do processo; avisos persistentes em região template **Alert** |
| Estados de região (carregando/vazio/erro) | Lazy Loading, *When No Data Found* personalizado, botões condicionados aos dados |
| Regiões | template **Standard**, título em frase normal ("Meu gestor", não "MEU GESTOR") |
| Navegação | Navigation Menu nativo; grupo Administração com Authorization Scheme na entrada |

Prancha (Figma) — conteúdo: Botões (Primária, Secundária, Terciária, Somente ícone, Hover, Foco teclado com anel azul, Desabilitado, Carregando "Salvando..."); Campos (Vazio, Preenchido, Foco com borda/label azul, Erro em vermelho com mensagem abaixo, Desabilitado, Switch, Checkbox); Status e etiquetas (Ativa verde, Inativa cinza, Erro vermelho, Aviso laranja, Informação azul; etiquetas Operações/Diretoria/Vendas); Feedback (alertas sucesso verde, aviso bege, erro rosa, info azul, com título + próxima ação e botão fechar); Navegação lateral (Padrão, Hover com fundo cinza, Ativo = fundo + barra azul + negrito, Grupo + subitem); Estados de região; Estrutura da aplicação (header com ☰ CorlixHub, busca "Buscar na intranet...", sino, avatar "SS Sarah Silva ▾"; menu do usuário com Meu perfil / Preferências / Sair; menu: Início, Comunicados, Chat, Pessoas › Colaboradores, Organograma, Minha equipe, Minhas aprovações [contador]; Minha carreira › Meu perfil, Avaliações, Resultados 360, Plano de desenvolvimento, Feedbacks; Administração › Empresas, Central de equipes, Monitor de logs, Configurações).

Ícones do Navigation Menu propostos: Início `fa-home`, Comunicados `fa-bullhorn`, Chat `fa-comments-o`, Pessoas `fa-users`, Organograma `fa-sitemap`, Minha carreira `fa-briefcase`, Histórico de carreira `fa-history`, Administração `fa-shield`.

---

## 8. Processo: aplicar o tema em uma página (`Etapas-tema-paginas.md`)

O tema vale para o app inteiro assim que o CSS carrega — não há "ligar por página". O trabalho por página é **remover o que foge** do design system. Recarregar com Ctrl/Cmd+Shift+R após cada página.

**Etapa 0 (uma vez):** (1) ordem dos File URLs `corlix-tema#MIN#` → `custom#MIN#`; (2) *Themes > Universal Theme > Styles*: Redwood Light *Current*; (3) Theme Roller sem estilo personalizado salvo; (4) teste: fundo `#F1EFED`, header branco, barra azul no menu, links azuis. Se nada mudou, o problema é o passo 1.

**Checklist por página:**
1. Botões: uma Hot; demais *Text*; "Ver todos" com Remove UI Decoration; Excluir = Danger sem Hot.
2. Campos obrigatórios → Required - Floating; demais Optional - Floating.
3. Regiões *Standard*, título em frase normal, sem `<span style=...>` em Title/Header Text.
4. Remover todo `style="..."` de cor/fonte/tamanho/fundo; usar `var(--cx-*)` ou `cx-badge`/`cx-etiqueta`.
5. SVG inline: `stroke/fill="currentColor"`.
6. Mensagens: Success Message / Inline with Field.
7. **Título com descrição (passo 1.1):** apagar a região *Title Bar* (breadcrumb); criar *Static Content* no slot **Breadcrumb Bar**, template **Hero** com ícone escondido, Title = nome da página, Source = descrição; botões da página no slot **Next** dessa região.
8. Cores hardcoded → tokens: `#3B66F5 #2563EB #056ac8 #4f46e5` → `--cx-primaria`; `#eef2ff` → `--cx-tag`; `#111827 #151515 #404040 #000` → `--cx-texto`; `#6B7280 #4b5563` → `--cx-texto-2`; `#E5E7EB #F3F4F6` → `--cx-borda`.

**Status por página (conforme o guia + estado atual do código):**

| Página | Ação | Estado no working tree |
|---|---|---|
| 0 Global | nada (classes `corlix-header__*`) | ok |
| 1 Home | 9 itens (aniversariantes, meu gestor, comunicados com `cx-etiqueta`, remover style do link, `B_VER_TODOS`, "Novo comunicado", SVG `currentColor`, CSS de apoio, cores) | **aplicado** (HTML com `cx-*`, `B_VER_TODOS` com text-with-icon + `figma-footer-link`, botão "Novo comunicado", `currentColor`; `.dept-*`/`.cmt-badge` já removidos do CSS). Resta: coluna `CLASSE_DEPTO` ainda na query (linha ~350), sem uso |
| 2, 5, 6, 8, 11, 12 | só barra de título; aplicar 1.1 se o protótipo tiver descrição | — |
| 3 Organograma | seguir `modulos/organograma/Etapas-organograma.md` + 1.1 (busca no slot Next) | CSS do módulo fora do app |
| 4 Chat | mapear `--ch-*` → `--cx-*` no `:root` inline; manter `--ch-online/ausente/offline` e medidas | **aplicado** |
| 7 Monitor de logs | nada | ok |
| 13 Histórico | seguir `modulos/historico-carreira/Etapas-historico-carreira.md` item 2 | CSS do módulo fora do app |
| 14 Cadastro de usuários | guia manda 1.1 + Required - Floating em `P14_NOME_COMPLETO/EMAIL/EMPRESA/DEPARTAMENTO/CARGO` | **divergente**: em vez de Hero, a região `cadastrar-colaborador-header` (body, Standard, removeHeader) usa `<h1 class="cx-titulo">` + `<p class="cx-descricao">` |
| 15 Empresas | nada | ok |
| 16 Cadastro de empresas | guia manda apagar Header Text; `delete` = Danger sem Hot | **divergente**: Header Text virou `<h2 class="cx-titulo-secao">` (sem style inline) |
| 17 Emitir comunicado | opcional renomear para "Novo comunicado" | — |
| 26 Central de equipes | nada | ok |
| 27 Nova equipe | `delete` = Danger sem Hot | modificado |
| 9999 Login | nada | ok |

Checklist final: nenhum `style=` de cor/fonte (buscar `style=` no export); uma Hot por tela; Excluir Danger; obrigatórios Required - Floating; etiquetas neutras; títulos sem caixa alta; Tab mostra contorno azul 2px.

---

## 9. Convenções para criar/alterar estilos

1. **Cor nova ou ajuste global** → token `--cx-*` ou variável UT no `:root` de `corlix-tema.css`. Nunca no Theme Roller (competiria com o arquivo). Nunca hex solto em `custom.css`/páginas.
2. **Componente reutilizável do design system** → classe `cx-*` (BEM: `cx-bloco__elemento`, `cx-bloco--variante`, nomes em português). Badges/etiquetas no `corlix-tema.css`; layout em `custom.css` §11.
3. **Ajuste específico de página/região** → `custom.css`, numa seção numerada nova (atualizar o índice no topo), escopado por uma classe de região (CSS Classes da região), usando tokens.
4. **Módulo grande** (organograma, histórico) → CSS próprio em `modulos/<modulo>/`, raiz escopada (`.org`, `.hc`), tokens locais com fallback: `--org-primaria: var(--cx-primaria, #00688C);`.
5. **CSS só de uma página e pequeno** → *Page > CSS > Inline* é aceitável (padrão do Chat), mas cores devem apontar para `--cx-*`.
6. **Minificação:** depois de editar `X.css`, **regenerar `X.min.css`** e subir os dois (o guia diz isso explicitamente). Não editar `.min` à mão — não há ferramenta no repo; qualquer minificador CSS serve (ex.: `npx clean-css-cli -o custom.min.css custom.css` ou `npx csso`). Conferir sincronia comparando seletores (§2.4).
7. Arquivo estático novo: além do arquivo em `static-files/`, adicionar entrada no manifesto `shared-components/static-files.apx` (`file nome.css ( mimeType: text/css charSet: utf-8 )`) e referenciar em `application.apx` → `css.fileUrls` com `#MIN#`.
8. Preferir variáveis UT a sobrescrever propriedades; evitar `!important` (o legado da Home usa, não replicar).
9. Acessibilidade: status nunca só por cor; foco visível (use `:focus:not(:focus-visible)` se precisar esconder o outline de clique).

---

## 10. Pegadinhas

- **`#MIN#` + `.min` desatualizado** = visual diferente em debug vs produção.
- **Cache**: após subir CSS, Ctrl/Cmd+Shift+R (recomendação do guia; o navegador pode manter a versão antiga do arquivo).
- **Seletor do item atual do menu** (`.t-TreeNav .a-TreeView-node.is-current > .a-TreeView-row`) é o ponto mais frágil; se a barra azul sumir após upgrade do APEX, inspecionar a classe real no DevTools.
- **Nomes de variáveis UT** vieram do UT 26.1.5; renomeação silenciosa só perde aquele ajuste.
- **`.a-CardView-*` e `.ui-dialog-titlebar` em `custom.css` são globais** — afetam qualquer região Cards e todo diálogo do app (raio 14px + sombra + hover que sobe 3px, contrariando a política "sem sombra" do tema).
- **Último item do menu lateral vira botão de rodapé** (`#t_TreeNav ... li:last-child`). Se adicionar uma entrada no fim do Navigation Menu, ela vira o "botão". Remover o bloco quando "Sair" for para o menu do usuário.
- **`.t-Footer` está escondido** globalmente; regiões no slot Footer não aparecem.
- **`.titulo-lista-de-comunicados` força `lowercase`.**
- **`.figma-badge-mes` é hook de JS** da Home — não remover ao trocar o visual.
- **Classes `log-*` em p15/p16/p17/p27** no grep são `dialog-*`, não do Monitor de logs.
- **CSS dos módulos** (`organograma.css`, `historico-carreira.css`) ainda não estão em `static-files/` nem no `fileUrls`.
- Comentários desatualizados: cabeçalho do `corlix-tema.css` (sem `#MIN#`) e §2 do `custom.css` ("corlix-header.css").
- Fallbacks de `--cx-primaria-suave` nos módulos usam `#E6F2F6`, diferente do `#E4F1F7` do tema (só importa se o tema não carregar).
- Não há dark mode; não criar regras `prefers-color-scheme` sem definir a paleta escura antes.

---

## 11. Mudanças não commitadas (git diff no momento da escrita)

- `application.apx`: `css.fileUrls` passou de só `custom#MIN#.css` para `[corlix-tema#MIN#.css, custom#MIN#.css]`.
- `static-files.apx`: entradas novas `corlix-tema.css` e `corlix-tema.min.css`; os dois arquivos são *untracked*.
- `custom.css` (+202/−145): cabeçalho renomeado para "AJUSTES DE PÁGINAS"; removidos `.t-Body-mainContent { background:#dddddd }`, `.t-Header-branding { background:#FFF !important }`, override `--ut-body-content-padding-y: 1.5rem`, fontes fixas ("Segoe UI", "Sora", `-apple-system`), `text-transform: uppercase` do `.card-default h3`, sombra do `.card-default`, `.cmt-badge` e `.dept-0..5/.dept-geral`; hex trocados por tokens `--cx-*`; busca do header 280→360px, input 32→36px, ícones sem fundo; botão "Sair" com `--cx-btn`/`--cx-raio`; `.figma-avatar-wrapper` novo; foco do "Ver todos" só escondido no clique; nova §11 com classes `cx-*`.
- Páginas modificadas: p1 Home, p4 Chat, p14, p16, p27 (aplicação do tema conforme §8).

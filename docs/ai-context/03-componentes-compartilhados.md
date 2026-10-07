# 03 — Componentes compartilhados (Shared Components) da app 100 CORLIXHUB

> Fonte: `corlixhub/application.apx`, `corlixhub/page-groups.apx`, `corlixhub/.apex/`, `corlixhub/deployments/`,
> `corlixhub/supporting-objects/`, `corlixhub/shared-components/**` e trechos de `database/f100.sql` (via grep).
> Estado conferido em 2026-10-06, branch `DEV`, **com mudanças não commitadas** (ver §13).
> APEXlang: `mmdVersion` `26.1.0+3102` (`corlixhub/.apex/apexlang.json`); export SQL diz `Version: 26.1.5`, `p_compatibility_mode=>'26.1'`.

---

## 1. Configuração da aplicação (`corlixhub/application.apx`)

| Item | Valor | Observação |
|---|---|---|
| Alias / nome | `CORLIXHUB` / `Corlix Hub` | Owner/schema `WKSP_CORLIXHUB` (f100.sql). |
| Logo | tipo `text`, texto `CorlixHub` | Renderizado em `#LOGO#` do page template. |
| Home | página `1` | URL: `f?p=&APP_ID.:1:&APP_SESSION.::&DEBUG.:::` |
| Login | página `LOGIN` (= 9999) | |
| Autenticação | `@oracle-apex-accounts` (tipo `oracleApexAccounts`) | Usuários são **contas do workspace APEX**; não há esquema custom nem post-authentication procedure. |
| Navigation menu | lista `@navigation-menu`, template `@/side-navigation-menu`, posição `side` | Template options: `#DEFAULT#`, `js-defaultCollapsed`, `js-navCollapsed--default`, `t-TreeNav--styleA` → menu lateral **começa recolhido** (só ícones). |
| Navigation bar | `implementation: classic` | Nenhuma lista explícita; o default do tema é `@/navigation-bar`. O cabeçalho real (busca, sino, engrenagem, avatar) vem da **Global Page 0** (ver §1.2). |
| Tema | `@universal-theme` (UT 42, `ut-26.1`, estilo `Redwood Light`) | `globalPage: 0`; `addBuiltWithApexToFooter: false`. |
| Máscaras de formato | `date: DS`, `timestamp: DS`, `timestampTimeZone: DS` | `DS` = formato curto da NLS da sessão. Como `p_flow_language=>'en'` (idioma primário **inglês**, derivado de `FLOW_PRIMARY_LANGUAGE`), datas podem sair no padrão americano se a NLS do banco não for pt-BR. Formate explicitamente (`to_char(..., 'dd/mm/yyyy')`) quando importar. |
| CSS globais | `#APP_FILES#corlix-tema#MIN#.css`, depois `#APP_FILES#custom#MIN#.css` | Ordem importa (tema → ajustes). **Mudança não commitada** (§13). |
| Segurança | `runtimeApiUsage: modifyWorkspaceRepository` (`p_runtime_api_usage=>'W'`) | Permite APIs de runtime alterarem o repositório do workspace (ex.: `apex_util.create_user` na tela de cadastro de usuários). |
| Session State Protection | habilitado (`p_page_protection_enabled_y_n=>'Y'`), `checksumSalt` fixo, `p_bookmark_checksum_function=>'SH512'` | Todas as páginas normais usam `pageAccessProtection: argumentsMustHaveChecksum` → **links com parâmetros precisam ser gerados por APEX** (`apex_page.get_url`, link builder, `f?p` com `:...` não funciona sem checksum). App items têm `p_protection_level=>'I'` (não podem ser setados pelo browser). |
| Error handler | `errorHandlingFunctionName: log_pkg.apex_error_handler` | Fonte em `database/corlix-hub.sql` (ver §11). |
| Runtime | `allowFeedback: true` | Feedback habilitado. |
| Substituição | `APP_NAME` = `CorlixHub` | Use `&APP_NAME.` em textos. Em `supporting-objects/substitutions.apx` aparece `substitution APP_NAME ( )` vazio (artefato do export; valor real está em application.apx). |
| Outros (f100.sql) | `p_flow_version=>'Release 1.0'`, `p_flow_status=>'AVAILABLE_W_EDIT_LINK'`, `p_browser_cache=>'N'`, `p_rejoin_existing_sessions=>'N'`, `p_exact_substitutions_only=>'Y'`, `p_file_storage=>'DB'`, `p_is_pwa=>'Y'` (não instalável, sem push), `p_page_view_logging=>'YES'`, `p_theme_style_by_user_pref=>false` | |

### 1.1 Deployment / página de grupos / supporting objects
- `corlixhub/deployments/default.json`: `{"app":{"id":100,"runtime":{"debugging":true}}}` → **debug habilitado** no deploy padrão (desligue em produção).
- `corlixhub/page-groups.apx`: um único grupo `administration` ("Administration"). Nenhuma página o referencia (grep em `pages/` sem `pageGroup`/`group:`).
- `corlixhub/supporting-objects/supporting-objects.apx`: só `includeInAppExport: true`. **Não há install/upgrade/deinstall scripts**: em `f100.sql`, `create_install` tem `p_deinstall_script_clob` vazio, `deployment/checks` e `deployment/buildoptions` são `null;`. Ou seja, **importar a app NÃO cria tabelas, packages nem dados**.

### 1.2 Cabeçalho global (Global Page 0 — referência cruzada)
A Page 0 (`pages/p00000-global-page.apx`) injeta duas regiões Static Content (template `@/standard` com `t-Region--removeHeader js-removeLandmark t-Region--noUI t-Region--scrollBody`):
- slot `afterLogo`: busca `<input id="P0_SEARCH_GLOBAL" class="corlix-header__search-input">` (HTML puro, não é item APEX).
- slot `afterNavigationBar`: links para notificações/configurações + `&G_NOME_USUARIO.`, `&APP_USER_CARGO.`, `<img src="&APP_USER_FOTO.">`.
  - Os links são **hardcoded**: `r/corlixhub/&APP_ALIAS./notificacoes?session=&SESSION.` e `.../configuracoes?...` (caminho do workspace `corlixhub` fixo; depende de friendly URLs e dos aliases `NOTIFICACOES` (p5) e `CONFIGURACOES` (p6)).
  - Esses slots existem tanto no `@/standard` quanto no `@corlix-standard-page`.

---

## 2. Roles ACL e Authorization Schemes

### 2.1 Roles (`acl-roles.apx`)
| Static ID | Nome (usado nas authorizations) |
|---|---|
| `diretoria` | `Diretoria` |
| `equipe-do-corlix-hub` | `Equipe do Corlix Hub` |
| `publicador-de-conteúdo` | `Publicador de Conteúdo` (static id com acento) |
| `colaborador` | `Colaborador` (todo usuário) |
| `gestor` | `Gestor` |
| `admin-rh` | `Admin RH` (exigido pelo módulo de carreira via authorization `ADMIN_RH`) |

Atribuição: na P14, o processo "Atribuir papéis do cargo" chama `pkg_perfis_acesso.atribuir_papeis`, que dá `colaborador` a todos e os papéis do cargo listados em `CARGO_PAPEL` (módulo `modulos/perfis-acesso/`, ver `06`). `equipe-do-corlix-hub` e ajustes pontuais continuam manuais em *Shared Components > Application Access Control*.

### 2.2 Authorizations (`authorizations.apx`) — todas `isInRoleOrGroup`, avaliadas `perSession`
| Static ID (referência `@...`) | Nome exibido | Role exigida | Mensagem de erro |
|---|---|---|---|
| `administration-rights` | `Equipe Corlix Hub` | `Equipe do Corlix Hub` | "Acesso restrito à equipe do Corlix Hub." |
| `publicador-de-conteudo` | `Publicador de Conteudo` | `Publicador de Conteúdo` | "Acesso restrito a publicadores de conteúdo." |
| `somente-diretoria` | `Somente Diretoria` | `Diretoria` | "Acesso restrito à Diretoria." |
| `admin-rh` | `ADMIN_RH` (nome exigido por `pkg_historico_carreira` / `fn_carreira_ve_salario`) | `Admin RH` | "Acesso restrito ao RH." |

`perSession` = resultado em cache na sessão: após mudar a role de alguém, o usuário precisa **novo login**.

### 2.3 Quem acessa o quê (uso real)
| Onde | Authorization |
|---|---|
| Menu "Cadastro de Usuários" (p14) | `@somente-diretoria` |
| Menu "Emitir Comunicado" (p17) | `@publicador-de-conteudo` |
| Menu "Empresas Cadastradas" (p15/16) | `@administration-rights` |
| Coluna `CAB_DEPT` do relatório de contatos do Chat (p4) | `@administration-rights` (cabeçalho de departamento só aparece para a equipe Corlix — provavelmente acidental) |

**Pegadinha de segurança:** nenhuma página tem `authorizationScheme` em nível de página. As authorizations só **escondem itens do menu**; qualquer usuário autenticado acessa p14, p15, p16, p17 e **p7 (Monitor de Logs, sem nenhuma authorization)** digitando a URL. Para proteger de verdade, colocar `security { authorizationScheme: @... }` no `page`.
O módulo `modulos/historico-carreira/` prevê também as authorizations `GESTOR` e `COLABORADOR` (PL/SQL) e o app item `G_ID_EMPRESA`, que **ainda não existem** nos shared components. `ADMIN_RH` já existe (e ainda não protege nenhuma página).

---

## 3. Application Items e Application Processes

### 3.1 Items (`app-items.apx`) — todos com proteção `I` (Restricted)
| Item | Populado por | Usado em |
|---|---|---|
| `APP_USER_CARGO` | processo `APP_USER_CARGO` | Page 0 (cabeçalho) |
| `APP_USER_FOTO` | processo `APP_USER_FOTO` | Page 0 (`<img src="&APP_USER_FOTO.">`) |
| `APP_USER_NOME` | **ninguém** | **ninguém** (item órfão) |
| `G_NOME_EMPRESA` | processo `G_NOME_EMPRESA` | Home p1 ("Sua jornada de carreira na &G_NOME_EMPRESA.") |
| `G_NOME_USUARIO` | processo `G_NOME_USUARIO` | Page 0 e Home p1 ("Bem-vindo, &G_NOME_USUARIO.!") |

### 3.2 Processes (`app-processes.apx`)
Todos: `type: executeCode`, `sequence: 1`, ponto **`BEFORE_HEADER` (On Load: Before Header)** segundo `f100.sql`, **sem condição** → as 4 queries rodam **em toda renderização de página**, inclusive na página de login (onde `:APP_USER = 'nobody'` → cai nos `EXCEPTION`). Candidatos naturais a `On New Instance`/pós-autenticação.

Vínculo usuário APEX ↔ colaborador: `UPPER(TRIM(COLABORADOR.login_apex)) = UPPER(TRIM(:APP_USER))`.

```plsql
-- APP_USER_CARGO
SELECT G.nome INTO :APP_USER_CARGO
  FROM COLABORADOR C JOIN CARGO G ON G.id_cargo = C.id_cargo
 WHERE UPPER(TRIM(C.login_apex)) = UPPER(TRIM(:APP_USER));
-- NO_DATA_FOUND → 'SEM VÍNCULO'; TOO_MANY_ROWS → 'MÚLTIPLOS VÍNCULOS'; OTHERS → 'ERRO AO CARREGAR CARGO'

-- APP_USER_FOTO
SELECT CASE WHEN C.foto_url IS NULL THEN '#APP_FILES#default-user.jpeg'
            ELSE '#APP_FILES#fotos/' || C.foto_url END
  INTO :APP_USER_FOTO
  FROM COLABORADOR C WHERE UPPER(TRIM(C.login_apex)) = UPPER(TRIM(:APP_USER));
-- qualquer exceção → '#APP_FILES#default-user.jpeg'

-- G_NOME_EMPRESA
SELECT E.nome INTO :G_NOME_EMPRESA
  FROM COLABORADOR C JOIN EMPRESA E ON E.id_empresa = C.id_empresa
 WHERE UPPER(TRIM(C.login_apex)) = UPPER(TRIM(:APP_USER));
-- NO_DATA_FOUND → 'SEM VINCULO - usuario: '||:APP_USER; TOO_MANY_ROWS → 'MULTIPLOS VINCULOS - usuario: '||:APP_USER; OTHERS → 'ERRO: '||SQLERRM

-- G_NOME_USUARIO (não usa COLABORADOR!)
select initcap(first_name || ' ' || last_name) into :G_NOME_USUARIO
  from apex_workspace_apex_users where upper(user_name) = upper(:APP_USER);
-- no_data_found → :APP_USER
```

Pegadinhas:
- **Caminho da foto quebrado:** `APP_USER_FOTO` monta `#APP_FILES#fotos/<foto_url>`, mas a pasta registrada é `Fotos Colaboradores/` (§9). Não existe pasta `fotos/`. A Home (p1) tem a mesma inconsistência: o card "Meu Gestor" usa `'#APP_FILES#fotos/' || G.FOTO_URL`, enquanto aniversariantes usam `'#APP_FILES#Fotos Colaboradores/' || FOTO_URL`. O avatar do cabeçalho não tem `onerror` de fallback (os da Home têm).
- `G_NOME_USUARIO` vem do cadastro de usuário do workspace (first/last name), não de `COLABORADOR.nome_completo` → nomes podem divergir.
- `G_NOME_EMPRESA` expõe `SQLERRM` na tela em caso de erro.
- Strings `#APP_FILES#` gravadas em item/coluna dependem da substituição feita pelo APEX ao renderizar o HTML (funciona em Static Content/HTML Expression como na Home); em PL/SQL puro o valor é literal.

---

## 4. Lists (`lists.apx`)

### 4.1 `navigation-menu` ("Navigation Menu") — menu lateral, em ordem de `sequence`
| Seq | Static ID | Label | Ícone | Destino | Current em páginas | Authorization |
|---|---|---|---|---|---|---|
| 10 | `home` | Home | `fa-home` | p1 | (padrão: p1) | — |
| 20 | `meu-perfil` | Meu Perfil | `fa-user` | p2 | 2 | — |
| 30 | `organograma` | Organograma | `fa-tree-org` | p3 | 3 | — |
| 40 | `comunicação` | Comunicados | `fa-commenting-o` | p11 | 11 | — |
| 50 | `colaboradores` | Colaboradores | `fa-users-alt` | p12 | 12 | — |
| 60 | `histórico-de-carreira` | Histórico de carreira | `fa-workflow` | p13 | 13 | — |
| 70 | `cadastros` | Cadastro de Usuários | `fa-user-plus` | p14 | 14 | `@somente-diretoria` |
| 80 | `emitir-comunicado` | Emitir Comunicado | `fa-magic` | p17 (modal wizard) | 17 | `@publicador-de-conteudo` — **filho de `@home`** (`parentEntry: @home`), aparece como subitem de Home |
| 110 | `empresas-cadastradas` | Empresas Cadastradas | `fa-building-o` | p15 | 15, 16 | `@administration-rights` |
| 160 | `central-de-equipes` | Central de Equipes | `fa-table` | p26 | 26, 27 | — |
| 170 | `chat` | Chat | `fa-comments-o` | p4 | 4 | — |
| 190 | `terminal` | Monitor de Logs | `fa-terminal` | p7 | 7 | **nenhuma** |
| 10000 | `sair` | Sair | `fa-box-arrow-out-east` | URL `&LOGOUT_URL.` | — | — |

Fora do menu: p5 (Notificações, acessada pelo sino do cabeçalho), p6 (Configurações, engrenagem), p8 (`NOTIFICAÇÕES`, página vazia/duplicada), p9999 (login). `custom.css` empurra o último item do menu para o rodapé (§9). Ícones são Font APEX (`icons.library: fontApex`), classes `fa-*`.

### 4.2 `emitir-comunicado` ("Emitir Comunicado") — lista de wizard
Entradas `Step 1` → p17, `Step 2` → p18, `Step 3` → p19. **Páginas 18 e 19 não existem** e a lista **não é referenciada por nenhuma página** (p17 usa `wizard-modal-dialog`, mas sem região Wizard Progress apontando para ela). Resto de geração automática. Atenção: o módulo histórico-de-carreira planeja usar os números 18–23 para outras páginas.

---

## 5. Breadcrumbs (`breadcrumbs.apx`)
Um único breadcrumb `breadcrumb` ("Breadcrumb"). **Hierarquia plana**: todas as entradas têm `sequence: 10` e **nenhuma `parentEntry`** (nem "Home" é pai) → cada página mostra só o próprio nome.

| Entry (static id) | Nome | Página / link |
|---|---|---|
| `home` | Home | 1 |
| `meu-perfil` | Meu Perfil | 2 |
| `organograma` | Organograma | 3 |
| `notificações` | Notificações | 5 |
| `configurações` | Configurações | 6 |
| `terminal` | Monitor de Logs | 7 |
| `comunicação` | Comunicação | 11 (no menu o label é "Comunicados") |
| `colaboradores` | Colaboradores | 12 |
| `histórico-de-carreira` | Histórico de carreira | 13 |
| `cadastros` | Cadastro de Usuários | 14 |
| `empresas-cadastradas` | Empresas Cadastradas | 15 |
| `central-de-equipes` | Central de Equipes | 26 |

Páginas com região Breadcrumb (`breadcrumb: @breadcrumb`, template de região `@/title-bar`): 2, 3, 5, 6, 7, 11, 12, 13, 15, 26. Sem breadcrumb: 1, 4, 8, 14 (tem entry mas não região), modais 16/17/27. Para adicionar hierarquia: `layout { parentEntry: @home }` na entry.

---

## 6. LOVs (`lovs.apx`)
| Static ID | Nome | Tipo | Retorno / Exibição | Usada em |
|---|---|---|---|---|
| `boolean` | `BOOLEAN` | estática | `TRUE`→"Yes" (seq 1), `FALSE`→"No" (seq 2) — rótulos em inglês | Coluna `STATUS` (dataType `BOOLEAN`) em p15 e p26 |
| `colaborador-nome-completo` | `COLABORADOR.NOME_COMPLETO` | tabela `COLABORADOR` | `ID_COLABORADOR` / `NOME_COMPLETO`, ordena por `NOME_COMPLETO` | p26, p27 |
| `departamento-nome` | `DEPARTAMENTO.NOME` | tabela `DEPARTAMENTO` | `ID_DEPARTAMENTO` / `NOME` | p26, p27 |
| `empresa-nome` | `EMPRESA.NOME` | tabela `EMPRESA` | `ID_EMPRESA` / `NOME` | p26, p27 |

As LOVs de tabela **não filtram por empresa** (multi-tenant) nem por `status` → mostram colaboradores/departamentos de todas as empresas.

---

## 7. Component Settings e Build Options
- `component-settings.apx`: valores app-wide de plugins nativos. Relevantes: **Checkbox** `uncheckedValue: N`; **Switch** `onValue: Y` (portanto off = `N` padrão); **Date Picker** com `monthPicker`, `yearPicker`, `showTodayButton`; **Star Rating** tooltip `#VALUE#`; **Geocoded Address** `mapPreview: [resultsPopup, item]`. Demais (`showAiAssistant`, `colorPicker`, `selectMany`, `serverSideGeocoding`, `regionDisplaySelector`, `interactiveReport`, `map`, REST `oracleCloudAppsSaas`/`oracleCloudAppsBoss`) estão com defaults. Atenção: colunas do banco são `BOOLEAN` (23ai) em vários lugares, mas switch/checkbox gravam `Y`/`N`.
- `build-options.apx`: só `commented-out` ("Commented Out", padrão APEX para excluir componentes). Não é referenciado por nenhum componente versionado.

---

## 8. Tema e templates customizados (`shared-components/themes/universal-theme/`)

### 8.1 `theme.apx`
Universal Theme `themeNumber: 42`, `baseTheme: ut-26.1`, estilo atual `@/redwood-light`, ícones `fontApex`, `filePrefix: #APEX_FILES#themes/theme_42/26.1/`. JS: `widget.stickyWidget` + `theme42#MIN#.js`; CSS: `Core#MIN#.css`.
Defaults de componente: **page = `@corlix-standard-page`** (páginas novas nascem com o template custom), login/erro = `@/login`, modal = `@/modal-dialog`, breadcrumb region = `@/title-bar`, região = `@/standard`, IR = `@/interactive-report`, labels = `optional-floating`/`required-floating`, botão = `@/text`, lista = `@/links-list`, nav menu side = `@/side-navigation-menu`.
`themes/universal-theme/static-files/10245258954911381.css` e `10246955817960493.css`: 68 bytes cada, **só o comentário de copyright da Oracle** (criados por `EDUARDOMARINS` em 2026-07-08, provavelmente sobras de Theme Roller). Inócuos.

### 8.2 Page template `corlix-standard-page` ("Corlix - Standard Page", class `oneLevelTabs`)
Usado por: p4 Chat, p5 Notificações, p6 Configurações, p7 Monitor de Logs, p26 Central de Equipes. As demais páginas normais (1, 2, 3, 8, 11, 12, 13, 14, 15) usam explicitamente `@/standard`.
É uma cópia simplificada do Standard do UT **sem colunas laterais**:
- `<body class="t-PageBody t-PageBody--hideLeft t-PageBody--hideActions no-anim t-PageTemplate--standard #PAGE_CSS_CLASSES#">`; JS on load `apex.theme42.initializePage.noSideCol();`. `<html>` recebe `page-&APP_PAGE_ID. app-&APP_ALIAS.` (use `.page-4 ...` para CSS por página).
- Header `t-Header`: `#REGION_POSITION_07#` (banner), botão de colapsar menu `#t_Button_navControl`, `#LOGO#` + `#AFTER_LOGO#`, navbar com `#BEFORE_NAVIGATION_BAR#`, `#NAVIGATION_BAR#`, `#AFTER_NAVIGATION_BAR#`.
- Body: `#SIDE_GLOBAL_NAVIGATION_LIST#`, `t-Body-title` = `#REGION_POSITION_01#` (breadcrumb bar), mensagens, `t-Body-fullContent` = `#REGION_POSITION_08#`, `t-Body-contentInner` = `#BODY#`, footer `#REGION_POSITION_05#` + `#APP_VERSION#`, inline dialogs `#REGION_POSITION_04#`.
- Slots (nome APEXlang → posição): `afterLogo` (AFTER_LOGO), `beforeNavigationBar`, `afterNavigationBar` (itens/botões, sem grid, max 4), `banner` (POS_07), `breadcrumbBar` (POS_01), `body` (BODY, 12 col), `fullWidthContent` (POS_08), `footer` (POS_05), `dialogsDrawersAndPopups` (POS_04), `topNavigation` (POS_06).
- **Pegadinha:** o slot `topNavigation` (`REGION_POSITION_06`) está declarado mas **não há `#REGION_POSITION_06#` no HTML** → regiões ali não aparecem. Também **não existem** slots de coluna esquerda/direita (`REGION_POSITION_02/03`) — não use "Left Column"/"Right Column" nesse template.
- Navigation bar subtemplate: `<ul class="t-NavigationBar t-NavigationBar--classic">` com um `<li>` fixo mostrando `&APP_USER.` + entradas `#LINK#/#IMAGE#/#TEXT#`. Grid: 12 colunas, `alwaysUseMaxColumns: true`, classes `container`/`row`/`col col-N`. Template option: `js-pageStickyMobileHeader`. Error page template com `#MESSAGE#`, `#ADDITIONAL_INFO#`, `#TECHNICAL_INFO#`, botão `#OK#`.

### 8.3 Region template `cards-container-image-first` ("Cards Container - Image First", `custom1`)
Usado só na Home (p1). HTML:
```html
<div class="t-CardsRegion #REGION_CSS_CLASSES#" id="#DOM_ID#" #REGION_LANDMARK_ATTRIBUTES# #REGION_ATTRIBUTES#>
  <h2 class="t-CardsRegion-title" id="#DOM_ID#_heading" data-apex-heading>#TITLE#</h2>
  <div class="t-Region-orderBy">#ORDER_BY_ITEM#</div>
  #BODY#
  #SUB_REGIONS#
</div>
```
Slots: `regionBody` (BODY), `sortOrder` (ORDER_BY_ITEM, itens/botões), `subRegions`. Template options: `u-colors` (Apply Theme Colors, default), header `t-CardsRegion--hideHeader js-addHiddenHeadingRoleDesc` (preset) ou `t-CardsRegion--removeHeader js-removeLandmark`, estilo `t-CardsRegion--styleA|B|C`. Landmark `region`. É o "Cards Container" do UT; a ideia "image first" é aplicada por CSS/atributos da região Cards.

### 8.4 Classic report templates (named column, `custom1`) — usados só no Chat (p4)
A query deve devolver **exatamente** as colunas citadas (nomes em maiúsculas como `#COLUNA#`). Colunas com HTML devem ter `escapeSpecialChars: false`. CSS `.ch-*` está **inline na página 4** (não em arquivo estático).

**`chat-contatos`** — wrapper `<div class="ch-contacts"> ... </div>`; linha:
```html
#CAB_DEPT#
<a href="javascript:void(0)" class="ch-contact" data-id="#ID_COLABORADOR#">
  <span class="ch-avatar-wrap"><span class="ch-avatar">#INICIAIS#</span><i class="ch-dot ch-dot--#PRESENCA#"></i></span>
  <span class="ch-contact-txt"><b>#NOME_COMPLETO#</b><small>#CARGO#</small></span>
</a>
```
Colunas: `CAB_DEPT` (HTML `<div class="ch-dept">Depto</div>` só na 1ª linha de cada departamento, via `row_number() over (partition by d.nome ...)`), `ID_COLABORADOR` (lido por JS via `data-id`), `INICIAIS`, `PRESENCA` ∈ `online|ausente|offline` (classes `.ch-dot--online/ausente/offline`; calculada de `presenca_colaborador.data_ultimo_ping` 5/30 min), `NOME_COMPLETO`, `CARGO`. O JS marca o selecionado com `.ch-contact.is-active`.

**`chat-mensagens`** — wrapper `<div class="ch-msgs"> ... </div>`; linha:
```html
#SEP_DIA#
<div class="ch-msg ch-msg--#LADO#">
  <div class="ch-bubble"><span class="ch-txt">#CORPO#</span><span class="ch-time">#HORA#</span></div>
</div>
```
Colunas: `SEP_DIA` (HTML `<div class="ch-sep"><span>HOJE|ONTEM|dd/mm/yyyy</span></div>` na 1ª mensagem do dia), `LADO` ∈ `out` (enviada por `:APP_USER`) / `in`, `CORPO`, `HORA` (`hh24:mi`). Fonte: `canal_mensagem` filtrado por `:P4_CANAL_ID` e `excluida = false`.
Paginação dos dois: padrão UT (`#PAGINATION_NEXT#` etc.).

### 8.5 Button template `html-button-legacy-apex-5-migration` (`custom8`)
`<input type="button" value="#LABEL#" onclick="#JAVASCRIPT#" ...>` — legado, **não usado** em nenhuma página.

---

## 9. Static Application Files (`static-files.apx` + `static-files/`)
301 arquivos registrados (todos `charSet: utf-8`):

| Arquivo | Uso |
|---|---|
| `corlix-tema.css` / `corlix-tema.min.css` | Camada de tema (design system do Figma "Redwood Light (CorlixHub)"). Só redefine variáveis do UT (`--ut-*`, `--a-*`) e define tokens **`--cx-*`** (fonte da verdade: `--cx-primaria` = sky-120 `#00688C`, `--cx-primaria-hover`, `--cx-fundo`, `--cx-superficie`, `--cx-borda`, `--cx-texto`, `--cx-raio`, `--cx-raio-card`, `--cx-sucesso`, `--cx-alerta` ...). CSS de módulos (organograma, histórico-carreira) consomem esses tokens. **Novo, não commitado.** |
| `custom.css` / `custom.min.css` | Ajustes por página: overrides globais do UT, menu lateral (último item vai ao rodapé), header (`.corlix-header__search*`, `__actions`, `__icon-btn`, `__user*`, `__avatar`), card padrão (`.card-default`), Home (`.card-boas-vindas`, `.card-comunicados-oficiais`, `.card-meu-gestor`, `.links-rapidos-card`, `.card-aniversariantes`, `.popup-todos-aniversariantes`, `.figma-row`, `.cx-pessoa`), logs (`.log-descricao`, `.log-detalhe`). Modificado, não commitado. |
| `default-user.jpeg` | Avatar padrão (fallback em `onerror` e em `APP_USER_FOTO`). |
| `icons/app-icon-32.png`, `-144-rounded`, `-192`, `-256-rounded`, `-512` | Ícones do app/PWA; login (p9999) usa `#APP_FILES#icons/app-icon-512.png`. |
| `Fotos Colaboradores/<nome>_<sobrenome>.jpg` (291 arquivos) | Fotos fictícias dos colaboradores (ex.: `aline_alves.jpg`), `image/jpeg`. |

Como referenciar:
- `#APP_FILES#arquivo.ext` (em HTML, CSS URLs de página/app, SQL que gera HTML). `#MIN#` vira `.min` fora do modo debug (`#APP_FILES#custom#MIN#.css` → `custom.min.css`); **mantenha o par `.css`/`.min.css` sincronizado manualmente** (não há build automático no repo).
- Fotos: `#APP_FILES#Fotos Colaboradores/` || `COLABORADOR.FOTO_URL` (espera-se `FOTO_URL` = só o nome do arquivo, ex. `aline_alves.jpg`; o espaço na pasta funciona no browser, mas `%20` pode ser necessário em alguns contextos). Sempre adicionar `onerror="this.onerror=null;this.src='#APP_FILES#default-user.jpeg';"`.
- Docs dos módulos pedem subir `organograma.css` e `historico-carreira.css` como static files — **ainda não registrados** em `static-files.apx`.

---

## 10. Objetos de banco pressupostos (não criados pela app)
Nenhum DDL acompanha a app (sem supporting objects). O `README.md` cita `database/ddl/schema_corlixhub.sql` e `database/seed/seed_corlixhub.sql`, mas **esses arquivos não existem**. O DDL do schema base está em `database/corlix-hub.sql` (snapshot sem dados); os módulos têm o seu em `modulos/historico-carreira/01_ddl_historico_carreira.sql` e `modulos/organograma/organograma.sql`. Objetos que os shared components exigem:

| Objeto | Colunas usadas | Por quem |
|---|---|---|
| `COLABORADOR` | `id_colaborador`, `login_apex`, `id_cargo`, `id_empresa`, `id_departamento`, `id_gestor`, `foto_url`, `nome_completo`, `primeiro_nome`, `ultimo_nome`, `data_de_nascimento`, `status` (BOOLEAN) | app processes, LOV, Chat, Home |
| `CARGO` | `id_cargo`, `nome` | `APP_USER_CARGO`, Chat |
| `EMPRESA` | `id_empresa`, `nome` | `G_NOME_EMPRESA`, LOV |
| `DEPARTAMENTO` | `id_departamento`, `nome` | LOV, Chat |
| `PRESENCA_COLABORADOR` | `id_colaborador`, `data_ultimo_ping`, `status_presenca` | template chat-contatos (p4) |
| `CANAL_MENSAGEM` | `id_canal`, `id_colaborador`, `corpo`, `data_envio`, `excluida` (BOOLEAN) | template chat-mensagens (p4) |
| `APP_LOG` | `id`, `log_ts` (TIMESTAMP WITH TZ), `nivel` (`ERRO`/`AVISO`/`INFO`), `app_id`, `page_id`, `apex_user`, `session_id`, `origem`, `mensagem`, `detalhe` | Monitor de Logs (p7); presumivelmente escrita por `log_pkg` |
| `LOG_PKG.APEX_ERROR_HANDLER` | função `(p_error in apex_error.t_error) return apex_error.t_error_result` | error handler da app |
| `APEX_WORKSPACE_APEX_USERS` | `user_name`, `first_name`, `last_name` | `G_NOME_USUARIO` (view do APEX) |

---

## 11. `log_pkg.apex_error_handler`
Fonte em `database/corlix-hub.sql` (spec + body). `gravar` usa `pragma autonomous_transaction` e grava em `APP_LOG`; `erro`/`aviso`/`info` são atalhos. `apex_error_handler` registra origem (tipo do componente), `ORA-`, backtrace sem linhas `APEX_`/`SYS.` e o comando, e devolve `apex_error.init_error_result(p_error)` sem alterar a mensagem. **Não delega** -20001..-20099 a `pkg_historico_carreira.fn_tratar_erro`, como o guia do módulo recomenda. Detalhes em `05` §4.9.
---

## 12. Pegadinhas e inconsistências (resumo)
1. **Ordem dos CSS diverge** entre APEXlang (`corlix-tema` → `custom`) e `database/f100.sql` atual (`custom` → `corlix-tema`, linhas ~140–142). O correto, pelo comentário do próprio `corlix-tema.css`, é tema primeiro.
2. README aponta para `database/ddl/` e `database/seed/`, que não existem; o DDL base está em `database/corlix-hub.sql`.
3. Authorizations só no menu; páginas restritas (7, 14, 15, 16, 17) acessíveis por URL. Monitor de Logs sem authorization alguma.
4. Caminho de foto `#APP_FILES#fotos/` (app process e card Gestor) vs pasta real `Fotos Colaboradores/`.
5. 4 app processes sem condição em Before Header (custo por página, rodam no login). `APP_USER_NOME` órfão. `G_NOME_USUARIO` usa usuários do workspace, os demais usam `COLABORADOR.login_apex`.
6. Lista `emitir-comunicado` aponta para p18/p19 inexistentes e não é usada; números 18–23 reservados pelo módulo histórico-carreira.
7. Breadcrumb plano (sem pais); entry `cadastros` (p14) sem região; nome "Comunicação" ≠ menu "Comunicados"; static id `terminal` = Monitor de Logs.
8. `corlix-standard-page`: slot `topNavigation` sem placeholder; sem colunas laterais. Default de página do tema é esse template, mas a maioria das páginas usa `@/standard`.
9. Static ids com acentos (`publicador-de-conteúdo`, `comunicação`, `histórico-de-carreira`, `configurações`, `notificações`) e páginas duplicadas de notificações (p5 `NOTIFICACOES` usada pelo sino; p8 `NOTIFICAÇÕES` vazia).
10. Idioma primário `en` + máscaras `DS`; LOV `BOOLEAN` com rótulos "Yes/No" em inglês.
11. Links do cabeçalho com caminho de workspace `r/corlixhub/` fixo.
12. `deployments/default.json` com `debugging: true`.
13. Arquivos `.css` e `.min.css` mantidos à mão — editar os dois.

---

## 13. Mudanças não commitadas (git diff no momento da escrita)
- `corlixhub/application.apx`: `css.fileUrls` passou de `#APP_FILES#custom#MIN#.css` para a lista `[#APP_FILES#corlix-tema#MIN#.css, #APP_FILES#custom#MIN#.css]`.
- `corlixhub/shared-components/static-files.apx`: registrados `corlix-tema.css` e `corlix-tema.min.css` (arquivos novos, untracked, em `static-files/`).
- `static-files/custom.css` e `custom.min.css` modificados (~350 linhas; refatoração para usar tokens `--cx-*`).
- `database/f100.sql` modificado (+814/−510), incluindo `create_app_static_file` dos `corlix-tema*` e `p_css_file_urls` com os dois arquivos (ordem invertida, ver §12.1).
- Também untracked: `modulos/tema/` (README/Etapas do tema, que documentam a ordem `corlix-tema` → `custom`), `modulos/historico-carreira/`, `figma/`, `scripts/apex-limpar-sql-scripts.sql` (remove SQL Scripts do workspace via `apex_application_files`, `c_dry_run` = true por padrão).

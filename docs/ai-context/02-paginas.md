# 02 — Páginas da aplicação (APEX app 100 / CORLIXHUB)

> Documento de contexto para IA. Fonte: leitura integral de `corlixhub/pages/*.apx` (19 arquivos) + shared components citados (`corlixhub/shared-components/lists.apx`, `breadcrumbs.apx`, `authorizations.apx`, `app-processes.apx`, `app-items.apx`, `lovs.apx`, templates em `corlixhub/shared-components/themes/universal-theme/`). Estado: branch `DEV`, commit `bac2d69` + mudanças não commitadas (ver §5).
> `database/f100.sql` (export clássico, 12 MB) é equivalente; **não** leia inteiro, use `grep`.

---

## 1. Sintaxe APEXlang (`.apx`, mmdVersion 26.1.0) — o que é preciso para editar à mão

### 1.1 Estrutura geral
- Um arquivo por página: `corlixhub/pages/pNNNNN-<slug>.apx` (número com 5 dígitos; slug pode conter acentos, ex.: `p00008-notificações.apx`, `p00013-histórico-de-carreira.apx`).
- Blocos de **componente** usam `tipo identificador ( ... )` (parênteses). Blocos de **propriedades agrupadas** usam `grupo { ... }` (chaves). Ex.: `region novo ( ... layout { sequence: 10 } ... )`.
- Raiz: `page <número> ( name: ... alias: ... title: ... appearance {...} navigation {...} security {...} javaScript {...} css {...} <componentes> )`.
- Componentes filhos de página: `region`, `pageItem`, `button`, `process`, `dynamicAction` (com `action` filhos), `validation`, `branch` (sem identificador: `branch ( ... )`).
- Componentes aninhados: `region` de relatório contém `column`; IR contém `savedReport primary ( displayColumn X (...) sort (...) )`; `process type: invokeApi` contém `parameter`; botão com `action: triggerAction` contém `triggerAction <id> (...)`.
- Valores: escalares sem aspas (`label: Salvar Usuario`), listas com colchetes e um item por linha (`templateOptions: [ #DEFAULT# t-Region--noUI ]`), alvos de link como objeto `target: { page: 16 items: { P16_ID_EMPRESA: \#ID_EMPRESA#\ } action: resetPagination }` (note o escape `\#...#\` para substituições `#COL#` dentro de valores de item).
- Código multilinha em blocos cercados com linguagem: ` ```sql `, ` ```plsql `, ` ```html `, ` ```css `, ` ```javascript-browser `. A indentação do bloco é a do campo; o conteúdo é indentado relativo a ele.
- Comentários `//` aparecem só por acidente (ver bug histórico da Home em §5).

### 1.2 Referências `@`
- `@identificador` = componente local (região/item/botão da mesma página ou shared component do app). Ex.: `parentRegion: @container-conteudo-principal`, `region: @novo`, `button: @B_VER_TODOS`, `formRegion: @step-1`, `breadcrumb: @breadcrumb`, `lov: @boolean`, `authorizationScheme: @administration-rights`.
- `@/nome` = template/tema padrão do Universal Theme. Ex.: `pageTemplate: @/standard`, `@/login`, `@/modal-dialog`, `@/wizard-modal-dialog`, `template: @/blank-with-attributes`, `@/title-bar`, `@/interactive-report`, `@/cards-container`, `@/inline-dialog`, `@/tabs-container`, `@/buttons-container`, `@/required-floating`, `@/optional-floating`, `@/hidden`, `buttonTemplate: @/text`, `@/text-with-icon`.
- `@nome` sem barra para templates **customizados** do app: `@corlix-standard-page` (page template, `themes/universal-theme/page-templates/corlix-standard-page.apx`), `@cards-container-image-first` (region template), `@chat-contatos` e `@chat-mensagens` (classic report templates em `themes/universal-theme/classic-report-templates/`).
- O identificador do componente (ex.: `region new`, `region novo`, `region step-1`) é independente do `name:` exibido no Builder. Itens usam o próprio nome (`pageItem P14_CARGO`).

### 1.3 Layout / slots
- `layout { sequence: N slot: <slot> parentRegion: @x region: @x columnSpan: 8 startNewRow: false newColumn: false columnCssClasses: ... alignment: left }`.
- Slots de página vistos: `body`, `breadcrumbBar`, `contentBody`, `dialogsDrawersAndPopups`, `dialogFooter`, `wizardBody`, `wizardButtons`, `afterLogo`, `afterNavigationBar` (Global Page).
- Slots dentro de região: `regionBody`, `subRegions`, `tabs` (filhos de tabs-container), `next`, `close`, `delete`, `create`, `edit`, `rightOfInteractiveReportSearchBar` (botões).
- Itens apontam para região via `layout { region: @r slot: regionBody }`; colunas de form via `source { formRegion: @r column: COL dataType: ... primaryKey: true queryOnly: true }`.

### 1.4 Aparência
- `appearance { template: @/... templateOptions: [ #DEFAULT# classe1 classe2 ] cssClasses: ... icon: fa-xxx hot: true }`. `#DEFAULT#` = opções padrão do template; demais são classes do UT (`t-Region--noUI`, `t-Region--removeHeader js-removeLandmark`, `t-Button--danger`, `t-Button--iconRight`, ...). Nota: `t-Region--removeHeader js-removeLandmark` ocupa uma única linha (é uma opção composta).
- `componentAppearance { ... }` = template do componente interno (cards layout, report template, breadcrumb template).
- `#APP_FILES#` = prefixo de arquivos estáticos do app (`shared-components/static-files/`), ex.: `#APP_FILES#icons/app-icon-512.png`, `#APP_FILES#default-user.jpeg`. `#MIN#` alterna `.min` (usado em `application.apx`: `#APP_FILES#corlix-tema#MIN#.css`).
- Substituições: `&ITEM.` (session state, ex.: `&G_NOME_USUARIO.`, `&APP_ALIAS.`, `&SESSION.`, `&APP_ID.`), `&COL.` em HTML expressions de Cards, `#COL#` em templates de relatório/HTML expression de colunas IR, `&APP_TEXT$DELETE_MSG!RAW.` (texto de tradução com escape RAW).

### 1.5 Mini exemplo real (Home, botão + DA)
```
    button B_VER_TODOS (
        buttonName: B_VER_TODOS
        label: Ver todos
        layout {
            sequence: 10
            region: @lista-aniversariantes
            slot: next
        }
        appearance {
            buttonTemplate: @/text-with-icon
            templateOptions: [
                #DEFAULT#
                t-Button--noUI
                t-Button--iconRight
            ]
            icon: fa-arrow-right
        }
        behavior {
            action: definedByDynamicAction
        }
    )

    dynamicAction abrir-popup-aniversariantes (
        name: Abrir Popup Aniversariantes
        execution { sequence: 20 }
        when {
            event: click
            selectionType: button
            button: @B_VER_TODOS
        }
        action native-javascript-code (
            action: openRegion
            affectedElements {
                selectionType: region
                region: @POPUP_ANIVERSARIANTES
            }
            execution { sequence: 10 fireOnInit: false }
        )
    )
```
(No arquivo real cada propriedade fica em sua própria linha; condensei `execution` aqui.)

### 1.6 Outros padrões
- Processos: `process <id> ( name: type: executeCode|formInitialization|formAutoRowProcessing|closeDialog|clearSessionState|invokeApi  source { plsqlCode: ```plsql``` }  formRegion: @r  execution { sequence: N point: beforeHeader|afterSubmit }  serverSideCondition { type: requestIsContainedInValue value: CREATE,SAVE,DELETE }  successMessage {...}  advanced { executionMappingIdentifier: <número> } )`. O `executionMappingIdentifier` é gerado pelo APEX — preservar ao editar; ao criar um novo, omitir (provavelmente gerado na importação — não verificado).
- DAs: `when { event: click|ready|keyup|apexafterclosedialog  selectionType: button|items|region|jQuerySelector ... }`, `clientSideCondition { type: itemIsNotNull item: X }`, ações com `execution { fireWhenEventResultIs: false }` = ramo "falso". Sem `event:` explícito em DA de itens = evento padrão `change`.
- Ação servidor: `action: executeServerSideCode settings { plsqlCode: ... itemsToSubmit: X itemsToReturn: Y }`.
- Validação: `validation <id> ( validation { type: functionBodyReturningBoolean plsqlFunctionBody: ... alwaysExecute: true } error { errorMessage: ... associatedItem: @ITEM } )`.
- Itens: `type: textField|password|checkbox|switch|selectOne|selectList|popupLov|datePicker|textarea|hidden|imageUpload`; `lov { type: sqlQuery|sharedComponent sqlQuery: ... lov: @x }`; `cascadingLov { parentItems: ... itemsToSubmit: ... }`; `validation { valueRequired: true maxLength: N }`; `default { type: expression|sqlQuerySingleValue ... }`; `sessionState { dataType: boolean|clob storage: request|session }`.
- Segurança comum a todas as páginas: `security { pageAccessProtection: argumentsMustHaveChecksum formAutoComplete: false }`. **Nenhuma página declara `authorizationScheme` próprio** (ver §6).

---

## 2. Tabela-resumo

| Nº | Nome | Alias | Arquivo | Template | Modo | Autorização (página / menu) | Status |
|---|---|---|---|---|---|---|---|
| 0 | Global Page | — | p00000-global-page.apx | — | — | — | Implementada (header: busca + ações/usuário) |
| 1 | Home | HOME | p00001-home.apx | @/standard | normal | nenhuma / nenhuma | Implementada (dashboard) |
| 2 | Meu Perfil | MEU-PERFIL | p00002-meu-perfil.apx | @/standard | normal | nenhuma / nenhuma | Placeholder (só breadcrumb) |
| 3 | Organograma | ORGANOGRAMA | p00003-organograma.apx | @/standard | normal | nenhuma / nenhuma | Placeholder (módulo em `modulos/organograma/`, não integrado) |
| 4 | Chat | CHAT | p00004-chat.apx | @corlix-standard-page | normal | nenhuma / nenhuma (coluna CAB_DEPT exige @administration-rights) | Implementada parcialmente (leitura; sem envio) |
| 5 | Notificações | NOTIFICACOES | p00005-notificacoes.apx | @corlix-standard-page | normal | nenhuma | Placeholder (breadcrumb) |
| 6 | Configurações | CONFIGURACOES | p00006-configuracoes.apx | @corlix-standard-page | normal | nenhuma | Placeholder (breadcrumb) |
| 7 | Monitor de Logs | MONITOR_LOGS | p00007-monitor-logs.apx | @corlix-standard-page | normal | nenhuma / nenhuma (!) | Implementada (3 IRs em abas) |
| 8 | Notificações | NOTIFICAÇÕES | p00008-notificações.apx | @/standard | normal | nenhuma | Vazia (nem breadcrumb) — duplicata da 5 |
| 11 | Comunicados Oficiais | COMUNICADOS-OFICIAIS | p00011-comunicados-oficiais.apx | @/standard | normal | nenhuma / nenhuma | Placeholder (breadcrumb) |
| 12 | Colaboradores | COLABORADORES | p00012-colaboradores.apx | @/standard | normal | nenhuma / nenhuma | Placeholder (breadcrumb) |
| 13 | Histórico de carreira | HISTÓRICO-DE-CARREIRA | p00013-histórico-de-carreira.apx | @/standard | normal | nenhuma / nenhuma | Placeholder (módulo em `modulos/historico-carreira/`, não integrado) |
| 14 | Cadastro de Usuários | CADASTROS-DE-USUARIOS | p00014-cadastros-de-usuarios.apx | @/standard | normal | nenhuma / menu: @somente-diretoria | Implementada (form COLABORADOR + cria usuário APEX) |
| 15 | Empresas Cadastradas | EMPRESAS-CADASTRADAS | p00015-empresas-cadastradas.apx | @/standard | normal | nenhuma / menu: @administration-rights | Implementada (IR EMPRESA) |
| 16 | Cadastro de Empresas | CADASTRO-DE-EMPRESAS | p00016-cadastro-de-empresas.apx | @/modal-dialog | modal | nenhuma / (isCurrent do item 15) | Implementada (form EMPRESA + ViaCEP) |
| 17 | Emitir Comunicado | COMUNICADO | p00017-comunicado.apx | @/wizard-modal-dialog | modal (h=600) | nenhuma / menu: @publicador-de-conteudo | Implementada (form COMUNICADO) |
| 26 | Central de Equipes | CENTRAL-DE-EQUIPES | p00026-central-de-equipes.apx | @corlix-standard-page | normal | nenhuma / nenhuma | Implementada (classic report EQUIPE) |
| 27 | Nova Equipe | NOVA-EQUIPE | p00027-nova-equipe.apx | @/modal-dialog | modal | nenhuma | Implementada (form EQUIPE) |
| 9999 | Login Page | LOGIN | p09999-login.apx | @/login | normal, `authentication: public` | pública | Implementada (login padrão APEX) |

Notas da tabela:
- Grupo de páginas: existe só `pageGroup administration` (`corlixhub/page-groups.apx`), **nenhuma página o referencia**.
- Autorizações existentes (`shared-components/authorizations.apx`, todas `isInRoleOrGroup`, avaliação por sessão): `administration-rights` ("Equipe do Corlix Hub"), `publicador-de-conteudo` ("Publicador de Conteúdo"), `somente-diretoria` ("Diretoria"). Só são usadas em entradas do menu e na coluna CAB_DEPT do Chat.
- Páginas inexistentes mas referenciadas: 18 e 19 (lista `emitir-comunicado`, steps 2 e 3 do wizard).
- Menu lateral (`list navigation-menu`): Home(1) seq10 → Meu Perfil(2) 20 → Organograma(3) 30 → Comunicados(11) 40 → Colaboradores(12) 50 → Histórico de carreira(13) 60 → Cadastro de Usuários(14) 70 → Emitir Comunicado(17) 80 (filho de Home) → Empresas Cadastradas(15) 110 → Central de Equipes(26) 160 → Chat(4) 170 → Monitor de Logs(7) 190 → Sair (`&LOGOUT_URL.`) 10000. Páginas 5, 6, 8 não estão no menu (5 e 6 são acessadas pelo header da Global Page).
- Breadcrumb único `breadcrumb` (shared component): entradas planas (sem hierarquia/parent) para 1, 2, 3, 5, 6, 7, 11, 12, 13, 14, 15, 26. Páginas 14 e 15 não exibem região breadcrumb (14 não tem; 15 tem).

---

## 3. Contexto global usado pelas páginas

- **Application items** (`app-items.apx`): `APP_USER_CARGO`, `APP_USER_FOTO`, `APP_USER_NOME` (não preenchido por nenhum processo visto), `G_NOME_EMPRESA`, `G_NOME_USUARIO`.
- **Application processes** (`app-processes.apx`, todos `executeCode`, `sequence: 1`, ponto de execução não explícito no .apx):
  - `APP_USER_CARGO`: `CARGO.nome` via `COLABORADOR.login_apex = :APP_USER` (UPPER/TRIM); fallbacks 'SEM VÍNCULO' / 'MÚLTIPLOS VÍNCULOS' / 'ERRO AO CARREGAR CARGO'.
  - `APP_USER_FOTO`: `'#APP_FILES#fotos/' || foto_url` ou `'#APP_FILES#default-user.jpeg'`.
  - `G_NOME_EMPRESA`: `EMPRESA.nome` do colaborador logado; fallback com texto de erro + usuário.
  - `G_NOME_USUARIO`: `initcap(first_name||' '||last_name)` de `apex_workspace_apex_users` (usuários do workspace APEX, não da tabela COLABORADOR); fallback `:APP_USER`.
- **LOVs compartilhadas** (`lovs.apx`): `boolean` (estática Yes/TRUE, No/FALSE), `colaborador-nome-completo` (COLABORADOR), `departamento-nome` (DEPARTAMENTO), `empresa-nome` (EMPRESA). Nenhuma filtra por empresa.
- O vínculo usuário APEX ↔ colaborador é sempre `COLABORADOR.LOGIN_APEX = :APP_USER` (às vezes com UPPER, às vezes sem — ver pegadinhas).

---

## 4. Páginas em detalhe

### Página 0 — Global Page (`p00000-global-page.apx`)
- **Propósito**: regiões renderizadas em todas as páginas (header customizado).
- **Regiões**:
  - `novo` "Barra de Busca" — staticContent, slot `afterLogo`, template @/standard com `t-Region--removeHeader js-removeLandmark`, `t-Region--noUI`, `t-Region--scrollBody`. HTML: `<div class="corlix-header__search">` com ícone `fa-search` e `<input id="P0_SEARCH_GLOBAL" class="corlix-header__search-input" placeholder="Buscar na intranet...">`. **Não é um page item** (input HTML puro) e **não há JS/DA associado** → busca sem funcionalidade.
  - `perfil` "Perfil" — staticContent, slot `afterNavigationBar`. HTML: link sino `fa-bell-o` → `r/corlixhub/&APP_ALIAS./notificacoes?session=&SESSION.` (página 5), link engrenagem `fa-cog` → `.../configuracoes` (página 6), bloco usuário com `&G_NOME_USUARIO.`, `&APP_USER_CARGO.`, `<img src="&APP_USER_FOTO.">` (classes `corlix-header__*`).
- **Pegadinhas**: os hrefs são relativos e começam com `r/corlixhub/...` (sem `/` inicial nem `f?p`); a resolução depende da URL corrente (friendly URL `/ords/r/<workspace>/<alias>/<page>`) e pode gerar caminho duplicado — conferir no browser. Prefira `f?p=&APP_ID.:5:&SESSION.` ou `apex.util.makeApplicationUrl`. Slots `afterLogo`/`afterNavigationBar` existem no `@corlix-standard-page`; páginas com `@/standard` podem renderizar o header de forma diferente.

### Página 1 — Home (`p00001-home.apx`)
- **Propósito**: dashboard inicial (boas-vindas, comunicados recentes, gestor, links rápidos, aniversariantes do mês).
- **Layout** (grid 12 colunas):
  - `container-conteudo-principal` (staticContent, @/blank-with-attributes, slot body, `columnSpan: 8`, `columnCssClasses: .container-conteudo-principal` ← **com ponto, bug**: a classe gerada será literalmente `.container-conteudo-principal`).
    - `card-boas-vindas` (seq 10): `<h1>Bem-vindo, &G_NOME_USUARIO.! 👋</h1>` + texto com `<a href="#" class="link-empresa">&G_NOME_EMPRESA.</a>` (link morto). Classes `card-default card-boas-vindas`.
    - `card-comunicados-oficiais` (seq 30): htmlCode `<h2> Comunicados Oficiais </h2>`, classes `card-default card-comunicados-oficiais`.
      - `id-lista-de-comunicados` (cards, template customizado `@cards-container-image-first`, `t-CardsRegion--hideHeader`, layout horizontal, `columnCssClasses: lista-de-comunicados`). SQL: `COMUNICADO c LEFT JOIN DEPARTAMENTO d`, colunas ID_COMUNICADO, TITULO, `DBMS_LOB.SUBSTR(CONTEUDO,250,1)`, DATA_PUBLICACAO, IMAGEM, MIME_TYPE, NOME_ARQUIVO, `NVL(d.NOME,'Geral') DEPARTAMENTO`, `CLASSE_DEPTO` ('dept-'||MOD(id,6)), `TEMPO_PUBLICACAO` ('Hoje'/'Ontem'/'N dias atrás' via `TRUNC(SYSDATE)`), `ORDER BY DATA_PUBLICACAO DESC FETCH FIRST 3 ROWS ONLY`. Title HTML: `<span class="cx-etiqueta">&DEPARTAMENTO.</span><span class="cmt-date">&TEMPO_PUBLICACAO.</span><div class="cmt-title">&TITULO.</div>`; body = CONTEUDO; media = BLOB `IMAGEM` (mime `MIME_TYPE`), posição first, classe `imagem-capa-comunicado`.
        - `botao-emitir-comunicado` (staticContent filho da região de cards, slot subRegions, `columnCssClasses: emitir-comunicado`) contendo o botão `emitir-comunicado`.
  - `container-conteudo-diversos` (seq 40, `columnSpan: 4`, `startNewRow: false`, classe `container-conteudo-diversos`):
    - `card-meu-gestor` (cards, @/cards-container, `t-CardsRegion--hideHeader`, classes `card-default card-meu-gestor`). SQL: `COLABORADOR C JOIN COLABORADOR G ON G.ID_COLABORADOR = C.ID_GESTOR JOIN CARGO CG ON CG.ID_CARGO = G.ID_CARGO WHERE C.LOGIN_APEX = :APP_USER` → NOME_CARGO, NOME_GESTOR (PRIMEIRO_NOME||' '||ULTIMO_NOME), FOTO_GESTOR (`'#APP_FILES#fotos/'||FOTO_URL` ou default). Header `<h3>Meu gestor</h3>`, footer com dois botões `t-Button` "Chat"/"E-mail" com `href="#"` (mortos). Title HTML `cx-pessoa` com `onerror` → `#APP_FILES#default-user.jpeg`. SQL termina com `;` (ver pegadinhas).
    - `links-rapidos` (seq 40, staticContent): 3 `.link-item` com `onclick="apex.navigation.redirect('f?p=&APP_ID.:N:&SESSION.')"`: "Holerite Digital" → **página 5** (Notificações), "Ponto Eletrônico" → **página 6** (Configurações), "Suporte TI" → **página 7** (Monitor de Logs). Destinos são placeholders/incorretos. SVGs usam `currentColor`.
    - `card-aniversariantes` (seq 50, staticContent): cabeçalho `<div class="cx-cabecalho-card"><h3>Aniversariantes</h3><span class="figma-badge-mes cx-badge cx-badge--info"></span></div>` (badge preenchido via JS).
      - `lista-aniversariantes` (type cards, mas template `@/blank-with-attributes`): SQL sobre `COLABORADOR` filtrando mês de nascimento = mês atual em `America/Sao_Paulo` (`CAST(SYSTIMESTAMP AT TIME ZONE 'America/Sao_Paulo' AS DATE)`), colunas ID_COLABORADOR, NOME_COMPLETO, DATA_DE_NASCIMENTO, FOTO_URL (`'#APP_FILES#Fotos Colaboradores/'||FOTO_URL`), NOME, DESCRICAO ('Hoje' / 'Amanhã, DD de Mês' / 'DD de Mês'), CSS_NIVER_HOJE ('is-birthday-today'/'is-normal-day'), MES_CORRENTE; `ORDER BY EXTRACT(DAY ...) FETCH FIRST 5 ROWS ONLY;`. Title HTML `figma-row &CSS_NIVER_HOJE.` com avatar (`onerror` default), nome, data e ícone 🎂 (visível só via CSS em `is-birthday-today`).
  - `POPUP_ANIVERSARIANTES` (cards, slot `dialogsDrawersAndPopups`, template `@/inline-dialog` com `js-dialog-autoheight js-dialog-size600x400`, classe `popup-todos-aniversariantes`, title "TODOS OS ANIVERSARIANTES DO MÊS", `lazyLoading: true`, media `u-circle`). Mesma SQL da lista sem o `FETCH FIRST 5`.
- **Itens**: nenhum.
- **Botões**: `B_VER_TODOS` ("Ver todos", @/text-with-icon, `t-Button--noUI t-Button--iconRight`, `fa-arrow-right`, classe `figma-footer-link`, slot `next` de `lista-aniversariantes`, ação via DA). `emitir-comunicado` (buttonName `botao_emitir_comunicado`, "Novo comunicado", `fa-plus`, `t-Button--iconLeft`, classe `botao-emitir-comunicado`) → `redirectThisApp` página 17 (sem autorização).
- **Dynamic actions**: `carregar-mês-no-badge` (event `ready`, JS: `new Date().toLocaleString('pt-BR',{month:'long'})` capitalizado → `.figma-badge-mes.innerText`); `abrir-popup-aniversariantes` (click em B_VER_TODOS → `openRegion` POPUP_ANIVERSARIANTES).
- **JS da página** (`javaScript.executeWhenPageLoads`): `carregarCapasComunicados()` força `loading='eager'`, `decoding='async'` e `fetchPriority='high'` na 1ª imagem de `.lista-de-comunicados img.a-CardView-mediaImg`; reaplica em `apexafterrefresh`.
- **CSS inline**: nenhum (estilos em `corlix-tema.css`/`custom.css`).
- **Processos/validações/branches**: nenhum.
- **Banco**: COLABORADOR, CARGO, COMUNICADO, DEPARTAMENTO; app items G_NOME_USUARIO, G_NOME_EMPRESA.
- **Navegação**: → 17 (botão), → 5/6/7 (links rápidos), popup inline.
- **Pegadinhas**:
  - Comunicados e aniversariantes **não filtram por empresa** (`ID_EMPRESA`) nem por `STATUS` do colaborador → vazamento entre tenants num SaaS multiempresa.
  - Pastas de foto inconsistentes: aniversariantes usam `#APP_FILES#Fotos Colaboradores/` (com espaço), gestor e header usam `#APP_FILES#fotos/`. Quando `FOTO_URL` é nulo a query de aniversariantes retorna o caminho da pasta (não uma imagem) e depende do `onerror` para cair no `default-user.jpeg`.
  - `TEMPO_PUBLICACAO` usa `SYSDATE` (fuso do servidor) enquanto aniversariantes usam fuso São Paulo.
  - `MES_CORRENTE` e `CLASSE_DEPTO` são calculados e não usados (badge é preenchido no cliente).
  - SQLs terminam com `;` (cards de gestor, comunicados, lista de aniversariantes). O APEX costuma tolerar/remover o `;` final, mas é bom remover.
  - O botão "Novo comunicado" aparece para todos; no menu o mesmo destino exige `publicador-de-conteudo`, e a página 17 não tem autorização.
  - Após fechar o modal 17 não há DA `apexafterclosedialog` para atualizar a lista de comunicados (e a 17 nem fecha o diálogo — ver página 17).

### Página 2 — Meu Perfil (`p00002-meu-perfil.apx`)
Placeholder: só região `breadcrumb` (type breadcrumb, `@breadcrumb`, slot breadcrumbBar, @/title-bar com `t-BreadcrumbRegion--useBreadcrumbTitle`). Template @/standard. Nada mais.

### Página 3 — Organograma (`p00003-organograma.apx`)
Placeholder idêntico à 2. O módulo real está sendo desenvolvido fora do app em `modulos/organograma/` (`organograma.sql/.js/.css`, `Etapas-organograma.md`, PNGs de redesign — tudo não commitado/modificado); ainda não há região/JS na página.

### Página 4 — Chat (`p00004-chat.apx`)
- **Propósito**: chat interno 1:1. Coluna esquerda com contatos agrupados por departamento e status de presença; coluna direita com mensagens do canal direto.
- **Página**: template `@corlix-standard-page`, `cssClasses: ch-page`. CSS inline extenso (variáveis `--ch-*` mapeadas para tokens do tema `--cx-*`, exceto presença `--ch-online #22C55E`, `--ch-ausente #F59E0B`, `--ch-offline #D1D5DB`); zera padding do `t-Body-content` em `.ch-page`; `.ch-shell` é grid `260px 1fr` com `height: calc(100vh - 40px)`; wrappers APEX viram `display: contents`; estilos `.ch-dept`, `.ch-contact(.is-active)`, `.ch-avatar`, `.ch-dot--online|ausente|offline`, `.ch-msgs`, `.ch-sep`, `.ch-msg--in|out`, `.ch-bubble`, `.ch-time`.
- **Regiões**:
  - `chat-shell_1` "Chat Shell" (staticContent, @/blank-with-attributes, classe `ch-shell`).
    - `contatos` "Lista" (classicReport, template de relatório customizado `@chat-contatos`, `columnCssClasses: ch-list`, `breakFormatting.breakColumns: col1`). SQL: `colaborador c JOIN departamento d LEFT JOIN cargo cg LEFT JOIN presenca_colaborador p` → departamento, id_colaborador, nome_completo, cargo, foto_url, iniciais (`upper(substr(primeiro_nome,1,1)||substr(ultimo_nome,1,1))`), presenca (`online` se `p.data_ultimo_ping > systimestamp - 5 min` e `status_presenca='ONLINE'`; `ausente` se ping < 30 min; senão `offline`), `cab_dept` (HTML `<div class="ch-dept">nome</div>` na 1ª linha de cada departamento via `row_number()`); `where c.status = true and nvl(upper(c.login_apex),'x') != upper(:APP_USER) order by d.nome, c.nome_completo`. O template `chat-contatos` renderiza `#CAB_DEPT#` + `<a href="javascript:void(0)" class="ch-contact" data-id="#ID_COLABORADOR#">` com avatar/iniciais/dot/nome/cargo. Colunas: CAB_DEPT (`escapeSpecialChars: false`, **`authorizationScheme: @administration-rights`**), CARGO, DEPARTAMENTO, FOTO_URL, ID_COLABORADOR, INICIAIS, NOME_COMPLETO, PRESENCA.
    - `conversa` "Conversa" (staticContent, classe `ch-chat`).
      - `msgs` "Mensagens" (classicReport, template `@chat-mensagens`, `customAttributes: class="ch-msgs-wrap"`, **serverSideCondition `itemIsNotNull P4_CANAL_ID`**). SQL: `canal_mensagem m JOIN colaborador col ON col.id_colaborador = m.id_colaborador WHERE m.id_canal = :P4_CANAL_ID AND nvl(m.excluida,false) = false ORDER BY m.data_envio` → corpo, hora (`hh24:mi`), lado (`out` se `col.login_apex = :APP_USER`, senão `in`), sep_dia (HTML `ch-sep` com HOJE/ONTEM/dd/mm/yyyy na 1ª msg do dia; `escapeSpecialChars: false`).
- **Itens**: `P4_CONTATO_ID` (hidden, seq 20, `valueProtected: false`), `P4_CANAL_ID` (hidden, seq 30, `valueProtected: false`). Ambos no slot body.
- **Botões / processos / validações**: nenhum.
- **Dynamic action** `selecionar-contato` (click, jQuery `.ch-contact`):
  1. seq 20 `executeJsCode`: `apex.item("P4_CONTATO_ID").setValue(this.triggeringElement.dataset.id)`; troca a classe `is-active`.
  2. seq 30 `executeServerSideCode` (submit P4_CONTATO_ID, retorna P4_CANAL_ID): busca `id_colaborador` do usuário (`upper(login_apex) = upper(:APP_USER)`) e `:P4_CANAL_ID := ch_get_canal_direto(l_eu, :P4_CONTATO_ID);`.
  3. seq 40 `refresh` da região `msgs`.
- **Banco**: tabelas COLABORADOR, DEPARTAMENTO, CARGO, PRESENCA_COLABORADOR, CANAL_MENSAGEM; função `CH_GET_CANAL_DIRETO(p_colab_a, p_colab_b)` (devolve ou cria o canal direto em `CANAL`/`CANAL_PARTICIPANTE`). DDL em `database/corlix-hub.sql`; ver `05` §4–4A.
- **Navegação**: nenhuma (tudo AJAX).
- **Pegadinhas**:
  - **Bug provável principal**: a região `msgs` tem condição de servidor `P4_CANAL_ID is not null`; na carga inicial o item é nulo, então a região **não é renderizada** e o `refresh` da DA não tem o que atualizar → mensagens nunca aparecem sem recarregar a página. Solução típica: remover a condição e usar "Page Items to Submit = P4_CANAL_ID" na região (e retornar sem linhas quando nulo).
  - A região `msgs` não declara "Page Items to Submit" = P4_CANAL_ID. O valor é atribuído em sessão pelo PL/SQL da DA e devolvido ao cliente via `itemsToReturn`, então provavelmente já está em sessão no refresh, mas declarar o item na região é o padrão mais seguro.
  - Coluna `CAB_DEPT` restrita a `@administration-rights` → usuários comuns não veem cabeçalhos de departamento (provavelmente acidental).
  - `componentAppearance.templateOptions: "[object Object]"` na região `contatos` — valor corrompido (serialização JS errada), deveria ser `#DEFAULT#`.
  - Não há campo/botão de envio de mensagem, nem polling/refresh periódico, nem atualização de presença (ping) — chat apenas leitura.
  - `select ... into l_eu` sem tratamento de `NO_DATA_FOUND`/`TOO_MANY_ROWS`.
  - `lado` compara `login_apex = :APP_USER` sem UPPER (case-sensitive), enquanto a lista usa UPPER → mensagens próprias podem aparecer como `in` se o login estiver gravado em minúsculas (APP_USER costuma vir em maiúsculas).
  - Contatos não filtrados por empresa (multi-tenant).
  - `c.status = true` usa BOOLEAN SQL nativo (Oracle 23ai).

### Página 5 — Notificações (`p00005-notificacoes.apx`)
Placeholder: só `navegação-estrutural` (breadcrumb). Template `@corlix-standard-page`. Destino do sino do header (alias `notificacoes`) e do link rápido "Holerite Digital".

### Página 6 — Configurações (`p00006-configuracoes.apx`)
Placeholder: só breadcrumb `navegação-estrutural`. Template `@corlix-standard-page`. Destino da engrenagem do header e do link rápido "Ponto Eletrônico".

### Página 7 — Monitor de Logs (`p00007-monitor-logs.apx`)
- **Propósito**: tela técnica de observabilidade.
- **Regiões**: `navegação-estrutural` (breadcrumb); `logs` "Logs da aplicação" (staticContent, @/tabs-container, `js-useLocalStorage t-TabsRegion-mod--simple`) com 3 IRs (@/interactive-report, header escondido, paginação `rowRangesXToY`, saved report primário 50 linhas, sort DATA_HORA desc) no slot `tabs`:
  1. `app_log` "Log da aplicação" (seq 10): `select id, log_ts at time zone 'America/Sao_Paulo' as data_hora, nivel, nivel_css (ERRO→u-danger, AVISO→u-warning, INFO→u-info, senão u-normal), app_id, page_id, apex_user, session_id, origem, mensagem, detalhe from app_log`. NIVEL com HTML expression `<span class="t-Badge #NIVEL_CSS#">#NIVEL#</span>`; DETALHE (CLOB) em `<details class="log-detalhe"><summary>Ver detalhes</summary><pre>#DETALHE#</pre></details>`, sem filtro/sort/agregação. Header: "Erros capturados automaticamente e mensagens gravadas pelo código com `log_pkg`" + tags "Automático", "Histórico de 30 dias".
  2. `apex_workspace_activity_log` "Erros de página (APEX)" (seq 20): view `apex_workspace_activity_log where error_message is not null`, data convertida de UTC para São Paulo; colunas app, pagina, nome_pagina, usuario, erro, tipo_componente, componente.
  3. `apex_debug_messages` "Debug detalhado (APEX)" (seq 30): view `apex_debug_messages`, nível 1/2/4 → ERRO/AVISO/INFO, senão DEBUG, badge igual; mensagens de "no data" em PT.
- **Itens/botões/processos/DAs**: nenhum. CSS das classes `log-descricao`, `log-tag`, `log-detalhe` vem do tema global.
- **Banco**: tabela `APP_LOG` + package `LOG_PKG` (DDL em `database/corlix-hub.sql`; ver `05` §4.9), views APEX `APEX_WORKSPACE_ACTIVITY_LOG`, `APEX_DEBUG_MESSAGES`.
- **Pegadinhas**: **sem autorização** na página e no menu → qualquer usuário logado vê logs/debug (dados sensíveis). As views APEX não são filtradas por `application_id` (mostram o workspace inteiro). Colunas DATA_HORA declaradas `dataType: DATE` mas a SQL retorna TIMESTAMP WITH TIME ZONE (máscara `DD/MM/YYYY HH24:MI:SS`). Mensagens "no data" só traduzidas no IR de debug. Também é destino do link rápido "Suporte TI" da Home.

### Página 8 — Notificações (`p00008-notificações.apx`)
Página **vazia** (sem regiões, sem breadcrumb), alias com caracteres não-ASCII `NOTIFICAÇÕES`, template @/standard. Duplicata da página 5; não referenciada por menu/breadcrumb/links. Candidata a remoção (ou a 5 deveria ser a única).

### Página 11 — Comunicados Oficiais (`p00011-comunicados-oficiais.apx`)
Placeholder (só `breadcrumb`). Template @/standard. No menu como "Comunicados" (seq 40). A listagem real de comunicados hoje só existe na Home (top 3).

### Página 12 — Colaboradores (`p00012-colaboradores.apx`)
Placeholder (só `breadcrumb`). Template @/standard.

### Página 13 — Histórico de carreira (`p00013-histórico-de-carreira.apx`)
Placeholder (só `breadcrumb`). Alias com acento `HISTÓRICO-DE-CARREIRA`. Módulo em desenvolvimento fora do app em `modulos/historico-carreira/` (DDL, views, `pkg_historico_carreira`, `pkg_historico_carreira_ui`, triggers, JS/CSS da página, `instalar.sql`) — não commitado e ainda não ligado à página.

### Página 14 — Cadastro de Usuários (`p00014-cadastros-de-usuarios.apx`)
- **Propósito**: cadastrar colaborador (insert em COLABORADOR) e criar o usuário de login no APEX.
- **Regiões**: `cadastrar-colaborador-header` (staticContent seq 10, `<h1 class="cx-titulo">Cadastro de usuários</h1><p class="cx-descricao">...`); `novo` "Cadastrar Colaborador" (**form** sobre tabela `COLABORADOR`, seq 20, @/standard sem header, `t-Region--stacked`), com sub-regiões (`t-Region--noUI`): `new` "INFORMAÇÕES DE LOGIN" (seq 20), `dados-do-colaborador` "DADOS DO COLABORADOR" (seq 30), `status-do-registro` "STATUS DO REGISTRO" (seq 50, texto "Contas inativas não terão acesso ao sistema."). Sem breadcrumb.
- **Itens** (form region `@novo`, largura 30):
  | Item | Tipo | Coluna | Região | Obrig. | LOV / obs |
  |---|---|---|---|---|---|
  | P14_ID_COLABORADOR | hidden, PK, queryOnly, checksum de sessão | ID_COLABORADOR | novo | — | |
  | P14_LOGIN | textField (max 255) | LOGIN_APEX | new | não | "Login Corporativo" |
  | P14_EMAIL | textField email (max 200) | EMAIL | new | sim | label "E-mail Coporativo" (typo) |
  | P14_SENHA | password | — (não mapeado) | new | não | usado só no CREATE_USER |
  | P14_CONFIRMAR_SENHA | password | — | new | não | |
  | P14_NOME_COMPLETO | textField (max 200) | NOME_COMPLETO | dados | sim | |
  | P14_PRIMEIRO_NOME | textField (max 30) | PRIMEIRO_NOME | dados | não | |
  | P14_ULTIMO_NOME | textField (max 30) | ULTIMO_NOME | dados | não | |
  | P14_DATA_ADMISSAO | datePicker nativo, `YYYY-MM-DD` | DATA_ADMISSAO | dados | não | |
  | P14_DATA_NASCIMENTO | datePicker nativo | DATA_DE_NASCIMENTO | dados | não | |
  | P14_EMPRESA | selectOne | ID_EMPRESA | dados | sim | `SELECT NOME d, ID_EMPRESA r FROM EMPRESA ORDER BY NOME` |
  | P14_DEPARTAMENTO | popupLov, cascata de P14_EMPRESA | ID_DEPARTAMENTO | dados | sim | `DEPARTAMENTO WHERE ID_EMPRESA = :P14_EMPRESA` |
  | P14_CARGO | popupLov, cascata de EMPRESA+DEPARTAMENTO | ID_CARGO | dados | sim | `CARGO WHERE ID_DEPARTAMENTO = :P14_DEPARTAMENTO AND ID_EMPRESA = :P14_EMPRESA` |
  | P14_GESTOR | popupLov, cascata de P14_EMPRESA | ID_GESTOR | dados | não | colaboradores da empresa escolhida cujo cargo tem o papel `gestor` em `CARGO_PAPEL` |
  | P14_STATUS | switch, boolean (sessão) | STATUS | status-do-registro | não | |
- **Botões**: `salvar-usuario` (SALVAR_USUARIO, "Salvar Usuario", hot, slot create, `databaseAction: insert`, confirmação warning "Confirmar Cadastro..."); `cancelar` (CANCELAR, slot delete, redireciona para a própria página 14).
- **DA** `new` ("Desabilitar campos caso a empresa não tenha sido selecionada"): change em P14_EMPRESA, condição cliente `itemIsNotNull P14_EMPRESA` → verdadeiro: `enable` DEPARTAMENTO/CARGO/GESTOR (seq 20); falso: `disable` (seq 30).
- **Validação** `validar-confirmação-de-senha`: `RETURN :P14_SENHA = :P14_CONFIRMAR_SENHA;` (alwaysExecute), erro no item P14_CONFIRMAR_SENHA.
- **Processos**: `inicializar-o-form-cadastros` (formInitialization, beforeHeader); `salvar-dados-colaborador` (formAutoRowProcessing, ponto *After Submit* = `ON_SUBMIT_BEFORE_COMPUTATION`, seq 10, msg "Colaborador cadastrado com sucesso!"); `criar-usuario-apex` (executeCode, *After Submit*, seq 20): `APEX_UTIL.CREATE_USER(p_user_name=>:P14_LOGIN, p_email_address=>:P14_EMAIL, p_web_password=>:P14_SENHA, p_first_name=>:P14_PRIMEIRO_NOME, p_last_name=>:P14_ULTIMO_NOME, p_change_password_on_first_use=>'N')`, `WHEN OTHERS` → `raise_application_error(-20000, SQLERRM||backtrace)` (mesma mensagem de sucesso duplicada); `atribuir-papeis-do-cargo` (executeCode, ponto *Processing* = `AFTER_SUBMIT`, seq 30, condição `P14_LOGIN` não nulo): `PKG_PERFIS_ACESSO.ATRIBUIR_PAPEIS(:P14_LOGIN, :P14_CARGO, :APP_ID)`.
- **Branch**: "Limpar formulário após carregamento" (point processing) → página 14 com `clearCache: 14`, `action: clearRegions`.
- **Banco**: COLABORADOR (insert), EMPRESA, DEPARTAMENTO, CARGO, CARGO_PAPEL; `PKG_PERFIS_ACESSO`; APIs `APEX_UTIL.CREATE_USER` e `APEX_ACL` (usuário do workspace — por isso `G_NOME_USUARIO` lê `apex_workspace_apex_users`).
- **Pegadinhas**:
  - Página sem autorização; só a entrada de menu exige `somente-diretoria`.
  - `P14_LOGIN` é obrigatório. Senha e confirmação não são, mas `CREATE_USER` precisa delas; com ambas nulas a validação retorna NULL (`NULL = NULL`) — APEX trata como falha com mensagem enganosa.
  - Os processos 10 e 20 rodam em *After Submit*, **antes** da validação de senha. A confirmar com um teste: senha divergente pode deixar colaborador ou conta criados. A correção seria movê-los para *Processing*.
  - A LOV de Cargo mostra cargos antigos (com colaboradores) e duplicatas novas vazias do seed de perfis de acesso.
  - Os papéis vêm do cargo (`CARGO_PAPEL`). Se um papel de `CARGO_PAPEL` não existir na app, o cadastro inteiro falha com -20102. Trocar o cargo depois não ajusta os papéis.
  - O DA de habilitar/desabilitar depende do comportamento padrão "fire on initialization"; itens desabilitados no cliente não são enviados no submit (se o usuário limpar a empresa).
  - Form só faz insert (não há fluxo de edição; sem link para cá com ID).
  - Mudança não commitada: CARGO, DEPARTAMENTO, EMAIL, EMPRESA e NOME_COMPLETO passaram de `@/optional-floating` para `@/required-floating`; header trocou estilo inline por classes `cx-titulo`/`cx-descricao`.

### Página 15 — Empresas Cadastradas (`p00015-empresas-cadastradas.apx`)
- **Propósito**: listar empresas (tenants) e abrir o modal de cadastro/edição.
- **Regiões**: `breadcrumb`; `empresas-cadastradas` (IR sobre a **tabela** `EMPRESA`, link de linha com ícone `fa-edit` → página 16 com `P16_ID_EMPRESA = #ID_EMPRESA#`, `resetPagination`). Colunas: ID_EMPRESA (hidden, PK), NOME ("Razão Social"), CNPJ, DATA_CRIACAO, NOME_FANTASIA, EMAIL_CORPORATIVO, TELEFONE, CEP, LOGRADOURO, NUMERO, COMPLEMENTO, BAIRRO, CIDADE, UF, STATUS (LOV `@boolean`). Mensagens "no data" em inglês. LOGOTIPO_EMPRESA não exibido.
- **Botão**: `create` ("Cadastrar", hot, slot `rightOfInteractiveReportSearchBar`) → página 16 `clearCache: 16`.
- **DA**: `edit-report-dialog-closed` (`apexafterclosedialog` na região) → refresh do IR.
- **Banco**: EMPRESA.
- **Pegadinhas**: sem autorização na página (menu exige `administration-rights`). Lista todas as empresas (é tela de administrador da plataforma).

### Página 16 — Cadastro de Empresas (`p00016-cadastro-de-empresas.apx`)
- **Propósito**: modal de CRUD da tabela EMPRESA, com autopreenchimento de endereço via ViaCEP.
- **Página**: `pageMode: modalDialog`, `@/modal-dialog`, `chained: false`.
- **Regiões**: `cadastro-de-empresas` (form EMPRESA, `edit.enabled` add/update/delete, @/blank-with-attributes, slot contentBody) com sub-regiões (sem UI, header `<h2 class="cx-titulo-secao">`): `new` "Informações principais" (seq 10), `contato-e-endereço` (seq 40), `configurações` (seq 50); `buttons` (@/buttons-container, slot dialogFooter).
- **Itens** (form `@cadastro-de-empresas`, largura 32): P16_ID_EMPRESA (hidden PK); em "Informações": P16_NOME (Razão Social, req, 200), P16_NOME_FANTASIA (req, 255), P16_CNPJ (req, 20), P16_DATA_CRIACAO (datePicker nativo `YYYY-MM-DD`, req, maxLength 255 sem sentido); em "Contato e endereço": P16_EMAIL_CORPORATIVO (email, lower, req, 255), P16_TELEFONE (phone, req, **max 12**), P16_CEP (req, **max 8** — CEP com hífen tem 9), P16_LOGRADOURO (req, 100), P16_NUMERO (req, **max 4**), P16_COMPLEMENTO (opc, 30), P16_BAIRRO (req, 50), P16_CIDADE (req, 100), P16_UF (req, 2); em "Configurações": P16_STATUS (switch boolean, req), P16_LOGOTIPO_EMPRESA (imageUpload, `storage.type: appTempFiles`, coluna BLOB LOGOTIPO_EMPRESA).
- **Botões**: `cancel` (cancelDialog), `delete` ("Remover", `t-Button--danger`, sem validações, confirmação `&APP_TEXT$DELETE_MSG!RAW.`, só se ID não nulo), `save` ("Salvar", update, só se ID não nulo), `create` ("Criar", insert, só se ID nulo).
- **DAs**:
  - `endereço-por-cep` (keyup em P16_CEP): remove não-dígitos; com 8 dígitos faz `fetch('https://viacep.com.br/ws/${cep}/json/')`, preenche LOGRADOURO, BAIRRO, CIDADE (=localidade), UF; habilita NUMERO e COMPLEMENTO e foca NUMERO; se `data.erro`, `apex.message.showErrors` "CEP não encontrado." e desabilita NUMERO/COMPLEMENTO.
  - `desabilitar-campos-de-endereço` (change em P16_CEP, condição `itemIsNotNull P16_CEP`): verdadeiro → `enable` NOME_FANTASIA, NOME, CNPJ, DATA_CRIACAO, EMAIL_CORPORATIVO, TELEFONE, CEP, STATUS, LOGOTIPO (campos que nunca são desabilitados — ação sem efeito útil); falso → `disable` LOGRADOURO, BAIRRO, CIDADE, UF, NUMERO, COMPLEMENTO.
- **Processos**: `initialize-form-cadastro-de-empresas` (formInitialization, beforeHeader); `process-form-cadastro-de-empresas` (formAutoRowProcessing, seq 10); `close-dialog` (closeDialog, seq 50, quando REQUEST em CREATE,SAVE,DELETE).
- **Banco**: EMPRESA. Serviço externo: ViaCEP (chamado do browser).
- **Pegadinhas**:
  - LOGRADOURO/BAIRRO/CIDADE/UF ficam **desabilitados** mesmo após o ViaCEP preenchê-los (o JS só reabilita NUMERO/COMPLEMENTO). Itens desabilitados pelo APEX não são enviados no submit → risco de "valor obrigatório" ou de gravar nulo. Verificar no browser; correção: usar readonly via JS (`prop('readOnly')`) ou habilitar antes do submit.
  - Na edição de uma empresa existente, a DA de change (com fire-on-init padrão) avalia CEP não nulo → não desabilita; mas em criação tudo de endereço começa desabilitado, inclusive NUMERO/COMPLEMENTO até o ViaCEP responder.
  - `maxLength` de TELEFONE (12), CEP (8) e NUMERO (4) são restritivos para formatos com máscara.
  - `appTempFiles` em item com coluna BLOB de form: o upload vai para `APEX_APPLICATION_TEMP_FILES`; não há processo copiando para `EMPRESA.LOGOTIPO_EMPRESA` → logotipo provavelmente não é salvo (verificar).
  - Mudança não commitada: headers das seções viraram `<h2 class="cx-titulo-secao">`; botão Remover ganhou `t-Button--danger`.

### Página 17 — Emitir Comunicado (`p00017-comunicado.apx`)
- **Propósito**: modal (wizard template, altura 600) para publicar um comunicado.
- **Regiões**: `buttons` (slot wizardButtons); `step-1` "emitir-comunicado" (form sobre `COMUNICADO`, slot wizardBody, title "Emitir novo comunicado").
- **Itens** (form `@step-1`; **todos com `sequence: 10`** → ordem de exibição indefinida/por nome):
  - P17_ID_COMUNICADO (hidden PK, queryOnly).
  - P17_TITULO (textField, req, 200, label "Titulo").
  - P17_CONTEUDO (textarea CLOB, h=5).
  - P17_ID_DEPARTAMENTO (selectList; LOV: departamentos da empresa do usuário logado via subquery `COLABORADOR.login_apex = :APP_USER`).
  - P17_IMAGEM (imageUpload na coluna BLOB IMAGEM, `mimeTypeColumn: MIME_TYPE`, `filenameColumn: NOME_ARQUIVO`).
  - P17_MIME_TYPE, P17_NOME_ARQUIVO (hidden, colunas).
  - P17_DATA_PUBLICACAO (hidden, default expression `SYSDATE;`).
  - P17_ID_AUTOR (hidden, default SQL `SELECT ID_COLABORADOR FROM COLABORADOR WHERE LOGIN_APEX = :APP_USER;`).
  - P17_ID_EMPRESA (hidden, checksum, default SQL `SELECT ID_EMPRESA FROM COLABORADOR WHERE LOGIN_APEX = :APP_USER;`).
- **Botões**: `cancel` (buttonName `cancelar`, cancelDialog); `next` (buttonName `enviar_comunicado`, "Enviar Comunicado", `fa-chevron-right`, insert, showProcessing, confirmação "Certeza que deseja emitir o comunicado?").
- **Processos**: `initialize-form-emitir-comunicado` (formInitialization); `processo-emissao-comunicado` (formAutoRowProcessing, target tabela COMUNICADO, sucesso "Comunicado Publicado com Sucesso!", erro "Não foi possível emitir o comunicado, tente novamente.").
- **Banco**: COMUNICADO (insert), COLABORADOR, DEPARTAMENTO.
- **Pegadinhas**:
  - **Não há processo `closeDialog` nem branch** → após inserir, o modal não fecha (recarrega a si mesmo); a Home não é atualizada.
  - Default `SYSDATE;` com ponto e vírgula em "PL/SQL expression" pode gerar erro de compilação (deveria ser `SYSDATE`). Defaults SQL também terminam com `;`.
  - `buttonName` em minúsculas (`cancelar`, `enviar_comunicado`) — REQUEST será esse nome; a DML automática usa `databaseAction: insert` do botão, então funciona.
  - Template wizard + lista `emitir-comunicado` aponta para páginas 18 e 19 inexistentes (wizard abandonado em 1 passo).
  - P17_ID_DEPARTAMENTO opcional: nulo = "Geral" na Home.
  - Sem autorização na página; só o menu exige `publicador-de-conteudo`, e o botão da Home é livre.
  - P17_TITULO usa `@/optional-floating` apesar de `valueRequired: true`.

### Página 26 — Central de Equipes (`p00026-central-de-equipes.apx`)
- **Propósito**: listar equipes e abrir modal de criação/edição.
- **Regiões**: `navegação-estrutural` (breadcrumb); `central-de-equipes` (classicReport sobre **tabela** `EQUIPE`, @/standard `t-Region--noPadding`, report @/standard com `t-Report--stretch/staticRowColors/rowHighlight/inline/hideNoPagination`). Colunas: ID_EQUIPE (link ícone `fa-edit` → página 27 com `P27_ID_EQUIPE=#ID_EQUIPE#`), ID_EMPRESA (LOV `@empresa-nome`), ID_DEPARTAMENTO (`@departamento-nome`), ID_CRIADOR (`@colaborador-nome-completo`), NOME, DESCRICAO, DATA_CRIACAO, STATUS (`@boolean`). Cabeçalhos são os gerados ("Id Empresa", "Data Criacao" etc.).
- **Botão**: `create` ("Criar", slot `edit`) → página 27 `clearCache: 27`.
- **DA**: `editar-relatório-caixa-de-diálogo-fechada` (`apexafterclosedialog`) → refresh do relatório.
- **Banco**: EQUIPE (+ EMPRESA, DEPARTAMENTO, COLABORADOR via LOVs).
- **Pegadinhas**: sem filtro por empresa (multi-tenant); sem autorização; rótulos não traduzidos/polidos.

### Página 27 — Nova Equipe (`p00027-nova-equipe.apx`)
- **Propósito**: modal CRUD de EQUIPE.
- **Regiões**: `nova-equipe` (form EQUIPE, add/update/delete); `botões` (dialogFooter).
- **Itens**: P27_ID_EQUIPE (hidden PK); P27_ID_EMPRESA (selectList `@empresa-nome`, req); P27_ID_DEPARTAMENTO (selectList `@departamento-nome`, opc); P27_ID_CRIADOR (selectList `@colaborador-nome-completo`, req); P27_NOME (req, 150); P27_DESCRICAO (textarea, 500); P27_DATA_CRIACAO (datePicker, req, maxLength 255); P27_STATUS (switch boolean, req). Labels alinhados à direita, nomes técnicos ("Id Criador").
- **Botões**: `cancel` (cancelDialog), `delete` ("Excluir", danger, confirmação, se ID não nulo), `save` ("Aplicar Alterações", se ID não nulo), `create` ("Criar", se ID nulo).
- **Processos**: formInitialization; formAutoRowProcessing; `fechar-caixa-de-diálogo` (closeDialog quando CREATE,SAVE,DELETE).
- **Pegadinhas**: LOVs não filtradas por empresa nem em cascata (departamento de outra empresa pode ser escolhido); criador escolhido manualmente (deveria ser o usuário logado); data de criação digitada manualmente. Mudança não commitada: botão Excluir ganhou `t-Button--danger`.

### Página 9999 — Login (`p09999-login.apx`)
- Página padrão gerada pelo APEX: `@/login`, `authentication: public`, title "CorlixHub - Log In".
- **Região** `corlixhub` (template @/login, imagem `#APP_FILES#icons/app-icon-512.png`).
- **Itens**: P9999_USERNAME (textField, ícone `fa-user`, `autocomplete="username"`, storage request), P9999_PASSWORD (password, `fa-key`, `autocomplete="current-password"`), P9999_REMEMBER (checkbox, só se `apex_authentication.persistent_cookies_enabled`). Labels em inglês ("Username", "Password", "Remember username").
- **Botão**: `login` (LOGIN, "Sign In", hot).
- **Processos**: `get-username-cookie` (beforeHeader: lê cookie de usuário); `set-username-cookie` (seq 10, `APEX_AUTHENTICATION.SEND_LOGIN_USERNAME_COOKIE(lower(:P9999_USERNAME), :P9999_REMEMBER)`); `login` (seq 20, `APEX_AUTHENTICATION.LOGIN(:P9999_USERNAME, :P9999_PASSWORD, p_set_persistent_auth default)`); `clear-page-s-cache` (seq 30, clearSessionState).
- **Pegadinhas**: textos não traduzidos para PT-BR.

---

## 5. Mudanças não commitadas em `corlixhub/pages` (git diff na branch DEV)

`git diff --stat`: p00001-home (291 linhas), p00004-chat (24), p00014-cadastros-de-usuarios (14), p00016-cadastro-de-empresas (11), p00027-nova-equipe (5). Tema geral: **migração de estilos inline para classes/tokens do novo tema** (`corlix-tema.css`, não commitado, em `shared-components/static-files/`).
- **Home**: (a) corrigido bug em que o bloco `javaScript.fileUrls` continha código JS (com comentários `//` e strings soltas) — substituído por `executeWhenPageLoads` com `carregarCapasComunicados()`; o preenchimento do badge do mês continua via DA. (b) SQLs de aniversariantes passaram de `SYSDATE` para `CAST(SYSTIMESTAMP AT TIME ZONE 'America/Sao_Paulo' AS DATE)` (e ganharam indentação extra). (c) fallbacks `onerror` trocados de `https://dicebear.com` (URL inválida) para `#APP_FILES#default-user.jpeg`. (d) HTML inline com `style=` substituído por classes `cx-cabecalho-card`, `cx-badge cx-badge--info`, `cx-acoes-card`, `cx-pessoa*`, `cx-etiqueta` (no lugar de `cmt-badge &CLASSE_DEPTO.`). (e) SVGs `#4f46e5` → `currentColor`. (f) `B_VER_TODOS`: "Ver Todos"→"Ver todos", template text-with-icon, removido `customAttributes style=...!important`. (g) botão "Emitir Comunicado" → "Novo comunicado" com ícone `fa-plus`. (h) header "MEU GESTOR" → "Meu gestor".
- **Chat**: cores hex das variáveis `--ch-*` trocadas por tokens `--cx-primaria`, `--cx-primaria-suave`, `--cx-tag`, `--cx-borda`, `--cx-superficie-2`, `--cx-texto(-2/-3)`, `--cx-raio-card`.
- **Página 14**: header com classes `cx-titulo`/`cx-descricao`; 5 itens obrigatórios passaram a usar `@/required-floating`.
- **Página 16**: cabeçalhos das seções `<h2 class="cx-titulo-secao">`; botão Remover `t-Button--danger`.
- **Página 27**: botão Excluir `t-Button--danger`.

---

## 6. Mapa de navegação

```
                       [9999 Login] --(APEX_AUTHENTICATION.LOGIN)--> homeUrl = [1 Home]

Global Page 0 (header em todas): sino -> [5 Notificações]   engrenagem -> [6 Configurações]

Menu lateral: 1, 2, 3, 11, 12, 13, 14*, 17**, 15***, 26, 4, 7, Sair(&LOGOUT_URL.)
   * somente-diretoria   ** publicador-de-conteudo   *** administration-rights

[1 Home]
  ├─ botão "Novo comunicado" ──────────────> [17 Emitir Comunicado] (modal; não fecha sozinho)
  ├─ "Ver todos" ──────────────────────────> POPUP_ANIVERSARIANTES (inline dialog na própria página)
  ├─ Link rápido "Holerite Digital" ───────> [5]   (placeholder)
  ├─ Link rápido "Ponto Eletrônico" ───────> [6]   (placeholder)
  ├─ Link rápido "Suporte TI" ─────────────> [7 Monitor de Logs]
  └─ Meu gestor: "Chat"/"E-mail" e link da empresa -> href="#" (mortos)

[15 Empresas Cadastradas] ── "Cadastrar" (clear 16) / ícone editar (P16_ID_EMPRESA) ──> [16 Cadastro de Empresas] (modal)
[16] ── CREATE/SAVE/DELETE ──> closeDialog ──> 15 refresca IR (apexafterclosedialog)

[26 Central de Equipes] ── "Criar" (clear 27) / ícone editar (P27_ID_EQUIPE) ──> [27 Nova Equipe] (modal)
[27] ── CREATE/SAVE/DELETE ──> closeDialog ──> 26 refresca relatório

[14 Cadastro de Usuários] ── submit ──> branch para 14 (clearCache 14) ; "Cancelar" -> 14

[4 Chat] — sem navegação; AJAX (DA) seleciona contato -> P4_CANAL_ID -> refresh msgs

Lista "emitir-comunicado" (wizard): 17 -> 18 -> 19   (18 e 19 NÃO EXISTEM)
Órfãs: [8 Notificações duplicada] (nenhum link). Páginas 2,3,11,12,13 só via menu, sem conteúdo.
```

---

## 7. Tabelas, views e objetos de banco usados pelas páginas

| Objeto | Tipo | Páginas |
|---|---|---|
| COLABORADOR | tabela | 1, 4, 14 (insert), 17 (defaults/LOV), 26/27 (LOV), app processes |
| CARGO | tabela | 1, 4, 14 (LOV), app process APP_USER_CARGO |
| DEPARTAMENTO | tabela | 1, 4, 14, 17, 26/27 (LOV) |
| EMPRESA | tabela | 14 (LOV), 15 (IR), 16 (CRUD), 26/27 (LOV), app process G_NOME_EMPRESA |
| COMUNICADO | tabela | 1 (top 3), 17 (insert) |
| EQUIPE | tabela | 26 (report), 27 (CRUD) |
| PRESENCA_COLABORADOR | tabela | 4 |
| CANAL_MENSAGEM | tabela | 4 |
| CH_GET_CANAL_DIRETO | função | 4 (DA server-side) |
| APP_LOG / LOG_PKG | tabela / package | 7 |
| APEX_WORKSPACE_ACTIVITY_LOG, APEX_DEBUG_MESSAGES, APEX_WORKSPACE_APEX_USERS | views APEX | 7, 7, app process G_NOME_USUARIO |
| APEX_UTIL.CREATE_USER, APEX_AUTHENTICATION.* | APIs APEX | 14, 9999 |

Colunas relevantes inferidas: COLABORADOR(ID_COLABORADOR, NOME_COMPLETO, PRIMEIRO_NOME, ULTIMO_NOME, EMAIL, LOGIN_APEX, DATA_ADMISSAO, DATA_DE_NASCIMENTO, FOTO_URL, ID_EMPRESA, ID_DEPARTAMENTO, ID_CARGO, ID_GESTOR, STATUS boolean); CARGO(ID_CARGO, NOME, ID_DEPARTAMENTO, ID_EMPRESA); DEPARTAMENTO(ID_DEPARTAMENTO, NOME, ID_EMPRESA); EMPRESA(ID_EMPRESA, NOME, NOME_FANTASIA, CNPJ, DATA_CRIACAO, EMAIL_CORPORATIVO, TELEFONE, CEP, LOGRADOURO, NUMERO, COMPLEMENTO, BAIRRO, CIDADE, UF, STATUS boolean, LOGOTIPO_EMPRESA blob); COMUNICADO(ID_COMUNICADO, TITULO, CONTEUDO clob, DATA_PUBLICACAO, IMAGEM blob, MIME_TYPE, NOME_ARQUIVO, ID_DEPARTAMENTO, ID_AUTOR, ID_EMPRESA); EQUIPE(ID_EQUIPE, ID_EMPRESA, ID_DEPARTAMENTO, ID_CRIADOR, NOME, DESCRICAO, DATA_CRIACAO, STATUS boolean); PRESENCA_COLABORADOR(ID_COLABORADOR, DATA_ULTIMO_PING, STATUS_PRESENCA); CANAL_MENSAGEM(ID_CANAL, ID_COLABORADOR, CORPO, DATA_ENVIO, EXCLUIDA boolean); APP_LOG(ID, LOG_TS tstz, NIVEL, APP_ID, PAGE_ID, APEX_USER, SESSION_ID, ORIGEM, MENSAGEM, DETALHE clob).
O DDL dessas tabelas, de `CH_GET_CANAL_DIRETO` e de `LOG_PKG` está em `database/corlix-hub.sql` (snapshot sem dados); detalhes em `05`.

---

## 8. Pegadinhas transversais (checklist para quem for editar)

1. **Autorização só no menu**: nenhuma página tem `authorizationScheme`; 7 (logs), 14 (cria usuários), 15/16 (empresas) e 17 (comunicados) são acessíveis por URL por qualquer usuário autenticado. Para proteger, adicionar `security { authorizationScheme: @... }` na página.
2. **Multi-tenant ausente nas consultas**: quase nenhuma SQL filtra por `ID_EMPRESA` do usuário (exceção: LOV de departamento da página 17).
3. **Duas páginas de Notificações** (5 implementada como placeholder com breadcrumb e alias ASCII `NOTIFICACOES`, usada pelo header; 8 vazia, alias `NOTIFICAÇÕES`, órfã).
4. **Aliases e nomes de arquivo com acento** (8, 13) — cuidado com URLs amigáveis e scripts.
5. Chat: região de mensagens condicionada no servidor + refresh por DA = não funciona; `templateOptions: "[object Object]"`; CAB_DEPT só para admins; sem envio.
6. Modal 17 sem closeDialog; wizard aponta para 18/19 inexistentes; `SYSDATE;` no default.
7. Modal 16: campos de endereço desabilitados (não submetidos); maxLengths curtos; logotipo em `appTempFiles`.
8. Caminhos de foto divergentes: `#APP_FILES#fotos/` vs `#APP_FILES#Fotos Colaboradores/`.
9. Links mortos/placeholder: busca global sem JS, `href="#"` (gestor, empresa), links rápidos apontando para 5/6/7.
10. Comparações de `LOGIN_APEX` ora com `UPPER`, ora sem (Home gestor, 17, lado do chat) — padronizar `UPPER(TRIM(login_apex)) = UPPER(:APP_USER)`.
11. Templates de página misturados: `@/standard` (1, 2, 3, 8, 11, 12, 13, 14, 15) vs `@corlix-standard-page` (4, 5, 6, 7, 26) — o header da Global Page usa slots `afterLogo`/`afterNavigationBar` definidos no template customizado.
12. Ao editar `.apx`: preservar `executionMappingIdentifier`/`savedReportMappingIdentifier`, manter escape `\#COL#\` em targets, uma opção por linha em listas, e blocos de código cercados com a linguagem correta (`javascript-browser`, não `javascript`).

# 06 · Módulos de feature (`modulos/`)

> Escopo: os módulos desenvolvidos **fora do App Builder** (SQL/PL/SQL + CSS + JS + guia `Etapas-*.md` de montagem da página). Schema/tabelas em detalhe: ver `05-banco-de-dados.md`. Tokens `--cx-*`, `corlix-tema.css` e o padrão visual: ver `04-tema-e-estilos.md`.
> Estado conferido em 2026-10-06 (branch `DEV`).

## Visão geral

| Pasta | Situação no Git | Página APEX alvo | Integrada no app? |
|---|---|---|---|
| `modulos/organograma/` | versionada (commit `bac2d69`), **com mudanças não commitadas** (+774/−80 linhas: drawer de detalhes) | p. 3 `Organograma` (`corlixhub/pages/p00003-organograma.apx`) | **Não.** A página só tem a região Breadcrumb |
| `modulos/historico-carreira/` | **untracked** | p. 13 `Histórico de carreira` (`p00013-histórico-de-carreira.apx`) + páginas novas 18–23 | **Não.** A página 13 só tem a região Breadcrumb; páginas 18–23 não existem |
| `modulos/tema/` | **untracked** | todas (tema global) | documentado em `04-tema-e-estilos.md` |
| `modulos/perfis-acesso/` | **untracked** | p. 14 `Cadastro de Usuários` | **Sim** na app (papéis `colaborador`/`gestor`/`admin-rh`, authorization `ADMIN_RH`, processo e LOV de gestor na P14); o SQL (`instalar.sql`) precisa ser rodado no banco. Guia: `Etapas-perfis-acesso.md` |

Também não há rastro dos objetos dos módulos em `database/f100.sql` (nenhuma ocorrência de `vw_org_colaborador`, `pkg_organograma`, `historico_carreira`, `tipo_movimentacao`, `G_ID_EMPRESA`), nem nos shared components (`app-items.apx` só tem `APP_USER_CARGO`, `APP_USER_FOTO`, `APP_USER_NOME`, `G_NOME_EMPRESA`, `G_NOME_USUARIO`; não existem `G_ID_EMPRESA`, `ID_COLABORADOR`, o processo `DOWNLOAD_FOTO`, nem os authorization schemes `GESTOR`/`COLABORADOR`). O papel `Admin RH` e a authorization `ADMIN_RH` foram criados pelo módulo `perfis-acesso`.

### Padrão arquitetural comum ("Dynamic Content renderizado por PL/SQL")

```
Tabelas existentes (COLABORADOR, CARGO, DEPARTAMENTO, EMPRESA, COMUNICADO)
   └─ view(s) do módulo (filtro/joins)          ex.: vw_org_colaborador, vw_movimentacao_valida
        └─ package *_UI / render  → CLOB de HTML (escapado com apex_escape)
             └─ Região APEX "Dynamic Content" (template Blank with Attributes, Static ID fixo,
                Source = PL/SQL Function Body returning CLOB, Page Items to Submit = item de foco)
                  ├─ CSS do módulo (Static Application File ou CSS Inline), escopado num prefixo (.org / .hc)
                  └─ JS do módulo em blocos: Function and Global Variable Declaration /
                     Execute when Page Loads / Dynamic Actions; eventos delegados via data-*,
                     apex.region(id).refresh() e apex.server.process(<Ajax Callback>)
```

Por que: os layouts dos protótipos (Figma em `figma/`) não cabem nos templates do Universal Theme; HTML gerado no servidor evita bibliotecas externas (o organograma abandonou a OrgChart JS e sua questão de licença) e mantém regras de visibilidade no banco.

Convenções de geração de HTML (idênticas nos dois packages): CLOB temporário global `g_html` + `inicia` / `p(texto)` (`dbms_lob.writeappend`); `e()` = `apex_escape.html`, `a()` = `apex_escape.html_attribute`; ícones Lucide inline (SVG stroke, `currentColor`, `aria-hidden`); textos com entidades HTML (`&atilde;`, `&middot;`) ou `unistr`; datas por extenso com `NLS_DATE_LANGUAGE='BRAZILIAN PORTUGUESE'`; URLs via `apex_page.get_url` (gera checksum); iniciais = 1ª letra do primeiro nome + 1ª do último sobrenome.

---

## 1. Organograma

### 1.1 Objetivo e regras de negócio

Navegação **por níveis** na hierarquia de gestão (`COLABORADOR.ID_GESTOR`): uma pessoa em foco, o caminho até o topo (breadcrumb) e os subordinados diretos em cards. Clique no card abre um **drawer** de detalhes (redesign em `Organograma — redesign (navegação por níveis).png` e `Organograma · detalhes da pessoa (Drawer) — redesign.png`).

- Só **contas ativas** aparecem (`colaborador.status = true`; `STATUS` nulo/false = inativo). Se um gestor fica inativo, os subordinados dele somem da navegação até serem realocados.
- Sem foco (ou foco inválido/inativo) → abre no **topo**: `id_raiz` = `min(id_colaborador)` ativo sem gestor.
- Card em foco: avatar, nome, "cargo · departamento", tag "Topo da hierarquia" (se sem gestor), resumo "N subordinados diretos · M pessoas na estrutura" (M = todos os descendentes ativos, `connect by`), botões "Ver perfil" (abre o drawer) e "Conversar" (oculto se a pessoa é o próprio `APP_USER`, comparando `login_apex`).
- Cards dos filhos (ordem alfabética): prévia da equipe com até 3 avatares/nomes; acima disso "+N" e "e mais N"; "Sem equipe direta" se 0; botão "Ver equipe" desce um nível.
- Avatar: `FOTO_URL` se houver; senão BLOB (`IMAGEM_PERFIL`) via `APPLICATION_PROCESS=DOWNLOAD_FOTO` com item `ID_COLABORADOR`; senão iniciais.
- Drawer: Contato (e-mail `mailto` + botão copiar com ✓ por 2 s), Na estrutura ("Reporta-se a" gestor ou "Topo da hierarquia"/"Gestor inativo ou não encontrado"; "Equipe direta" até `c_max_equipe` = 8, depois "e mais N na equipe"; "Ver equipe no organograma"), Sobre (Departamento, Empresa, "Na Corlix desde" = "fevereiro de 2026 · 7 meses" a partir de `DATA_ADMISSAO`, ou "admissão em ..." se futura; Aniversário só dia e mês), nota de privacidade, rodapé "Conversar" + "Ver perfil completo".
- **Privacidade:** a nota diz "você vê só os dados visíveis para todos", mas hoje e-mail, admissão e aniversário aparecem para qualquer usuário logado. Sugestão do guia: flag de visibilidade no cadastro.

### 1.2 Arquitetura

| Camada | Artefato | Detalhes |
|---|---|---|
| View | `vw_org_colaborador` | `colaborador` ⨝ `cargo` ⨝ `departamento`, `where c.status = true`. Colunas: `id_colaborador, id_gestor, nome_completo, email, login_apex, data_admissao, data_de_nascimento, cargo, departamento, foto_url, tem_imagem ('S'/'N')` |
| Package | `pkg_organograma` | Constantes: `c_nome_empresa = 'Corlix'`, `c_pagina_perfil = 20` / `c_item_perfil = 'P20_ID_COLABORADOR'`, `c_pagina_chat = 30` / `c_item_chat = 'P30_ID_COLABORADOR'` (**placeholders**), `c_max_equipe = 8`. Públicas: `id_raiz`, `render(p_id_foco, p_nome_empresa default c_nome_empresa) return clob`, `render_detalhes(p_id, p_nome_empresa) return clob`. Privadas: `render_caminho`, `render_foco`, `render_filhos`, `avatar`, `linha_pessoa`, `dado`, `tempo_de_casa`, `aniversario`, `eh_usuario_atual` (usa `v('APP_USER')`) |
| Região | Dynamic Content, Static ID `organograma` | Source `return pkg_organograma.render(to_number(:P10_ID_FOCO default null on conversion error));` |
| Ajax Callback | `ORG_DETALHES` | `apex_util.prn(p_clob => pkg_organograma.render_detalhes(to_number(apex_application.g_x01 default null on conversion error)), p_escape => false);` |
| Front | `organograma.css` (escopo `.org` e `.org-drawer`), `organograma.js` (3 blocos) | drawer = `<dialog>` nativo criado pelo JS |

Arquivo SQL único: `modulos/organograma/organograma.sql` (view + spec + body). A versão anterior (commitada) não tinha `render_detalhes`; recebia o nome da empresa como 2º argumento obrigatório e "Ver perfil" era link direto para a página de perfil.

### 1.3 Passo a passo de integração (resumo fiel de `Etapas-organograma.md`)

O guia usa **página 10** — no app real a página é a **3** (troque `P10_` → `P3_`; o histórico de carreira já espera `P3_ID_FOCO`).

Remover da versão antiga (se existir): URLs da OrgChart JS, região `painel-detalhes`, DA de Page Load, processos `GET_ORGANOGRAMA` e `GET_DETALHES_SETOR`, função `fn_organograma_json`. Pode manter `DOWNLOAD_FOTO`; tabela `departamento_metrica` e coluna `id_lider` ficaram sem uso.

1. **Banco:** rodar `organograma.sql` (cria/recria view e package). Reexecutar após cada mudança.
2. **Itens:** `P10_ID_FOCO` Hidden, *Value Protected = No* (o JS altera). `P10_BUSCA` Popup LOV, placeholder "Buscar pessoa no organograma", label oculto, na região de título alinhado à direita; LOV:
   `select nome_completo || ' — ' || cargo d, id_colaborador r from vw_org_colaborador order by nome_completo`
3. **Região de título:** template de título Redwood, "Organograma" / "Estrutura da Corlix a partir das relações de gestão."
4. **Região principal:** Dynamic Content · Static ID `organograma` · Template *Blank with Attributes* · Page Items to Submit `P10_ID_FOCO` · Source acima.
5. **Processo** `ORG_DETALHES`: Execute Code, ponto *Ajax Callback* (código acima).
6. **CSS:** `organograma.css` como Static Application File (`#APP_FILES#organograma.css`) ou CSS Inline.
7. **JS:** bloco 1 → *Function and Global Variable Declaration*; bloco 2 → *Execute when Page Loads*; bloco 3 → DA *Change* em `P10_BUSCA` → Execute JavaScript Code.
8. **Ajustar constantes** do package (`c_pagina_perfil/c_item_perfil`, `c_pagina_chat/c_item_chat`, `c_nome_empresa`) e reexecutar o SQL.
9. **Fotos BLOB:** criar Application Item `ID_COLABORADOR` + Application Process `DOWNLOAD_FOTO` (não existem no app hoje).

Deep-link previsto: `...:P10_ID_FOCO:<id>`. Atenção: a página 3 tem `pageAccessProtection: argumentsMustHaveChecksum`, então só URLs geradas com checksum (`apex_page.get_url`) funcionam.

### 1.4 API JavaScript (`organograma.js`)

Constantes: `ORG_ITEM_FOCO = "P10_ID_FOCO"`, `ORG_REGIAO = "organograma"`, `ORG_PROCESSO_DETALHES = "ORG_DETALHES"`. Estado: `orgDrawer` (dialog singleton), `orgPedido` (contador para descartar respostas atrasadas).

| Função | Faz |
|---|---|
| `orgId(valor)` | converte para número > 0 ou `null` |
| `orgIrPara(id)` | `apex.item(ORG_ITEM_FOCO).setValue(id)` + `apex.region(ORG_REGIAO).refresh()` (só a região, sem recarregar a página) |
| `orgObterDrawer()` | cria uma vez `<dialog class="org-drawer" aria-labelledby="org-drawer-nome"><div class="org-drawer__painel">` no `body`, com listener `orgCliqueNoDrawer` |
| `orgAbrirDetalhes(id)` | mostra spinner (`aria-busy`), `showModal()`, chama `apex.server.process("ORG_DETALHES", {x01: id}, {dataType: "text"})`; `done` → injeta HTML e foca `#org-drawer-nome`; `fail` → estado de erro com "Tentar novamente"/"Fechar" |
| `orgCopiar(botao)` | `navigator.clipboard.writeText(data-valor)`, classe `is-copiado` por 2 s, anuncia em `.org-sr` (`aria-live`) |
| `orgCliqueNoDrawer(ev)` | clique no backdrop fecha; delegação por `data-acao`: `fechar`, `detalhe` (troca conteúdo sem fechar), `equipe` (fecha + `orgIrPara`), `copiar` |

Execute when Page Loads: `$("#organograma").on("click", "[data-acao]")` → `foco` ⇒ `orgIrPara`, `detalhe` ⇒ `orgAbrirDetalhes`; `$("#organograma").on("apexafterrefresh")` → foca `#org-foco-nome` (`preventScroll`). DA de busca: `orgIrPara($v("P10_BUSCA"))` e limpa o item com `setValue("", null, true)` (suppressChangeEvent).

Contrato HTML↔JS: atributos `data-acao` ∈ {`foco`, `detalhe`, `equipe`, `fechar`, `copiar`} + `data-id` / `data-valor`. Esc, foco preso e scrim vêm do `<dialog>` nativo.

### 1.5 HTML gerado e classes CSS

```
div.org
 ├─ nav.org-caminho[aria-label] > svg + ol > li > (button.org-link[data-acao=foco] | span[aria-current=page]) ; li > span.org-caminho__sep
 ├─ div.org-arvore
 │   ├─ section.org-foco > div.org-foco__id > span.org-avatar.org-avatar--lg + div.org-foco__texto(h2#org-foco-nome.org-foco__nome[tabindex=-1], p.org-foco__cargo) + span.org-tag
 │   │                   p.org-foco__resumo ; div.org-foco__acoes > button.org-btn[data-acao=detalhe] + a.org-btn (Conversar)
 │   ├─ div.org-conectores.org-conectores--um|--varios[aria-hidden]
 │   └─ ul.org-filhos(.org-filhos--um) > li.org-card
 │        ├─ div.org-card__id > avatar--md + div.org-card__texto(button.org-card__nome[data-acao=detalhe], p.org-card__cargo)
 │        └─ div.org-card__equipe > (p.org-card__sem | div.org-avatares(avatar--sm…, .org-avatar--mais) + div.org-card__equipe-texto(span.org-card__rotulo, span.org-card__nomes) + button.org-ver-equipe[data-acao=foco])
 │   (ou p.org-vazio "… não tem subordinados diretos.")
 └─ p.org-ajuda
dialog.org-drawer > div.org-drawer__painel >
   header.org-drawer__cab (avatar--lg, div.org-drawer__ident > h2#org-drawer-nome.org-drawer__nome + p.org-drawer__cargo, button.org-icone-btn[data-acao=fechar])
   div.org-drawer__corpo > section.org-secao (h3.org-secao__titulo)
       Contato: div.org-contato > svg + div.org-campo(span.org-campo__rotulo, a.org-campo__valor) + button.org-icone-btn.org-copiar[data-acao=copiar](.org-ico-copiar/.org-ico-ok) + span.org-sr
       Na estrutura: div.org-grupo > ul.org-lista > li > button.org-linha[data-acao=detalhe](avatar--row, span.org-linha__texto > .org-linha__nome/.org-linha__sub, chevron) ; p.org-grupo__vazio ; p.org-grupo__mais ; button.org-ver-equipe[data-acao=equipe]
       Sobre: dl.org-dados > div > dt/dd
       p.org-privacidade
   footer.org-drawer__rodape > a.org-btn.org-btn--auto (+ .org-btn--primario "Ver perfil completo")
   (estados: div.org-drawer__estado com span.org-spinner)
```

CSS: tokens `--org-*` declarados em `.org, .org-drawer`, lendo `--cx-*` do `corlix-tema.css` com fallback (`var(--cx-primaria, #00688C)` etc.); variantes de avatar `--lg 56px / --md 48px / --row 36px / --sm 30px`; o card inteiro é clicável via `.org-card__nome::after { position:absolute; inset:0 }` e "Ver equipe" fica acima com `z-index:1`; foco de teclado do card via `:has(.org-card__nome:focus-visible)`; conectores com `::before/::after`; drawer lateral com animação (desligada em `prefers-reduced-motion`), `::backdrop` rgba; breakpoint `max-width: 760px` (1 coluna, sem barra horizontal dos conectores).

### 1.6 Status

Feito (nos arquivos do módulo): view, package com `render` + `render_detalhes`, CSS e JS do redesign + drawer, guia. Pendente: **nada montado na página 3**; criar itens/região/callback; ajustar `P10_`→`P3_` (JS e Source); apontar `c_pagina_perfil`/`c_pagina_chat` para páginas reais; criar `ID_COLABORADOR`/`DOWNLOAD_FOTO`; commitar as mudanças locais; flag de privacidade (opcional); filtro por empresa (ver pegadinhas).

### 1.7 Pegadinhas

- **Sem isolamento multi-tenant:** `vw_org_colaborador` e `id_raiz` **não filtram por `id_empresa`**. Com mais de uma empresa no schema, o "topo" é o menor ID global e a LOV de busca lista todos. O histórico de carreira resolve isso com `G_ID_EMPRESA`; o organograma precisa do mesmo filtro (ex.: `and c.id_empresa = to_number(sys_context('APEX$SESSION', ...))`/`v('G_ID_EMPRESA')` ou parâmetro).
- `c_nome_empresa` é constante "um app por cliente" — o app já tem `G_NOME_EMPRESA`; considerar usá-lo.
- `c_pagina_perfil = 20` **colide** com a página 20 "Dashboard RH" planejada pelo histórico de carreira. O perfil existente é a p. 2 (Meu Perfil, sem item de ID); o chat é a p. 4, que usa `P4_CONTATO_ID`/`P4_CANAL_ID` setados por DA de clique — confirme se aceita deep-link antes de apontar `c_item_chat`.
- Mais de 2 subordinados: cards quebram em linhas de 2 e os conectores só ligam a primeira linha.
- `P10_ID_FOCO` precisa de *Value Protected = No* e estar em *Page Items to Submit*; senão o refresh ignora a troca de foco.
- O Ajax Callback devolve HTML cru (`p_escape => false`); todo dado já é escapado no package — mantenha `e()`/`a()` ao editar.
- `render_detalhes` não verifica permissão; qualquer sessão pode pedir qualquer `x01`.

---

## 2. Histórico de Carreira

### 2.1 Objetivo e regras de negócio

Trajetória profissional de cada colaborador (admissão, promoção, mudança de cargo, transferência, mudança de gestão, efetivação de contrato, mérito, jornada, afastamento/retorno, desligamento, readmissão) + formações/certificações, exibida em linha do tempo (protótipo "Histórico de carreira — nova página"). O histórico é **fonte de verdade do RH e imutável**: efetivado não se altera nem exclui; correção = **estorno + novo lançamento**.

- Ciclo de vida: `RASCUNHO` (`registrar_movimentacao` / `atualizar_rascunho` / `excluir_rascunho`) → `EFETIVADO` (`efetivar_movimentacao`, atualiza `COLABORADOR`: cargo, departamento, gestor, status) → `ESTORNADO` (`estornar_movimentacao` cria um lançamento de estorno `EFETIVADO` com `ID_REGISTRO_ESTORNADO` e restaura a situação anterior). Só a **última** movimentação válida pode ser estornada.
- "Movimentação válida" = efetivada, não estornada e que não é estorno (`VW_MOVIMENTACAO_VALIDA`).
- Snapshot completo (anterior e novo, inclusive `ID_GESTOR_ANTERIOR`) gravado na efetivação.
- Bloqueios: data retroativa à última efetivada; data além de `qt_dias_futuro` (padrão 30); antes da admissão; após desligamento; cargo de outro departamento; objetos de outra empresa. Erros `-20001..-20019` (constantes `c_err_*` na spec), traduzidos por `fn_tratar_erro`.
- Readmissão = `ADMISSAO` após `DESLIGAMENTO` (reativa `STATUS`, atualiza `DATA_ADMISSAO`). Desligamento grava `STATUS = false` → some do organograma.
- "Hoje" no fuso da empresa (`fn_hoje`, `CONFIG_CARREIRA.DS_FUSO_HORARIO`, padrão `America/Sao_Paulo`) — o ADB roda em UTC.
- Comunicado automático (admissão, readmissão, promoção, transferência) em `COMUNICADO` para o departamento destino, mesma transação; nunca menciona salário; desligável por `FL_COMUNICADO_AUTOMATICO`.
- Perfis: `ADMIN_RH` vê/altera tudo da empresa (salário com log em `LOG_ACESSO_SALARIAL`, transação autônoma); `GESTOR` vê a equipe em qualquer nível abaixo, sem mérito e sem motivo de afastamento; `COLABORADOR` vê o próprio histórico (inclusive mérito) e pode **solicitar correção** (`SOLICITACAO_CORRECAO`).
- Multi-tenant por Application Item `G_ID_EMPRESA` (não VPD), em 3 camadas: queries filtram `:G_ID_EMPRESA`; o package recusa objetos de outra empresa; em sessão APEX confere a empresa contra `G_ID_EMPRESA` (sessão sem empresa é bloqueada).
- Package **não faz commit** (APEX comita no fim do request: salvar+efetivar é uma transação só).
- Triggers só de auditoria (`DT_`/`USR_`, `LOG_AUDITORIA_CARREIRA`, bloqueio de UPDATE/DELETE direto em efetivado — erro `-20013`).

### 2.2 Arquitetura e arquivos

| Ordem | Arquivo | Conteúdo |
|---|---|---|
| — | `instalar.sql` | roda tudo no SQLcl (`whenever sqlerror exit failure rollback`), lista inválidos no fim |
| 00 | `00_verificar_schema.sql` | exige 23ai e confere colunas reaproveitadas (`EMPRESA`, `DEPARTAMENTO`, `CARGO`, `COLABORADOR`, `COMUNICADO`) |
| 01 | `01_ddl_historico_carreira.sql` | `config_carreira`, `tipo_movimentacao`, `historico_carreira`, `formacao_colaborador`, `solicitacao_correcao`, `log_acesso_salarial`, `log_auditoria_carreira` (`create table if not exists`) |
| 02 | `02_seed_tipo_movimentacao.sql` | `prc_seed_tipo_movimentacao` + 11 códigos: `ADMISSAO, PROMOCAO, MUDANCA_CARGO, MUDANCA_GESTOR, TRANSFERENCIA_DEPTO, EFETIVACAO_CONTRATO, MERITO, ALTERACAO_JORNADA, AFASTAMENTO, RETORNO, DESLIGAMENTO` (por empresa, `MERGE ... USING (VALUES ...)`) |
| 03 | `03_views_carreira.sql` | `fn_carreira_ve_salario`, `vw_movimentacao_valida`, `vw_historico_carreira` (salário nulo p/ não-RH), `vw_carreira_timeline`, `vw_situacao_atual_colaborador` |
| 04 | `04_pkg_historico_carreira.pks/.pkb` | regras de negócio (API abaixo) |
| 08 | `08_pkg_historico_carreira_ui.sql` | `pkg_historico_carreira_ui.render` → HTML da p. 13 (instalado como "04b", antes das triggers) |
| 05 | `05_triggers_auditoria.sql` | `trg_*_aud` / `trg_*_log` |
| 06 | `06_carga_inicial.sql` | admissão para colaboradores existentes (sem comunicado) |
| 07 | `07_testes.sql` | 2 empresas, 10 colaboradores, teste por regra e isolamento; termina em rollback |
| front | `historico-carreira.css` (p. 13), `historico-carreira-pagina.js` (p. 13), `historico-carreira.js` (modal p. 18) | |

Instalação: `cd modulos/historico-carreira && sql <usuario>@<servico> @instalar.sql`.

**API PL/SQL (`pkg_historico_carreira`)**: `fn_hoje(id_empresa)`, `fn_data_local(id_empresa, ts)`, `fn_id_tipo(id_empresa, cd)`, `registrar_movimentacao(...) return id`, `atualizar_rascunho`, `excluir_rascunho`, `efetivar_movimentacao(id)`, `estornar_movimentacao(id, motivo)`, `registrar_admissao_automatica(id_colaborador)`, `solicitar_correcao(...) return id`, `responder_solicitacao(id, st, resposta)`, `fn_periodo`, `fn_tempo_no_cargo`, `fn_tempo_de_casa`, `fn_pode_ver_colaborador(id) return 'S'|'N'` (RH; o próprio; gestor de qualquer nível acima via `connect by`; fora de sessão APEX = 'S'), `registrar_acesso_salarial(id, contexto)`, `fn_empresa_contexto`, `definir_empresa_contexto`, `fn_tratar_erro(apex_error.t_error)`. Constantes: `c_st_rascunho/efetivado/estornado`, `c_auth_admin_rh = 'ADMIN_RH'`, `c_dias_futuro_padrao = 30`, `c_fuso_padrao`.

**`pkg_historico_carreira_ui`** (`authid definer`), constantes de destino (página nula ⇒ link some):

| Constante | Padrão |
|---|---|
| `c_pagina_organograma` / `c_item_organograma` | 3 / `P3_ID_FOCO` |
| `c_pagina_comunicado` / `c_item_comunicado` | 11 / null (abre a lista) |
| `c_pagina_holerite` | null (link "Ver holerite" oculto) |
| `c_pagina_solicitacao` / `c_item_solicitacao` | 22 / `P22_ID_COLABORADOR` |
| `c_pagina_painel_rh` | 20 |

`render(p_id_colaborador)`: valida `fn_pode_ver_colaborador` (senão `-20012`); lê colaborador + empresa (`nvl(nome_fantasia, nome)`); `g_proprio` (login = `APP_USER`), `g_rh` (`apex_authorization.is_authorized('ADMIN_RH')` ou fora do APEX); situação atual de `vw_situacao_atual_colaborador` com fallback ao cadastro; cursor `c_eventos` = `union all` de `MOV` (historico efetivado/estornado + joins de nomes, início do cargo anterior, desligamentos anteriores), `DEV` (formações) e `MARCO` (aniversários de casa, 1 por ano completo); filtra `MERITO` para quem não é o próprio nem RH; motivo de `AFASTAMENTO/RETORNO` oculto para terceiros não-RH. Nunca exibe salário.

### 2.3 Passo a passo de integração (resumo fiel de `Etapas-historico-carreira.md`)

Pré-requisito: `instalar.sql`. Depois de montar no Builder, exportar em APEXlang para `corlixhub/pages/`. Páginas: 13 (existe, vazia), 18 Movimentação (modal), 19 Formações, 20 Dashboard RH, 21 Anexo da formação (modal), 22 Solicitar correção (modal), 23 Responder solicitação (modal). Se o número estiver ocupado, trocar prefixos no Builder, no `historico-carreira.js` e nas constantes do `08_`.

**1. Shared Components**
- App Item `G_ID_EMPRESA` (Restricted – may not be set from browser) + App Process `SET_G_ID_EMPRESA` (*After Authentication*): `select id_empresa into :G_ID_EMPRESA from colaborador where upper(trim(login_apex)) = upper(trim(:APP_USER))` (null em no_data_found/too_many_rows). Sessões abertas precisam relogar.
- Role `Admin RH` (Static ID `ADMIN_RH`); Authorization Schemes **com estes nomes exatos**: `ADMIN_RH` (Is In Role), `GESTOR` (tem ≥1 subordinado direto na empresa), `COLABORADOR` (é RH ou tem cadastro na empresa) — todos *Once per session*.
- Erros: no `log_pkg.apex_error_handler`, delegar `ora_sqlcode between -20099 and -20001` para `pkg_historico_carreira.fn_tratar_erro` (opção A) ou usar essa função como Error Handling das p. 18/19/21 (opção B).
- LOVs: `LOV_TIPO_MOVIMENTACAO`, `LOV_DEPARTAMENTO_EMPRESA`, `LOV_COLABORADOR_ATIVO` (todas filtram `:G_ID_EMPRESA`), `LOV_TIPO_FORMACAO` estática (`GRADUACAO, POS, MBA, CURSO, CERTIFICACAO, IDIOMA`).

**2. Página 13**
- Authorization `COLABORADOR`; item `P13_ID_COLABORADOR` Hidden, Value Protected, *Checksum Required – Session Level*; **remover** a região Breadcrumb (título e "Exportar PDF" vêm na região).
- Before Header: (10) colaborador padrão = o próprio usuário; (20) validar acesso (`fn_pode_ver_colaborador = 'N'` ⇒ `-20012`); (30, auth `ADMIN_RH`) `registrar_acesso_salarial(..., 'P13 · lançamentos do histórico')`.
- CSS `#APP_FILES#historico-carreira#MIN#.css` (subir também `.min.css`) ou inline; JS `historico-carreira-pagina.js` bloco 1/bloco 2; page template Standard, *Remove Body Padding* se houver.
- Região **Dynamic Content**, Static ID **`historico_carreira`**, *Blank with Attributes*, Source `return pkg_historico_carreira_ui.render(:P13_ID_COLABORADOR);`, Page Items to Submit `P13_ID_COLABORADOR`.
- Região "Lançamentos (RH)": Interactive Report sobre `vw_historico_carreira` (auth `ADMIN_RH`, collapsible fechada); colunas de salário com condição `ADMIN_RH`; `ID_HISTORICO_CARREIRA` como link para p. 18 (`P18_ID_HISTORICO_CARREIRA`, `P18_ID_COLABORADOR`).
- Buttons Container (auth `ADMIN_RH`): `NOVA_MOVIMENTACAO` → p. 18; `FORMACOES` → p. 19.
- DA "Atualizar depois da modal": *Dialog Closed* em `document` → Refresh das duas regiões.

**3. Página 18 (modal, `ADMIN_RH`)** — Form sobre `VW_HISTORICO_CARREIRA`, **sem** Automatic Row Processing. Itens: `P18_ID_HISTORICO_CARREIRA`, `P18_ID_COLABORADOR` (checksum), `P18_ST_REGISTRO` (display, default RASCUNHO), `P18_FL_ESTORNO`, `P18_CD_TIPO` (Hidden, Value Protected **No**), `P18_ID_DEPARTAMENTO_ATUAL`, `P18_ID_TIPO_MOVIMENTACAO`, `P18_DT_EFETIVA` (`DD/MM/YYYY`), `P18_NM_CARGO_ANTERIOR`, `P18_NM_DEPARTAMENTO_ANTERIOR`, `P18_ID_DEPARTAMENTO_NOVO`, `P18_ID_CARGO_NOVO` (cascading LOV pai `P18_ID_DEPARTAMENTO_NOVO`, submit `P18_ID_DEPARTAMENTO_ATUAL`, Parent Required No), `P18_ID_GESTOR_NOVO`, `P18_VL_SALARIO_ANTERIOR/NOVO` (condição `ADMIN_RH`), `P18_DS_MOTIVO`, `P18_DS_OBSERVACAO`, `P18_DS_MOTIVO_ESTORNO`. Read Only quando `ST_REGISTRO <> 'RASCUNHO'`. DA "Tipo mudou" (Change em `P18_ID_TIPO_MOVIMENTACAO`): Set Value SQL → `P18_CD_TIPO`; depois `carreira.ajustarCampos(true);`. Botões `CANCELAR`, `EXCLUIR`, `SALVAR_RASCUNHO`, `EFETIVAR` (Hot, confirmação), `ESTORNAR` (Danger). Processos: Salvar (request in `SALVAR_RASCUNHO,EFETIVAR` → `registrar_movimentacao` ou `atualizar_rascunho`), Efetivar, Estornar, Excluir rascunho, Close Dialog. Before Header com log salarial quando há ID.

**4. Página 19 / 21** — IG de formações (`formacao_colaborador`, DML nativo permitido; coluna `DS_ALERTA_VALIDADE` "VENCIDA"/"A VENCER" em 60 dias, highlights salvos no relatório Primary); anexo em modal 21 (File Upload em BLOB `BL_ANEXO`, `DS_MIME_TYPE`, `DS_NOME_ARQUIVO`; validação de empresa).

**5. Página 20 Dashboard RH** — `P20_DT_INICIO/FIM`; gráficos: promoções por departamento, turnover admissões × desligamentos por mês, tempo médio no cargo; relatório de certificações a vencer; IR de solicitações abertas com link "Responder" (modal 23 → `responder_solicitacao`).

**6. Página 22** — modal "Solicitar correção" (`P22_ID_COLABORADOR` checksum, `P22_ID_HISTORICO_CARREIRA` opcional, `P22_DS_MENSAGEM`) → `solicitar_correcao`; o package confere que quem pede é o próprio.

**7. Ligações:** p. 14 processo "Registrar admissão" (seq. 15, após "Salvar Dados Colaborador") → `registrar_admissao_automatica(:P14_ID_COLABORADOR)` + botão "Histórico de carreira"; p. 12 coluna-link "Histórico"; p. 2 botão "Meu histórico"; menu "Histórico de carreira" e "Dashboard RH". Checklist de teste no item 8 do guia.

### 2.4 API JavaScript

**`historico-carreira-pagina.js` (p. 13, namespace `hc`)** — puramente client-side, sem chamadas ao servidor (abas e ano filtram no DOM):

| Função | Faz |
|---|---|
| `hc.plural(n)` | "1 registro" / "N registros" |
| `hc.filtrar(raiz)` | lê aba `[role=tab][aria-selected=true]` (`data-hc-filtro` = `tudo|mov|dev`) e `select[data-hc-ano]`; seta `hidden` em `.hc-evento` (por `data-grupo`/`data-ano`), marca último visível `.is-ultimo`, recalcula `.hc-ano__qt`, esconde anos vazios, `.is-primeiro`, mostra `[data-hc-sem-resultado]` |
| `hc.iniciar()` | idempotente (`hc.iniciado`); listeners **delegados no `document`** (sobrevivem ao refresh): click em aba / `[data-hc-acao=exportar]` (`window.print()`), change em `[data-hc-ano]`, setas ←/→ entre abas (WAI-ARIA tablist), `beforeprint/afterprint` mostram tudo e restauram (`data-hc-oculto`) |
| `hc.preparar()` | aplica `hc.filtrar` a cada `[data-hc]` |

Page Load: `hc.iniciar(); hc.preparar(); $("#historico_carreira").on("apexafterrefresh", hc.preparar);`

**`historico-carreira.js` (modal p. 18, namespace `carreira`)** — `carreira.visivelEm` / `carreira.obrigatorioEm` / `carreira.itens` mapeiam grupos (`cargo`, `departamento`, `gestor`, `salario`) → códigos de tipo → itens P18. `carreira.ajustarCampos(limpar)`: lê `$v('P18_CD_TIPO')`, `apex.item().show()/hide()`, limpa ocultos quando `limpar !== false`, alterna `is-required` no `#<ITEM>_CONTAINER`; ignora itens não renderizados (`$x`). Page Load: `ajustarCampos(false)` (preserva rascunho); DA: `ajustarCampos(true)`. Visibilidade: cargo em PROMOCAO/MUDANCA_CARGO/TRANSFERENCIA_DEPTO/ADMISSAO; departamento em TRANSFERENCIA_DEPTO/ADMISSAO; gestor também em MUDANCA_GESTOR (obrigatório); salário em PROMOCAO/MUDANCA_CARGO/MERITO/ADMISSAO. O servidor revalida.

### 2.5 HTML gerado e classes CSS

```
div.hc[data-hc]
 ├─ header.hc-titulo > div(h1 "Histórico de carreira", p) + button.hc-btn[data-hc-acao=exportar]
 └─ div.hc-conteudo
     ├─ div.hc-principal
     │   ├─ section.hc-card.hc-resumo > div.hc-indicadores > div.hc-indicador×3 (.hc-indicador__rotulo/__valor/__detalhe: Tempo de casa, No cargo atual|No último cargo, Promoções)
     │   │      div.hc-cargos > h2.hc-subtitulo + div.hc-faixa[role=list] > div.hc-faixa__seg(.is-atual|--vazio)[style=flex-grow:<dias>] + div.hc-eixo > span[style=left:%] … span.hc-eixo__fim
     │   └─ section.hc-card.hc-linha-tempo
     │        div.hc-abas > div.hc-abas__lista[role=tablist] > button[role=tab][data-hc-filtro=tudo|mov|dev] ; label.hc-filtro > select[data-hc-ano]
     │        ol.hc-linha > li.hc-ano[data-ano](span.hc-ano__rotulo, span.hc-ano__divisor > span.hc-ano__qt)
     │                    li.hc-evento(.is-estornado)[data-grupo=mov|dev|marco][data-ano]
     │                       time.hc-evento__data + div.hc-evento__corpo > span.hc-ponto.hc-ponto--forte|suave|neutro|alerta (svg)
     │                         div.hc-evento__titulo(h3, span.hc-tag(.hc-tag--alerta|--aviso), span.hc-pill "Cargo atual")
     │                         p.hc-evento__desc ; div.hc-antes-depois (span.hc-rotulo Antes/Depois) | div.hc-pessoas > div.hc-pessoa(span.hc-avatar(.hc-avatar--destaque))
     │                         div.hc-evento__rodape > div.hc-evento__metas > span.hc-meta ; a.hc-link
     │                         div.hc-aviso (comunicado automático + "Ver comunicado")
     │        p.hc-vazio[data-hc-sem-resultado][hidden]
     └─ aside.hc-lateral > section.hc-card (h2.hc-card__titulo "Posição atual|Última posição", dl.hc-posicao, div.hc-card__rodape "Ver no organograma")
                         section.hc-card > div.hc-sobre > ul(li > span.hc-sobre__icone …) + div.hc-sobre__correcao + p.hc-sobre__status + a.hc-btn.hc-btn--bloco "Solicitar correção"
```

CSS: tokens `--hc-*` em `.hc` lendo `--cx-*` com fallback; `.hc [hidden] { display:none !important }` (necessário porque as classes usam `display:flex`); breakpoints 1100px e 720px; `@media print` esconde chrome do Universal Theme (`.t-Header, .t-Body-nav, .t-Body-actions, .t-Breadcrumb, .t-Footer`), abas e botões, força `print-color-adjust` na faixa atual — é o "Exportar PDF".

### 2.6 Status

Feito (no módulo): DDL, seed, views, package de regras, package de UI, triggers, carga inicial, testes, CSS/JS, README + guia detalhado. Pendente: **pasta inteira untracked** (não commitada); nada instalado no export `database/f100.sql`; nenhuma página montada (13 é placeholder; 18–23 inexistentes); faltam `G_ID_EMPRESA` + `SET_G_ID_EMPRESA`, role/authorizations, LOVs, delegação no `log_pkg.apex_error_handler`, ligação com p. 14/12/2 e menu. Sem dado no modelo: PDI/Resultados 360 (aba "Desenvolvimento" mostra só formações; acrescentar `union all` em `c_eventos` com `ds_grupo = 'DEV'`), "Aprovado por", regime CLT.

### 2.7 Pegadinhas

- Nomes de authorization scheme **exatos** (`ADMIN_RH`): o package chama `apex_authorization.is_authorized('ADMIN_RH')`.
- Usuário sem linha em `COLABORADOR` não recebe `G_ID_EMPRESA` ⇒ bloqueado (inclusive RH). `G_ID_EMPRESA` só é setado no After Authentication: relogar após publicar.
- `fn_pode_ver_colaborador` e `render` liberam tudo **fora de sessão APEX** (scripts/jobs do owner) — `07_testes.sql` depende disso; `url()` devolve `#` fora do APEX.
- Remover o gestor não é possível por movimentação (gestor vazio = manter atual). Excluir colaborador com histórico é bloqueado por FK (use `DESLIGAMENTO`).
- Carga inicial: inativos pré-instalação recebem só admissão (sem desligamento) → turnover histórico incompleto.
- Comunicados automáticos não têm imagem; o card da Home reserva 260px para capa.
- `c_pagina_painel_rh = 20` colide com o `c_pagina_perfil = 20` do organograma (ver 1.7). `c_item_organograma = 'P3_ID_FOCO'` exige que o organograma seja montado na p. 3 com esse nome de item (o guia do organograma usa `P10_`).
- O IG (até 24.2) não fazia upload; por isso a modal 21 — verificar se a 26.1.5 já tem coluna de upload.
- Salvar e efetivar na mesma submissão: se a efetivação falha, o rascunho também é desfeito (sem commit no package).

---

## 3. `modulos/tema/`

`README.md` + `Etapas-tema-paginas.md`: camada de variáveis CSS (`corlix-tema.css`, tokens `--cx-*`) sobre o Redwood Light. Os CSS dos módulos acima leem esses tokens com fallback, então funcionam com ou sem o tema carregado. Detalhes em **`04-tema-e-estilos.md`**.

---

## 4. Template: como criar um novo módulo no mesmo padrão

```
modulos/<modulo>/
  README-<modulo>.md          objetivo, regras, decisões, limitações (opcional p/ módulos pequenos)
  Etapas-<modulo>.md          passo a passo no Builder (itens, regiões, callbacks, static IDs, constantes)
  instalar.sql                @@ em ordem, whenever sqlerror exit failure rollback, lista INVALID no fim
  00_verificar_schema.sql     (se reaproveita tabelas) confere colunas e versão 23ai
  01_ddl_*.sql                create table if not exists …, sempre com ID_EMPRESA + índices iniciando por ela
  03_views_*.sql              views com filtros de status/empresa
  04_pkg_<modulo>.pks/.pkb    regras; erros -200xx em constantes c_err_*; sem commit
  08_pkg_<modulo>_ui.sql      render(...) return clob
  <modulo>.css                tudo escopado em .<prefixo>; tokens --<prefixo>-*: var(--cx-*, fallback)
  <modulo>.js                 blocos comentados: 1 Global Declaration / 2 Page Load / 3 DAs
```

Checklist:
1. **Prefixo** curto e único (`org`, `hc`, …) para classes CSS, namespace JS e Static ID da região.
2. **Package UI**: copiar o esqueleto `g_html`/`inicia`/`p`/`e`/`a`; escapar **todo** dado (`e()` em texto, `a()` em atributo); ações como `<button type="button" data-acao="..." data-id="...">` (nunca `onclick` inline); acessibilidade (`aria-label`, `aria-current`, títulos com `tabindex="-1"` para receber foco após refresh); destinos de navegação em **constantes** (página/item) com `apex_page.get_url` (checksum).
3. **Multi-tenant**: filtrar por `:G_ID_EMPRESA` nas views/queries e validar no package (o organograma ainda não faz — não repetir).
4. **Região APEX**: Dynamic Content · Template *Blank with Attributes* · Static ID = prefixo · Source `return pkg_<m>_ui.render(:Pnn_ITEM);` · Page Items to Submit = itens lidos.
5. **Interação**: troca de estado → `apex.item(...).setValue()` + `apex.region(id).refresh()`; conteúdo sob demanda → Ajax Callback (`apex_util.prn(p_clob => ..., p_escape => false)`, parâmetros em `apex_application.g_x01..`) chamado com `apex.server.process(NOME, {x01: ...}, {dataType: "text"})`, com contador para descartar respostas antigas; reaplicar estado no `apexafterrefresh`; preferir delegação de eventos (região ou `document`).
6. **Itens alterados por JS**: *Value Protected = No*. Itens de ID vindos da URL: *Checksum Required – Session Level*.
7. **CSS/JS**: subir como Static Application File (`#APP_FILES#<m>#MIN#.css` + versão `.min`) ou colar inline; incluir `@media (max-width …)`, `prefers-reduced-motion`, `print` se houver exportação.
8. **Números de página**: o guia deve dizer quais prefixos `Pnn_` trocar (JS, Source, constantes do package). Conferir colisões com `corlixhub/pages/`.
9. Após montar no Builder: exportar em APEXlang (`corlixhub/pages/pNNNNN-*.apx`) e commitar módulo + páginas juntos.

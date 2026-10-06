# Corlix Hub · Contexto para IAs

> **Ponto de entrada** para qualquer IA ou agente que for trabalhar neste repositório. Leia este arquivo inteiro e depois abra só os documentos relevantes para a tarefa.
> Gerado em 06/10/2026 a partir da inspeção do código (branch `DEV`, HEAD `bac2d69` + mudanças não commitadas). Versão visual: [`index.html`](./index.html).

## Resumo em 30 segundos

- **Produto:** intranet corporativa SaaS para PMEs. Reúne colaboradores, organograma, histórico de carreira, comunicados, chat, equipes e cadastro multiempresa. Projeto FIAP Enterprise Challenge 2026.
- **Stack:** Oracle APEX 26.1 (Universal Theme, visual Redwood Light) sobre Oracle Database 23ai e ORDS 25.4. Toda a lógica está em SQL/PL/SQL e nas definições declarativas do APEX. Não há Node/Java/Python.
- **App:** ID `100`, alias `CORLIXHUB`, workspace/schema `WKSP_CORLIXHUB`, autenticação por contas APEX, idioma da UI pt-BR (idioma primário técnico `en`).
- **Fonte da app:** `corlixhub/` em formato **APEXlang** (`.apx`). `database/f100.sql` é o mesmo app num export SQL de 12 MB: use só para consultar, nunca edite.
- **Banco:** só o módulo de histórico de carreira tem DDL no repo (`modulos/historico-carreira/`). As tabelas base (`COLABORADOR`, `CARGO`, `DEPARTAMENTO`, `EMPRESA`, `COMUNICADO`, `EQUIPE`…) **não têm DDL versionado**; o schema delas foi inferido do uso.
- **Em andamento:** redesign visual (tokens `--cx-*` em `corlix-tema.css`), módulos de Organograma e Histórico de carreira (prontos em `modulos/`, ainda **não integrados** às páginas 3 e 13) e ~28 telas-alvo em `figma/`.

## Documentos

| # | Documento | Quando ler |
|---|---|---|
| 01 | [Arquitetura e ambiente](./01-arquitetura-e-ambiente.md) | Stack, mapa de pastas, Docker, CI, branches/commits, divergências README × código |
| 02 | [Páginas](./02-paginas.md) | Sintaxe APEXlang + cada página (regiões, itens, processos, DAs, SQL), mapa de navegação |
| 03 | [Componentes compartilhados](./03-componentes-compartilhados.md) | `application.apx`, roles/authorizations, app items/processes, menu, breadcrumbs, LOVs, templates do tema, static files |
| 04 | [Tema e estilos](./04-tema-e-estilos.md) | Tokens `--cx-*`, mapeamento Universal Theme, catálogo de classes CSS, como aplicar o tema numa página |
| 05 | [Banco de dados](./05-banco-de-dados.md) | Diagrama ER, tabelas (DDL e inferidas), views, triggers, packages, códigos de erro, testes |
| 06 | [Módulos](./06-modulos.md) | Organograma e Histórico de carreira: arquitetura, integração no APEX, API JS, template de novo módulo |
| 07 | [Design (Figma)](./07-design-figma.md) | Descrição detalhada de cada tela-alvo e mapeamento para componentes APEX; features sem backend |
| 08 | [Convenções e pegadinhas](./08-convencoes-e-pegadinhas.md) | **Leia antes de editar qualquer coisa.** Regras de trabalho, lacunas, bugs conhecidos, checklist |

### Guia por tipo de tarefa
- **Mexer numa página existente:** 08 → 02 (seção da página) → 03 (componentes que ela usa) → 04 (classes CSS).
- **Criar uma página ou tela do Figma:** 07 (tela) → 02 §1 (sintaxe) → 04 §8 (aplicar tema) → 08.
- **Mexer no banco ou criar tabela:** 05 → 06 §4 (padrão de módulo) → 08.
- **Integrar organograma ou histórico de carreira:** 06 → 05 → 02 (páginas 3/13).
- **Ambiente, deploy ou CI:** 01.

## Páginas (visão rápida)

| Nº | Página | Status |
|---|---|---|
| 0 | Global Page (header: busca, sino, config, usuário) | Implementada |
| 1 | Home (dashboard) | Implementada |
| 2 | Meu Perfil | Placeholder |
| 3 | Organograma | Placeholder; o módulo existe em `modulos/organograma` |
| 4 | Chat | Parcial (leitura, sem envio) |
| 5 / 8 | Notificações (duplicadas) | Placeholder / vazia |
| 6 | Configurações | Placeholder |
| 7 | Monitor de Logs | Implementada (sem authorization!) |
| 11 | Comunicados Oficiais | Placeholder |
| 12 | Colaboradores | Placeholder |
| 13 | Histórico de carreira | Placeholder; o módulo existe em `modulos/historico-carreira` |
| 14 | Cadastro de Usuários (cria usuário APEX) | Implementada |
| 15 / 16 | Empresas (lista / modal de cadastro com ViaCEP) | Implementada |
| 17 | Emitir Comunicado (modal wizard) | Implementada, com bugs |
| 26 / 27 | Central de Equipes / Nova Equipe (modal) | Implementada |
| 9999 | Login | Implementada |

## Regras de ouro (resumo do 08)
1. Edite `corlixhub/**/*.apx`; nunca edite `database/f100.sql`.
2. Use pt-BR em tudo e Conventional Commits; abra PRs para `DEV`.
3. Toda query de negócio deve filtrar por `id_empresa`, e toda página administrativa precisa de `authorizationScheme` na própria página.
4. Gere links com checksum (`apex_page.get_url`).
5. Ao alterar um `.css`, altere também o `.min.css` e registre arquivos novos em `static-files.apx`.
6. Se o README raiz divergir do código, confie no código. O que não estiver confirmado, pergunte ao time (ex.: o ambiente atual, já que `docker-compose.yml` foi apagado, e o fonte de `log_pkg`).
7. Ao mudar páginas, schema, tema ou módulos, **atualize o documento correspondente nesta pasta**.

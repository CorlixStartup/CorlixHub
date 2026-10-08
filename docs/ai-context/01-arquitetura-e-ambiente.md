# 01 · Arquitetura, ambiente e fluxo de trabalho

> Parte do pacote de contexto para IAs (`docs/ai-context/`). Comece pelo [`README.md`](./README.md) desta pasta.
> Gerado a partir da inspeção dos arquivos em 06/10/2026 (branch `DEV`, HEAD `bac2d69`).

## 1. O que é o Corlix Hub

- Intranet corporativa SaaS para **PMEs**: gestão de colaboradores, organograma, histórico de carreira, comunicação interna (comunicados, chat, notificações), equipes e cadastro multiempresa.
- Projeto acadêmico do **Enterprise Challenge (StartupOne) — FIAP, turma 4ESOA, 2026**. Tech lead: Sarah Ribeiro da Silva.
- Slogan: *"Core logic, smart solutions."*
- Idioma de toda a UI, código, comentários e documentação: **português do Brasil**.

## 2. Stack

| Camada | Tecnologia | Observação |
|---|---|---|
| App / UI | **Oracle APEX 26.1** (release 26.1.5), Universal Theme (visual Redwood Light) | App ID `100`, alias `CORLIXHUB`, nome "Corlix Hub" |
| Banco | **Oracle Database 23ai Free** (`23.26.1.0`) | Schema/workspace `WKSP_CORLIXHUB`, PDB `FREEPDB1` |
| HTTP | **ORDS 25.4.0** | Serve o APEX |
| Dev local | Docker Compose (`db` + `ords`) | ⚠️ ver §5 — `docker-compose.yml` está deletado no working tree |
| Lógica | SQL + PL/SQL (packages, views, triggers) | Nenhum backend fora do banco |
| Front custom | CSS (`corlix-tema.css`, `custom.css`, CSS de módulos) + JS vanilla/jQuery do APEX (`apex.*`) | Sem bundler, sem `package.json` |

Não existe Node, Java, Python etc. no projeto. Toda regra de negócio vive no banco (PL/SQL) ou nas definições declarativas do APEX.

## 3. Mapa do repositório

```
CorlixHub/
├── README.md                  # README humano (⚠️ parcialmente desatualizado — ver §6)
├── CLAUDE.md / AGENTS.md      # Ponteiros para esta documentação (para agentes de IA)
├── docs/ai-context/           # ESTA documentação para IAs
├── corlixhub/                 # ★ CÓDIGO-FONTE DA APP APEX em formato APEXlang (.apx)
│   ├── application.apx        #   definição global da app (auth, CSS globais, menu, error handler)
│   ├── page-groups.apx        #   grupo "Administration"
│   ├── .apex/apexlang.json    #   versão do formato (mmdVersion 26.1.0+3102)
│   ├── deployments/default.json  # app id 100, debugging true
│   ├── supporting-objects/    #   supporting objects (incluídos no export, vazios)
│   ├── pages/pNNNNN-<nome>.apx   # 1 arquivo por página (19 páginas)
│   └── shared-components/     #   roles, authorizations, app items/processes, lists, LOVs, breadcrumbs,
│       ├── static-files.apx   #   registro dos arquivos estáticos (#APP_FILES#)
│       ├── static-files/      #   CSS do tema, ícones PWA, default-user.jpeg, "Fotos Colaboradores/" (~291 fotos fictícias)
│       └── themes/universal-theme/  # templates customizados (page/region/report/button)
├── database/
│   └── f100.sql               # Export SQL clássico (single-file) da app 100 — 12 MB, ~63k linhas.
│                              #   É a MESMA app de corlixhub/, em outro formato. NÃO contém DDL das tabelas.
├── modulos/                   # Módulos de feature desenvolvidos fora do Builder (SQL/CSS/JS + guias "Etapas-*.md")
│   ├── organograma/           #   vw_org_colaborador, pkg_organograma, organograma.css/js, PNGs de redesign
│   ├── historico-carreira/    #   (untracked) DDL completo + packages + views + triggers + testes + CSS/JS
│   └── tema/                  #   (untracked) guia de aplicação do tema visual nas páginas
├── figma/                     # (untracked) ~28 PNGs com o design-alvo das telas
├── scripts/
│   ├── setup.sh / setup.ps1   # setup do ambiente Docker (macOS/Linux e Windows)
│   ├── git-hooks/commit-msg   # valida Conventional Commits
│   ├── apex-limpar-sql-scripts.sql  # apaga SQL Scripts do workspace (dry-run por padrão)
│   └── backup/                # pipeline de backup (SQLcl + Jenkins): app, DDL e dados
└── .github/workflows/ci.yml   # CI: valida docker-compose, gitleaks, bloqueia pastas proibidas
```

## 4. Dois formatos da mesma aplicação

| | `corlixhub/` (APEXlang) | `database/f100.sql` |
|---|---|---|
| Formato | Declarativo, legível, 1 arquivo por página/componente | `wwv_flow_imp*` PL/SQL gerado, single file |
| Uso por IA | **Leia e edite aqui.** Diffs pequenos, revisáveis | Só para grep/consulta; não editar à mão (Oracle não suporta) |
| Arquivos estáticos | Arquivos reais em `static-files/` | Embutidos em hex (~301 blocos `shared_components/files`) |
| Instalação | Import/sync via ferramentas APEXlang/SQLcl do APEX 26.1 | `@database/f100.sql` no SQLcl conectado como `WKSP_CORLIXHUB` |

Ao alterar a app no Builder, reexporte para **ambos** (ou combine com o time qual é a fonte de verdade — hoje, na prática, `corlixhub/` é a fonte principal e `f100.sql` é um snapshot). O export de `f100.sql` mais recente é de 04/10/2026 01:10, exportado por `SARAHSILVA`.

Contagens do export (cabeçalho de `f100.sql`): 19 páginas, 54 itens, 48 regiões, 15 processos, 17 botões, 8 dynamic actions, 1 validação; shared: 5 app items, 4 app processes, 2 lists, 1 breadcrumb (12 entradas), 1 authentication, 3 authorizations, 3 ACL roles, 4 LOVs, 1 tema com templates customizados (1 page, 1 region, 1 button, 2 report).

## 5. Ambiente de desenvolvimento

### 5.1 Docker (histórico — arquivos deletados no working tree)

No commit `HEAD` existiam `docker-compose.yml` e `.env.example`; **ambos aparecem como deletados (não commitado)** no `git status` atual. Conteúdo do `HEAD`:

```yaml
services:
  db:
    image: container-registry.oracle.com/database/free:23.26.1.0
    hostname: database
    ports: ["${DB_HOST_PORT:-1522}:1521"]
    environment: [ORACLE_PWD=${ORACLE_PWD:-pwd}, DBHOST=database]
    volumes: [./oracle_oradata/:/opt/oracle/oradata, ./apex/:/opt/oracle/apex]
  ords:
    image: container-registry.oracle.com/database/ords:25.4.0
    ports: ["${ORDS_HOST_PORT:-8081}:8080"]
    environment: [DBHOST=database, DBPORT=1521, DBSERVICENAME=FREEPDB1, ORACLE_PWD=..., APEX_PWD=...]
    volumes: [./ords_config/:/etc/ords/config, ./apex/:/opt/oracle/apex]
    depends_on: { db: { condition: service_healthy } }
```

Variáveis: `ORACLE_PWD`, `APEX_PWD`, `DB_HOST_PORT=1522`, `ORDS_HOST_PORT=8081`.
URLs locais: Builder `http://localhost:8081/ords`; app `http://localhost:8081/ords/r/wksp_corlixhub/corlixhub` (não confirmado).

⚠️ **Consequências se essa deleção for commitada:** o job `validate` do CI passou a ignorar a validação quando o arquivo não existe; `scripts/setup.*` também passam a não funcionar. Pergunte ao time antes de assumir qual é o ambiente atual (possivelmente migraram para uma instância APEX hospedada/OCI ou outra forma de rodar).

### 5.2 Pastas que nunca vão para o Git
`apex/` (distribuição Oracle ~1,1 GB), `META-INF/`, `oracle_oradata/` (datafiles), `ords_config/` (contém wallet e chave TLS), `.env*` (exceto `.env.example`), `*.log`, `.DS_Store`. O CI bloqueia `apex/`, `oracle_oradata/`, `ords_config/`, `META-INF/`.

### 5.3 Instalando o banco de uma feature
O DDL dos objetos de banco "core" (`COLABORADOR`, `CARGO`, `DEPARTAMENTO`, `EMPRESA`, `COMUNICADO`, equipes, chat, logs…) está em `database/corlix-hub.sql`, um snapshot só de estrutura, sem dados (o README cita `database/ddl/` e `database/seed/`, que não existem). Os módulos trazem seus próprios scripts:
- Histórico de carreira: `modulos/historico-carreira/instalar.sql` (roda `00_…` a `07_…` em ordem).
- Organograma: `modulos/organograma/organograma.sql`.
Detalhes em [`05-banco-de-dados.md`](./05-banco-de-dados.md) e [`06-modulos.md`](./06-modulos.md).

## 6. Divergências README × realidade (importante para IAs)

| README diz | Realidade no repo |
|---|---|
| App exportada em `f100/application/pages/*.sql` + `f100/install.sql` | App está em `corlixhub/` (APEXlang `.apx`) e `database/f100.sql` (single file) |
| `database/ddl/schema_corlixhub.sql` e `database/seed/seed_corlixhub.sql` | Não existem. `database/ddl/` agora é gerada pelo backup (`01-tipos.sql` … `11-sinonimos.sql`, ver §8.1); não há seed |
| "Não há packages PL/SQL próprios" | Existem `pkg_historico_carreira`, `pkg_historico_carreira_ui`, `pkg_organograma`; a app usa `log_pkg.apex_error_handler` |
| "Não há testes" | Existe `modulos/historico-carreira/07_testes.sql` |
| `docs/` não existe | Agora existe `docs/ai-context/` |
| Repo sem commits/remote | Remote `https://github.com/CorlixStartup/CorlixHub.git`; branches remotas `DEV` (HEAD), `UAT`, `PROD`, `main`, `feature/cadastro-empresas`; PR #1 mergeado |
| Seis entidades: Empresa, Colaborador, Cargo, Departamento, Movimentacao_Carreira, Comunicado | `MOVIMENTACAO_CARREIRA` existe no banco como tabela legada, sem uso; o módulo novo a substitui por `HISTORICO_CARREIRA` + `TIPO_MOVIMENTACAO`; há também equipes, chat, logs, presença etc. |

Quando o README e o código discordarem, **confie no código** e sinalize a divergência.

## 7. Git, branches e commits

- Branches permanentes: `DEV` (integração, padrão para PRs) → `UAT` (homologação) → `PROD`. Auxiliares: `feature/*`, `bugfix/*` (de `DEV`), `hotfix/*` (de `PROD`, depois replicado para UAT e DEV), `release/*` opcional.
- Nunca commit direto em `DEV`/`UAT`/`PROD`; sempre PR.
- **Conventional Commits** validado por `scripts/git-hooks/commit-msg` (ativar com `git config core.hooksPath scripts/git-hooks`). Regex:
  `^(feat|fix|hotfix|refactor|test|docs|chore|build|ci|perf)(\([a-z0-9_-]+\))?!?: .{1,100}$`
  Ex.: `feat(organograma): adiciona drawer de detalhes da pessoa`. (Obs.: o último commit `feature: …` não segue o padrão — o hook provavelmente não estava ativo.)
- `.gitattributes`: LF para tudo (`.sql`, `.sh`, `.md`, `.yml`), CRLF para `.ps1/.bat/.cmd`; imagens binárias.

## 8. CI (`.github/workflows/ci.yml`)
Roda em PR/push para `DEV`, `UAT`, `PROD`:
1. `validate` — `docker compose config` só se existir `docker-compose.yml`; sem o arquivo, emite um aviso e passa.
2. `secret-scan` — gitleaks 8.28.0 (CLI OSS) sobre todo o histórico.
3. `forbidden-paths` — falha se `apex/`, `oracle_oradata/`, `ords_config/` ou `META-INF/` existirem.
Não há deploy automatizado nem testes automatizados no CI.

## 8.1 Backup (`scripts/backup/`)
Job Jenkins diário (02h, America/Sao_Paulo) que conecta no Autonomous Database (OCI) pelo SQLcl, com wallet, como o dono do schema, e gera um `.tar.gz` por ambiente com:
- a app em APEXlang e em SQL (com checksum SHA-256);
- usuários e grupos do workspace;
- o DDL do schema (`dbms_metadata`, sem schema/tablespace, um arquivo por tipo);
- um CSV por tabela, com BLOBs em base64.

Os backups ficam como artefatos do Jenkins (30 dias) e nunca vão para o Git (`/backups/` no `.gitignore`), porque contêm dados pessoais. O `backup.sh` também roda local, e `scripts/backup/jenkins/` tem um `docker-compose.yml` que sobe um Jenkins local para testar o pipeline, copia cada `.tar.gz` para `backups/<ambiente>/` do projeto e, com `scripts/backup/extrair-no-projeto.sh`, atualiza `corlixhub/`, `database/f100.sql` e `database/ddl/` (pulando destinos com alterações não commitadas) e põe os CSVs em `database/dados/backup/` (ignorado pelo Git) (o compose fica fora da raiz, então o job `validate` do CI não o valida). Com o parâmetro `PUBLICAR_GIT` (padrão), o stage *Publicar no Git* roda `scripts/backup/publicar-no-git.sh`: clona a `DEV`, extrai o backup de `PRD` nela, commita só `corlixhub/`, `database/f100.sql` e `database/ddl/` com a mensagem `chore(backup): Backup - Corlix Hub - dd/MM/yyyy as HH:mm` (horário de Brasília; commit vazio se nada mudou), faz push e abre PR `DEV` → `PROD` se não houver um aberto; nesse modo a extração na pasta local do projeto é pulada. Usa a credencial `corlixhub-github` (usuário + token do GitHub). Referência (conteúdo, variáveis, restauração) em [`scripts/backup/README.md`](../../scripts/backup/README.md); passo a passo da configuração, com erros comuns, em [`scripts/backup/Etapas-backup.md`](../../scripts/backup/Etapas-backup.md).

## 9. Estado do working tree no momento desta documentação
Modificados (não commitados): `application.apx`, páginas 1, 4, 14, 16, 27, `static-files.apx`, `custom.css/.min.css`, `database/f100.sql`, arquivos de `modulos/organograma/`.
Novos (untracked): `corlix-tema.css/.min.css`, `figma/`, `modulos/historico-carreira/`, `modulos/tema/`, PNGs de redesign do organograma, `scripts/apex-limpar-sql-scripts.sql`.
Deletados: `.env.example`, `docker-compose.yml`.
Ou seja: há um trabalho grande de **redesign visual (tema Corlix)** + **módulo de histórico de carreira** em andamento.

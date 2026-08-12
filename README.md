# Corlix Hub

**Core logic, smart solutions.**

Plataforma SaaS de intranet corporativa desenvolvida para pequenas e médias
empresas (PMEs), centralizando gestão de funcionários, estrutura
organizacional, evolução de carreira e comunicação interna em um único
ambiente seguro e intuitivo.

Na prática, hoje o Corlix Hub é um portal interno construído em **Oracle
APEX**, rodando sobre **Oracle Database** e **Oracle REST Data Services
(ORDS)**, orquestrados via **Docker Compose** para desenvolvimento local
(workspace `WKSP_CORLIXHUB`, aplicação `CorlixHub`, ID `100`).

Projeto desenvolvido para o **Enterprise Challenge (StartupOne) — Turma
4ESOA, FIAP, 2026**.

> ⚠️ Este README passou por uma auditoria a partir da inspeção real dos
> arquivos do repositório em 11/08/2026. Onde não foi possível confirmar algo
> (ex.: se há ambiente de UAT/PROD já hospedado em algum lugar), isso está
> sinalizado explicitamente como **"não confirmado"** — não invente respostas
> para essas lacunas, pergunte ao time.

---

## O problema

PMEs em crescimento enfrentam três problemas recorrentes:

1. **Desorganização estrutural** — organogramas vivem em PDFs desatualizados; ninguém sabe a quem recorrer para cada assunto.
2. **Ausência de histórico de carreira** — promoções e mudanças de cargo são registradas de forma informal (ou não são registradas), gerando risco trabalhista e desmotivação.
3. **Comunicação interna fragmentada** — avisos importantes se perdem entre WhatsApp, e-mail e grupos informais, sem rastreabilidade.

Soluções enterprise (SAP SuccessFactors, Workday, Oracle HCM) resolvem isso, mas custam acima de R$100/usuário/mês e são desenhadas para empresas com milhares de funcionários — inacessíveis para o público-alvo deste projeto.

## A solução

O Corlix Hub entrega um recorte enxuto (MVP) desses três pilares em uma única plataforma:

- **Organograma** — estrutura hierárquica sempre atualizada a partir do cadastro de colaboradores.
- **Histórico de carreira** — timeline de promoções e mudanças de cargo por colaborador.
- **Mural de comunicados** — avisos oficiais, com opção de segmentação por departamento.

## Time

| Nome | RM |
|---|---|
| Sarah Ribeiro da Silva (tech lead) | 97747 |
| Alairton Rocha Scabelli | 551454 |
| Carolina Nascimento Amorim | 97930 |
| Eduardo Marins | 551892 |

---

## Índice

- [Stack tecnológica](#stack-tecnológica)
- [Modelo de dados](#modelo-de-dados)
- [Pré-requisitos](#pré-requisitos)
- [Estrutura de diretórios](#estrutura-de-diretórios)
- [Instalação passo a passo](#instalação-passo-a-passo)
- [Variáveis de ambiente](#variáveis-de-ambiente)
- [Como executar em desenvolvimento](#como-executar-em-desenvolvimento)
- [Como executar em produção](#como-executar-em-produção)
- [Testes](#testes)
- [Lint e formatação](#lint-e-formatação)
- [Migrations e seeds](#migrations-e-seeds)
- [Comandos principais](#comandos-principais)
- [Troubleshooting](#troubleshooting)
- [Fluxo de desenvolvimento (features e bugs)](#fluxo-de-desenvolvimento-features-e-bugs)
- [Processo de deploy](#processo-de-deploy)
- [Estratégia de branches (Git)](#estratégia-de-branches-git)
- [Convenção de commits](#convenção-de-commits)
- [Como contribuir](#como-contribuir)
- [Qualidade e automação](#qualidade-e-automação)
- [Portabilidade entre Windows, Linux e macOS](#portabilidade-entre-windows-linux-e-macos)
- [Roadmap](#roadmap)
- [Status atual](#status-atual)

---

## Stack tecnológica

### Ambiente de desenvolvimento local (verificado nos arquivos do projeto)

| Componente | Versão | Onde foi confirmado |
|---|---|---|
| Oracle Database Free | `23.26.1.0` (Oracle Database 23ai Free) | `docker-compose.yml` (imagem `container-registry.oracle.com/database/free:23.26.1.0`) |
| Oracle REST Data Services (ORDS) | `25.4.0` | `docker-compose.yml` (imagem `.../database/ords:25.4.0`) e `ords_config/logs/*.log` |
| Oracle APEX | `26.1` | `apex/images/apex_version.txt` |
| Orquestração | Docker Compose | `docker-compose.yml` |

Não há backend/frontend customizado fora do APEX (não há `package.json`,
`pom.xml`, `requirements.txt` etc. no projeto) — toda a lógica de aplicação
vive dentro da exportação da aplicação APEX (`f100/`) e nos dumps SQL do
schema do banco.

### Ambiente alvo de produção (visão do projeto, ainda não implementado)

A proposta original do Enterprise Challenge prevê hospedagem em **Oracle
Cloud Infrastructure (OCI)**, usando um **Autonomous Database** gerenciado no
lugar do Oracle Database Free rodando localmente em container. Isso ainda
**não existe** neste repositório — hoje só há o ambiente de desenvolvimento
local via Docker Compose descrito acima. Ver [Como executar em
produção](#como-executar-em-produção) e [Roadmap](#roadmap).

## Modelo de dados

Seis entidades principais: `Empresa`, `Colaborador`, `Cargo`, `Departamento`,
`Movimentacao_Carreira`, `Comunicado`. O DDL das tabelas do schema
`WKSP_CORLIXHUB` está em [`database/ddl/schema_corlixhub.sql`](./database/ddl/schema_corlixhub.sql),
e os dados de exemplo/seed em [`database/seed/seed_corlixhub.sql`](./database/seed/seed_corlixhub.sql)
(ver [Migrations e seeds](#migrations-e-seeds) para detalhes e ressalvas sobre esses dados).

---

## Pré-requisitos

Ferramentas necessárias na máquina de quem for rodar ou desenvolver o projeto:

| Ferramenta | Versão mínima recomendada | Observação |
|---|---|---|
| [Docker](https://docs.docker.com/get-docker/) | Docker Engine 24+ (Docker Desktop mais recente em Windows/macOS) | Testado neste ambiente com Docker `29.7.2` |
| Docker Compose (plugin v2, comando `docker compose`) | v2.20+ | Testado neste ambiente com Compose `v5.3.1`. **Não** use o binário antigo `docker-compose` (v1) — o `docker-compose.yml` usa sintaxe (`condition: service_healthy`) que exige o plugin v2. |
| Git | 2.30+ | Para clonar o repositório e trabalhar com branches |
| ~10 GB de espaço livre em disco | — | O container do Oracle Database + a distribuição do APEX ocupam vários GB (ver [Troubleshooting](#troubleshooting)) |
| Conta gratuita na Oracle (OTN) | — | Necessária apenas para baixar o instalador do Oracle APEX (ver passo 3 da instalação) |

**Não é necessário** instalar Oracle Database, SQL*Plus, Node.js ou qualquer
runtime de linguagem na máquina host — tudo roda dentro dos containers. Se você
quiser rodar scripts `.sql` manualmente fora do APEX Builder, recomendamos o
[Oracle SQLcl](https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/) ou o SQL Developer, mas isso é opcional.

**Compatibilidade por sistema operacional** (ver detalhes em
[Portabilidade](#portabilidade-entre-windows-linux-e-macos) mais abaixo):

- **macOS**: testado neste projeto (ambiente onde este README foi escrito).
- **Windows**: requer Docker Desktop com backend **WSL2**. Não testado neste
  repositório — sinalizado como **não confirmado**.
- **Linux**: requer Docker Engine + plugin Compose v2. Pode ser necessário
  ajustar permissões do volume `oracle_oradata/` (ver Troubleshooting). **Não
  confirmado** neste repositório.

---

## Estrutura de diretórios

### Como está hoje

```
corlix-hub/
├── docker-compose.yml        # Orquestra os containers db + ords
├── .env.example               # Modelo de variáveis de ambiente
├── .gitignore
├── .gitattributes
├── scripts/                   # Scripts de setup
│   ├── setup.sh
│   ├── setup.ps1
│   └── git-hooks/commit-msg
├── f100/                       # Exportação da aplicação APEX 100 "CorlixHub" (CÓDIGO-FONTE real do projeto)
│   ├── install.sql
│   └── application/
│       ├── pages/               # Uma página SQL por página da aplicação
│       ├── shared_components/   # Listas, LOVs, autorizações, temas, arquivos estáticos...
│       └── deployment/
├── database/
│   ├── ddl/schema_corlixhub.sql # DDL (CREATE TABLE) do schema WKSP_CORLIXHUB
│   └── seed/seed_corlixhub.sql  # Dados de exemplo/seed (INSERTs) do schema
├── apex/                       # Distribuição oficial do Oracle APEX 26.1 (vendor, ~1.1 GB)
│   └── f100/                    # Cópia duplicada da exportação (ver problema #2 abaixo)
├── META-INF/                   # Metadados de assinatura do pacote Oracle APEX (vendor)
├── oracle_oradata/              # Datafiles do Oracle Database (gerado em runtime, ~7,5 GB)
└── ords_config/                 # Configuração/segredos do ORDS (gerado em runtime)
```

### Por que algumas pastas não devem ir para o Git

| Pasta/arquivo | Tamanho aprox. | Motivo para não versionar |
|---|---|---|
| `apex/` | ~1,1 GB | É a distribuição oficial da Oracle (baixada do site da Oracle), não código do projeto. Além disso `apex/f100/` é uma cópia idêntica de `f100/` (confirmado com `diff -r`) gerada ao exportar a aplicação de dentro do APEX Builder para a pasta montada no container. |
| `META-INF/` | ~8,9 MB | Metadados de assinatura (`MANIFEST.MF`, `.RSA`, `.SF`) do zip oficial do APEX — também vendor, não é código do projeto. |
| `oracle_oradata/` | ~7,5 GB | Datafiles binários do Oracle (`.dbf`, `.ctl`, redo logs). São recriados automaticamente no primeiro `docker compose up`, não são portáveis entre máquinas/arquiteturas e mudam a cada execução — versionar isso no Git quebraria o repositório. |
| `ords_config/` | pequeno, mas sensível | Contém **segredos**: `wallet/cwallet.sso` (wallet do banco) e `global/standalone/self-signed.key`/`.pem` (chave privada TLS). Esses arquivos são **gerados automaticamente** pelo container ORDS a cada subida, a partir das variáveis de ambiente do `docker-compose.yml`. |
| `*.log` (`apex/install*.log`, `apex/configure*.log`, `ords_config/logs/*.log`) | variável | Logs de execução local, não fazem sentido versionados. |
| `.DS_Store` | pequeno | Lixo específico do Finder do macOS. |

Todos esses itens já estão no `.gitignore`.

Os dois dumps SQL, que antes estavam soltos na raiz do projeto sem indicar
claramente qual era DDL (estrutura) e qual era dado de exemplo (seed), já
foram organizados em `database/ddl/schema_corlixhub.sql` e
`database/seed/seed_corlixhub.sql`.

---

## Instalação passo a passo

### 1. Clonar o projeto

```bash
git clone <url-do-repositorio>
cd corlix-hub
```

> **Não confirmado**: o repositório já foi inicializado localmente com
> `git init`, mas ainda não tem nenhum commit nem remoto configurado
> (`git remote -v` não retorna nada). A URL de clone acima é um placeholder
> até vocês decidirem onde hospedar (GitHub, GitLab, Bitbucket, etc.) e
> fizerem o primeiro push.

### 2. Rodar o script de setup

```bash
# macOS / Linux
./scripts/setup.sh

# Windows (PowerShell)
.\scripts\setup.ps1
```

O script confere se Docker/Docker Compose estão instalados, cria o `.env` a
partir do `.env.example` e sobe os containers. Ele **não baixa o APEX
automaticamente** — isso precisa ser feito manualmente uma vez (próximo
passo), porque a Oracle exige aceite dos termos de uso no download.

### 3. Baixar a distribuição do Oracle APEX 26.1 (obrigatório, feito uma única vez por máquina)

1. Acesse <https://www.oracle.com/tools/downloads/apex-downloads/>.
2. Baixe a versão **26.1** (`apex_26.1.zip`) — precisa ser exatamente essa
   versão, é a que está referenciada em `apex/images/apex_version.txt`.
3. Descompacte o conteúdo do zip **diretamente na raiz do projeto**, de forma
   que existam as pastas `./apex/core`, `./apex/images`, `./apex/builder` etc.

> Isso é necessário porque o `docker-compose.yml` monta `./apex/` dentro dos
> containers `db` e `ords` (`/opt/oracle/apex`) — os containers usam esse
> conteúdo para instalar o APEX no banco e para servir os arquivos estáticos
> (imagens, CSS, JS) da aplicação.

### 4. Configurar variáveis de ambiente

```bash
cp .env.example .env
```

Edite `.env` e defina senhas próprias para `ORACLE_PWD` e `APEX_PWD` (ver
seção [Variáveis de ambiente](#variáveis-de-ambiente)). **Nunca** use os
valores de exemplo fora da sua máquina local.

### 5. Subir os containers

```bash
docker compose up -d
```

A primeira subida instala o Oracle APEX dentro do banco e pode levar entre
**5 e 15 minutos**, dependendo da máquina. Acompanhe com:

```bash
docker compose logs -f
docker compose ps      # espere o serviço "db" ficar "healthy"
```

### 6. Carregar o schema e os dados de exemplo

Com os containers de pé, conecte-se ao banco (porta `1522` por padrão, ou o
valor de `DB_HOST_PORT` no seu `.env`) com o cliente SQL de sua preferência
(SQL Developer, SQLcl, DBeaver...) no schema/workspace `WKSP_CORLIXHUB` e
execute, nesta ordem:

```sql
@database/ddl/schema_corlixhub.sql    -- cria as tabelas (DDL)
@database/seed/seed_corlixhub.sql     -- popula com dados de exemplo (INSERTs)
```

> **Não confirmado**: o repositório não documenta as credenciais/usuário do
> schema `WKSP_CORLIXHUB` nem como esse workspace é criado (o
> `docker-compose.yml` só provisiona o usuário `ADMIN` do workspace
> `INTERNAL` via `APEX_PWD`). Se o workspace `WKSP_CORLIXHUB` ainda não
> existir na sua instância, será preciso criá-lo antes pelo APEX Builder
> (`Administration > Manage Workspaces > Create Workspace`) — confirme esse
> passo com quem já rodou o projeto antes.

### 7. Instalar a aplicação APEX (f100)

Dentro do schema/workspace `WKSP_CORLIXHUB`, via SQLcl:

```bash
sql -name <seu-alias-de-conexão>
SQL> @f100/install.sql
```

Ou, alternativamente, importe a aplicação pelo **APEX Builder**
(`App Builder > Import`) apontando para a pasta `f100/application` (import
"from files").

### 8. Acessar a aplicação

- **ORDS / APEX Builder**: `http://localhost:8081/ords` (ou a porta definida
  em `ORDS_HOST_PORT`)
- **Aplicação CorlixHub**: `http://localhost:8081/ords/r/wksp_corlixhub/corlixhub`
  (caminho **não confirmado** — depende do alias do workspace/aplicação
  configurado; confirme a URL exata no APEX Builder em
  `App Builder > CorlixHub > Run Application`)

---

## Variáveis de ambiente

Arquivo `.env.example`, copie para `.env` e ajuste:

```bash
# Senha do usuário SYS/SYSTEM do Oracle Database (container "db")
ORACLE_PWD=changeMe123

# Senha do usuário ADMIN do workspace INTERNAL do Oracle APEX
APEX_PWD=changeMe123

# Portas expostas no host
DB_HOST_PORT=1522
ORDS_HOST_PORT=8081
```

Essas são **todas** as variáveis usadas hoje pelo `docker-compose.yml`
(confirmado lendo o arquivo). `ORACLE_PWD` e `APEX_PWD` lêem de variáveis de
ambiente com fallback para `pwd` (mantendo compatibilidade com quem já usa o
projeto), mas o valor `pwd` não deve ser usado fora de uma máquina de
desenvolvimento pessoal (ver checklist 🔴 em [Qualidade e
automação](#qualidade-e-automação)).

---

## Como executar em desenvolvimento

```bash
docker compose up -d       # sobe db + ords em background
docker compose logs -f     # acompanha os logs
docker compose down        # derruba os containers (mantém os dados em oracle_oradata/)
docker compose down -v     # derruba os containers E apaga os volumes (reset completo)
```

Para desenvolver a aplicação, use o **APEX Builder** normalmente
(`http://localhost:8081/ords`) para editar páginas, processos, etc. Depois de
alterar algo relevante, exporte a aplicação de volta para o repositório:

`App Builder > CorlixHub > Export/Import > Export > Split into multiple files`,
salvando em `f100/application/` — isso mantém o código-fonte da aplicação
versionado no Git (é assim que o `f100/` atual foi gerado).

---

## Como executar em produção

**Não confirmado / não existe hoje no repositório.** O `docker-compose.yml`
atual é adequado apenas para desenvolvimento local:

- Usa certificado TLS **autoassinado**, gerado automaticamente
  (`ords_config/global/standalone/self-signed.key/.pem`) — não deve ser
  usado como está em UAT/PROD.
- Não há um `docker-compose.uat.yml` / `docker-compose.prod.yml`, Kubernetes
  manifests, Terraform, pipeline de deploy, ou qualquer outro artefato de
  infraestrutura para outros ambientes neste repositório.
- Não há segredos gerenciados externamente (ex.: Vault, OCI Vault) — hoje as
  senhas dependem só do `.env` local.
- A visão original do projeto é hospedar em **Oracle Cloud Infrastructure
  (OCI)**, com um **Autonomous Database** no lugar do container Oracle
  Database Free (ver [Stack tecnológica](#stack-tecnológica) e
  [Roadmap](#roadmap)) — isso ainda não foi implementado nem provisionado.

Antes de existir um ambiente de PROD real, recomendamos definir com o time:
onde a aplicação/banco vão rodar (Autonomous Database na OCI Always Free
Tier é suficiente para o MVP, segundo a proposta original), como os segredos
serão injetados (não em arquivo `.env` versionável) e como serão feitos
backups do banco. Isso está refletido no checklist 🔴/🟠 em [Qualidade e
automação](#qualidade-e-automação).

---

## Testes

**Não confirmado**: não foi encontrado nenhum teste automatizado no
repositório (nenhum diretório `test/`, `tests/`, `spec/`, nem configuração de
utPLSQL, Playwright, Selenium etc.).

Sugestões (avaliadas em [Qualidade e automação](#qualidade-e-automação) mais
abaixo) — nenhuma foi implementada, pois isso exigiria decisões do time sobre
o que testar primeiro:

- **utPLSQL** para testes de unidade de lógica em PL/SQL, caso existam
  packages/procedures/functions próprias do projeto (hoje não encontramos
  nenhuma fora da exportação da aplicação APEX).
- **Playwright** ou **Selenium** para testes end-to-end da aplicação via
  navegador.

## Lint e formatação

**Não confirmado**: não há linter/formatter configurado no repositório hoje.
As páginas da aplicação (`f100/application/pages/*.sql`) são geradas pelo
APEX Builder e não costumam ser editadas manualmente, então lint tradicional
de código tem valor limitado. O que existe hoje que faria sentido "lintar" é:

- O próprio `docker-compose.yml` (validável com `docker compose config`).
- Os arquivos `.sql` de DDL/seed, se o time decidir adotar um formatter de SQL
  (ex.: [`sqlfluff`](https://sqlfluff.com/) com dialeto `oracle`).

Nenhuma dessas ferramentas foi adicionada — ver avaliação de custo/benefício
no checklist.

## Migrations e seeds

Não há uma ferramenta de migration (ex.: Flyway/Liquibase) neste projeto —
hoje a "estrutura" e os "dados" do banco são dois dumps SQL únicos:

- `database/ddl/schema_corlixhub.sql`: `CREATE TABLE` das tabelas do schema
  `WKSP_CORLIXHUB` (`COLABORADOR`, `COMUNICADO`, `EMPRESA`, `DEPARTAMENTO`,
  `CARGO`, entre outras — ver [Modelo de dados](#modelo-de-dados)).
- `database/seed/seed_corlixhub.sql`: `INSERT`s de dados de exemplo (uma
  "Empresa Piloto Corlix" fictícia com colaboradores de teste).

> Os dados em `database/seed/seed_corlixhub.sql` parecem ser fictícios/demo (CNPJ
> `00.000.000/0001-00`, "Empresa Piloto", e-mails como `@empresa.com`,
> `@fiap.com`) — mas isso **não pôde ser confirmado com certeza** apenas lendo
> o arquivo. Se algum desses dados for real (nomes/e-mails de pessoas reais),
> ele não deveria continuar versionado em texto puro no Git. Confirme com o
> time antes do primeiro commit.

Toda evolução de schema hoje precisaria ser feita manualmente e refletida de
volta nesses dumps. Se o schema crescer, vale considerar Flyway (ver
checklist 🟢 opcional).

---

## Comandos principais

| Comando | O que faz |
|---|---|
| `docker compose up -d` | Sobe os containers `db` e `ords` em background |
| `docker compose ps` | Mostra o status/health dos containers |
| `docker compose logs -f [db\|ords]` | Acompanha os logs |
| `docker compose down` | Para os containers, mantém os dados |
| `docker compose down -v` | Para os containers e apaga os volumes (reset total do banco) |
| `docker compose restart ords` | Reinicia só o ORDS (útil após mexer em `ords_config`) |
| `./scripts/setup.sh` / `.\scripts\setup.ps1` | Setup inicial guiado |

---

## Troubleshooting

**Não confirmado em todos os itens** — baseado na configuração do
`docker-compose.yml` e no comportamento documentado das imagens oficiais da
Oracle:

- **Porta já em uso (`1522` ou `8081`)**: altere `DB_HOST_PORT`/`ORDS_HOST_PORT`
  no seu `.env`.
- **Container `db` demora muito para ficar `healthy`**: é esperado na
  primeira subida (instalação do APEX no banco) — pode levar 5–15 min.
  Acompanhe com `docker compose logs -f db`.
- **`ords` fica reiniciando / erro de conexão com o banco**: normalmente
  significa que o `db` ainda não terminou de subir; o `depends_on` com
  `condition: service_healthy` já deveria evitar isso, mas confira
  `docker compose logs ords`.
- **Erro ao montar `./apex/`**: confirme que você descompactou o
  `apex_26.1.zip` diretamente na raiz do projeto (deve existir
  `./apex/core`), e não dentro de uma subpasta extra criada pelo zip.
- **Linux: erro de permissão em `oracle_oradata/`**: as imagens oficiais da
  Oracle geralmente ajustam a propriedade do volume automaticamente no
  entrypoint, mas em alguns hosts Linux pode ser necessário
  `sudo chown -R 54321:54321 oracle_oradata/` antes do primeiro
  `docker compose up`. **Não testado neste repositório.**
- **Senha rejeitada pelo Oracle**: a imagem oficial exige senha com no mínimo
  8 caracteres, ao menos 1 maiúscula e 1 número — ajuste `ORACLE_PWD`/
  `APEX_PWD` no `.env`.
- **Quero recomeçar do zero**: `docker compose down -v` remove os volumes;
  também é preciso apagar manualmente o conteúdo de `oracle_oradata/` e
  `ords_config/` no host, já que eles são bind mounts (não volumes
  gerenciados pelo Docker).

---

## Fluxo de desenvolvimento (features e bugs)

1. Atualize sua `DEV` local: `git checkout DEV && git pull`.
2. Crie uma branch a partir de `DEV`:
   - Nova funcionalidade: `feature/<nome-curto>`
   - Correção de bug (não urgente, encontrado em DEV/UAT): `bugfix/<nome-curto>`
3. Desenvolva na aplicação via APEX Builder, exporte a aplicação de volta
   para `f100/` (ver [Como executar em desenvolvimento](#como-executar-em-desenvolvimento)),
   e se necessário, atualize os dumps de schema/seed.
4. Faça commits seguindo a [convenção de commits](#convenção-de-commits).
5. Abra um Pull Request da sua branch para `DEV`.
6. Depois de aprovado e revisado, faça o merge em `DEV`.

Detalhes completos de promoção entre ambientes estão em
[Estratégia de branches](#estratégia-de-branches-git).

## Processo de deploy

Há um pipeline de **validação** (`.github/workflows/ci.yml`, roda em todo PR
para `DEV`/`UAT`/`PROD`), mas **não há deploy automatizado** — a promoção de
código entre ambientes e a instalação em cada um continuam manuais:

1. Promover o código para a branch do ambiente alvo (`UAT` ou `PROD`), como
   descrito em [Estratégia de branches](#estratégia-de-branches-git).
2. No ambiente alvo, importar a aplicação exportada (`f100/install.sql`) e
   aplicar eventuais alterações de schema pendentes.
3. Validar manualmente a aplicação no ambiente.

Uma sugestão de CI/CD (ainda não implementada) está na seção
[Qualidade e automação](#qualidade-e-automação).

---

## Estratégia de branches (Git)

O repositório segue um modelo de três branches principais, representando os
ambientes do projeto:

| Branch | Ambiente |
|---|---|
| `DEV` | Desenvolvimento |
| `UAT` | Testes / homologação |
| `PROD` | Produção |

> **Não confirmado**: o repositório já foi inicializado localmente com
> `git init` (branch padrão `main`), mas ainda não tem nenhum commit nem as
> branches `DEV`/`UAT`/`PROD` foram criadas. A estratégia abaixo é a proposta
> a ser aplicada assim que o primeiro commit e o remoto forem configurados.

<img width="1167" height="720" alt="Diagrama do fluxo de branches" src="https://github.com/user-attachments/assets/dbb87658-4f64-4de9-a8f3-60575c6a8683" />

### Branches principais (permanentes)

| Branch | Finalidade | Quem pode fazer merge nela |
|---|---|---|
| `PROD` | Reflete exatamente o que está em produção. Só recebe merge vindo de `UAT`. | Apenas responsável técnico/aprovador de release (ex.: tech lead), via Pull Request revisado. Nunca commit direto. |
| `UAT` | Ambiente de homologação/validação com o time de negócio. Recebe merge vindo de `DEV` quando um conjunto de features está pronto para validação. | Tech lead ou quem o time definir, via Pull Request. Nunca commit direto. |
| `DEV` | Integração contínua do trabalho do time. Recebe merge de `feature/*` e `bugfix/*`. | Qualquer dev do time, via Pull Request revisado por outro dev (mínimo 1 aprovação recomendado). |

### Branches auxiliares (temporárias)

| Branch | Criada a partir de | Nomenclatura | Mergeada de volta para |
|---|---|---|---|
| `feature/*` | `DEV` | `feature/comunicados-fixados`, `feature/upload-foto-colaborador` | `DEV` |
| `bugfix/*` | `DEV` (bug encontrado em DEV/UAT, não urgente) | `bugfix/data-comunicado-errada` | `DEV` |
| `hotfix/*` | `PROD` (problema crítico já em produção) | `hotfix/erro-login-500` | `PROD` **e** `UAT` **e** `DEV` (ver fluxo abaixo) |
| `release/*` (opcional) | `DEV`, quando quiser "congelar" um conjunto de features antes de mandar para `UAT` | `release/2026-08` | `UAT` |

`release/*` é opcional — só faz sentido se vocês quiserem agrupar várias
features em um pacote nomeado antes de promover para `UAT`. Se o fluxo for
simples (uma feature de cada vez ou um lote contínuo), pode promover
`DEV → UAT` diretamente sem essa branch intermediária.

### Fluxo normal: feature → DEV → UAT → PROD

```text
feature/comunicados-fixados
        │  (Pull Request, revisão de código, testes manuais)
        ▼
       DEV  ← integra várias features, é onde o time trabalha no dia a dia
        │  (quando um lote de features está pronto para validação de negócio)
        │  (Pull Request DEV → UAT)
        ▼
       UAT  ← time de negócio valida
        │  (após validação e aprovação formal)
        │  (Pull Request UAT → PROD)
        ▼
       PROD ← produção
```

Exemplo prático:

```bash
git checkout DEV
git pull
git checkout -b feature/comunicados-fixados

# ... desenvolve, exporta f100/, commita ...
git add .
git commit -m "feat(comunicado): adiciona opção de fixar comunicado no topo"
git push -u origin feature/comunicados-fixados

# Abrir PR feature/comunicados-fixados -> DEV no GitHub/GitLab
# Após aprovação e merge:

git checkout DEV
git pull
# Quando o time decidir que DEV está pronta para validação de negócio:
# Abrir PR DEV -> UAT
# Após validação do time de negócio em UAT:
# Abrir PR UAT -> PROD
```

### Pull Requests e code review

- Todo merge em `DEV`, `UAT` e `PROD` acontece via Pull Request — nunca
  commit direto nessas branches (recomenda-se configurar **proteção de
  branch** no GitHub/GitLab assim que o repositório for criado lá).
- Revisão mínima recomendada: **1 aprovação** de outra pessoa antes do merge
  em `DEV`; para `UAT`/`PROD`, recomenda-se aprovação do tech lead.
- O PR deve descrever o que mudou e, se aplicável, referenciar a tarefa/issue.

### Conflitos

- Resolva conflitos localmente antes de abrir/atualizar o PR:
  `git checkout feature/minha-branch && git fetch && git rebase DEV` (ou
  `git merge DEV`, se o time preferir merge a rebase).
- Para os arquivos de exportação do APEX (`f100/application/pages/*.sql`),
  conflitos costumam ser mais fáceis de resolver reexportando a página do
  zero pelo APEX Builder após reconciliar quem fez qual mudança, em vez de
  editar manualmente o SQL gerado.

### Rollback

- Se um problema for identificado logo após o merge em `PROD` e o commit
  "ruim" for o último: `git revert <commit>` na `PROD` (gera um commit novo
  que desfaz a mudança, mantendo histórico) e reaplique a instalação/deploy.
- Evite `git reset --hard` + `push --force` em `PROD`/`UAT`/`DEV` — são
  branches compartilhadas; reescrever histórico nelas afeta todo o time.

### Bug encontrado em UAT (não crítico)

```text
bugfix/corrige-filtro-departamento
        │
        ▼
       DEV   (corrige e valida)
        │
        ▼
       UAT   (nova validação)
```

Corrija a partir de `DEV` (não direto em `UAT`), valide, promova `DEV → UAT`
novamente.

### Hotfix crítico em produção

```text
                PROD (com bug crítico)
                  │
                  ▼
        hotfix/erro-login-500  (criada a partir de PROD)
                  │  corrige o mínimo necessário
                  ▼
                PROD  ← merge imediato após revisão expressa
                  │
                  ├──────────────► UAT   (mesma correção aplicada)
                  └──────────────► DEV   (mesma correção aplicada, evita regressão)
```

1. Crie a branch a partir de `PROD` (não de `DEV`, que pode ter mudanças
   ainda não validadas): `git checkout PROD && git checkout -b hotfix/erro-login-500`.
2. Corrija o mínimo necessário para resolver o incidente.
3. Abra PR `hotfix/erro-login-500 → PROD`, com revisão expressa (pode ser
   mais rápida que o fluxo normal, mas não pular revisão).
4. Após o merge em `PROD` e confirmação de que o incidente foi resolvido,
   **replique o mesmo commit/branch para `UAT` e `DEV`**
   (`git checkout UAT && git merge hotfix/erro-login-500`, idem em `DEV`) —
   isso evita que o bug "volte" na próxima promoção normal `DEV → UAT → PROD`.

---

## Convenção de commits

Baseada em [Conventional Commits](https://www.conventionalcommits.org/pt-br/).
Formato:

```text
<tipo>(<escopo opcional>): <descrição curta no imperativo>
```

| Tipo | Quando usar | Exemplo |
|---|---|---|
| `feat` | Nova funcionalidade | `feat(colaborador): adiciona upload de foto de perfil` |
| `fix` | Correção de bug (não urgente) | `fix(comunicado): corrige data de publicação exibida errada` |
| `hotfix` | Correção urgente aplicada direto a partir de `PROD` | `hotfix(login): corrige erro 500 ao autenticar em produção` |
| `refactor` | Mudança interna sem alterar comportamento | `refactor(pages): reorganiza processos da página de colaboradores` |
| `test` | Adição/ajuste de testes | `test(colaborador): adiciona teste utPLSQL para validação de e-mail` |
| `docs` | Documentação | `docs: atualiza instruções de instalação no README` |
| `chore` | Tarefas de manutenção sem impacto em código de produção | `chore: atualiza .gitignore` |
| `build` | Mudanças no processo de build/empacotamento | `build: atualiza versão do Oracle APEX para 26.1` |
| `ci` | Mudanças em pipelines de CI/CD | `ci: adiciona verificação de secret scanning` |
| `perf` | Melhoria de performance | `perf(comunicado): otimiza consulta da listagem de comunicados` |

`hotfix` **não faz parte** do Conventional Commits original, mas faz sentido
mantê-lo aqui como tipo próprio para diferenciar, no histórico, uma correção
normal (`fix`) de uma correção emergencial aplicada direto sobre `PROD` — já
que a estratégia de branches acima usa esse fluxo explicitamente.

Um hook de validação de mensagem de commit foi criado em
`scripts/git-hooks/commit-msg` (ver [Qualidade e automação](#qualidade-e-automação)).

---

## Como contribuir

1. Siga o [fluxo de desenvolvimento](#fluxo-de-desenvolvimento-features-e-bugs) acima.
2. Use a [convenção de commits](#convenção-de-commits).
3. Nunca faça commit de `apex/`, `oracle_oradata/`, `ords_config/`, `.env` ou
   qualquer credencial — todos já estão no `.gitignore`.
4. Ative o hook de validação de commits uma vez por clone:
   ```bash
   git config core.hooksPath scripts/git-hooks
   ```
5. Abra Pull Requests para `DEV` (nunca commit direto nas branches
   principais).

---

## Qualidade e automação

Avaliação do que faz sentido adotar agora vs. depois — nada abaixo foi
imposto sem necessidade; cada item tem o custo/benefício explicado.

| Prática | Recomendação | Custo/complexidade | Benefício |
|---|---|---|---|
| **Secret scanning + hooks básicos de higiene** (`pre-commit` + `gitleaks`, `detect-private-key`, `check-added-large-files`) | 🟢 Opcional, mas de baixo custo | Requer Python + instalar `pre-commit` uma vez por máquina | Evita commitar segredos (wallet, chaves) ou os 7,5 GB de `oracle_oradata/` por engano |
| **Hook de validação de mensagem de commit** (`scripts/git-hooks/commit-msg`, já criado) | 🟠 Recomendado | Zero dependências extra (usa só `bash`, já presente via Git Bash no Windows) | Mantém o histórico de commits consistente com a convenção acima |
| **CI leve no GitHub Actions** (`.github/workflows/ci.yml`, já criado): valida sintaxe do `docker-compose.yml`, roda secret scanning (`gitleaks`) e bloqueia commit acidental de `apex/`, `oracle_oradata/`, `ords_config/`, `META-INF/` | 🟠 Recomendado | Baixo — roda em segundos, sem infraestrutura própria | Pega cedo, em todo PR para `DEV`/`UAT`/`PROD`, erros de configuração e segredos vazados |
| **CI com smoke test completo (`docker compose up` de verdade)** | 🟢 Opcional, não implementado | Alto: exigiria hospedar um espelho autorizado da distribuição do Oracle APEX (~1,1 GB) acessível pelo runner, já que o download oficial requer aceite de licença manual | Detectaria também falhas na instalação do APEX/schema, não só erro de sintaxe |
| **utPLSQL para lógica em PL/SQL** | 🟢 Opcional | Só se existir lógica PL/SQL própria fora do APEX (não encontramos nenhuma hoje) | Cobertura de regras de negócio críticas |
| **Playwright/Selenium (E2E)** | 🟢 Opcional, futuro | Alto: exige manter scripts de UI sincronizados com as páginas APEX | Detecta regressões visíveis ao usuário |
| **Linter/formatter de SQL (`sqlfluff`)** | 🟢 Opcional | Baixo | Padroniza os dumps de DDL/seed, sem muito ganho nas páginas geradas pelo APEX Builder |
| **Migration tool (Flyway)** | 🟢 Opcional, futuro | Médio: exige reestruturar como o schema é versionado (hoje é um dump único) | Histórico incremental de mudanças de schema, útil se o time crescer |
| **Makefile** | ❌ Não recomendado | — | Não é nativo no Windows sem instalar `make` à parte — por isso optamos por `scripts/setup.sh` + `scripts/setup.ps1`, que funcionam nativamente nos três sistemas operacionais |
| **Dev Containers** | 🟢 Opcional, futuro | Médio | Só relevante se o time editar SQL/config fora do APEX Builder com frequência; hoje o desenvolvimento principal acontece dentro do APEX Builder via navegador, então o ganho é limitado |

---

## Portabilidade entre Windows, Linux e macOS

O que foi **verificado** no repositório:

- `docker-compose.yml` usa apenas bind mounts relativos (`./apex/`,
  `./oracle_oradata/`, `./ords_config/`) — o Docker resolve isso
  corretamente nos três sistemas operacionais.
- Nenhum caminho absoluto de máquina (`/Users/...`, `C:\...`, `/home/...`) foi
  encontrado em nenhum script `.sql`/`.xml`/`.yml` do projeto (foi feita uma
  busca em todo o repositório) — os únicos "caminhos" com aparência de
  `/Users`/`/home` encontrados estavam dentro de arquivos vendor do próprio
  APEX (`apex/core/...`, traduções do builder), não são específicos desta
  máquina.
- As duas únicas senhas do projeto (`ORACLE_PWD`, `APEX_PWD`) agora vêm de
  variáveis de ambiente (`.env`), não de valores fixos no `docker-compose.yml`.
- As portas usadas no host (`1522`, `8081`) evitam conflito com uma eventual
  instalação nativa do Oracle na porta padrão `1521`.

O que **não pôde ser confirmado** (exige testar de fato nas outras
plataformas):

- Comportamento do bind mount de `oracle_oradata/` em Linux nativo (possível
  necessidade de ajuste de permissão/UID, comum em imagens Oracle — ver
  Troubleshooting).
- Desempenho do Docker Desktop no Windows/WSL2 com os bind mounts (imagens
  Oracle com muitos arquivos pequenos, como `apex/images`, podem ser lentas
  em volumes montados via WSL2 dependendo de onde o projeto for clonado —
  recomenda-se clonar **dentro** do filesystem do WSL2, não em `/mnt/c/...`).

---

## Roadmap

A proposta original previa um cronograma de 6 meses até o MVP. O arquivo de
cronograma detalhado (`docs/cronograma.md`) **ainda não existe neste
repositório** — a pasta `docs/` não foi criada. Até essa lacuna ser
preenchida, o roadmap de alto nível é:

1. Consolidar o ambiente de desenvolvimento local (Docker Compose) — feito.
2. Modelar e versionar o schema do banco (`database/ddl`, `database/seed`) — feito.
3. Implementar as três features do MVP (organograma, histórico de carreira, mural de comunicados) no APEX.
4. Inicializar o repositório Git remoto e as branches `DEV`/`UAT`/`PROD` (ver [Estratégia de branches](#estratégia-de-branches-git)).
5. Provisionar o ambiente de produção na OCI (Autonomous Database + hospedagem) — ver [Como executar em produção](#como-executar-em-produção).
6. Validar em UAT com o time de negócio e promover para PROD.

## Status atual

🚧 Em desenvolvimento — MVP em construção como parte do Enterprise Challenge STO.

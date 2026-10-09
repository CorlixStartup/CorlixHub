# Backup do Corlix Hub

Pipeline que copia, de um Autonomous Database na OCI:

| Pasta no backup | Conteúdo | Gerado por |
|---|---|---|
| `apexlang/` | App 100 em APEXlang (mesmo formato de `corlixhub/`) | `apex export -exptype APEXLANG` |
| `sql/` | App 100 em SQL (`f100.sql`, com ACL e relatórios salvos) + checksum SHA-256 | `apex export -exptype SQL,CHECKSUM-SH256` |
| `workspace/` | Usuários e grupos do workspace (opcional; depende de permissão) | `apex export -expworkspace -expminimal` |
| `ddl/` | DDL do schema sem schema/tablespace, `01-tipos.sql` … `11-sinonimos.sql`, na ordem de recriação | `dbms_metadata` |
| `dados/` | Um CSV por tabela + `_contagens.csv`, `_colunas-especiais.csv` e `_exportar.sql` | `select` com `set sqlformat csv` |
| `manifesto.txt`, `sqlcl.log` | Data, ambiente, commit, versões e contagens; log do SQLcl | `backup.sh` |

Tudo vai num `corlixhub-<ambiente>-<AAAAMMDD-HHMMSS>.tar.gz` com `.sha256` ao lado.

**Primeira vez?** Siga o passo a passo em [`Etapas-backup.md`](./Etapas-backup.md): banco, Jenkins, credenciais, job, conferência e erros comuns.

> **Os backups têm dados pessoais dos colaboradores.** Não os versione (a pasta `backups/` está no `.gitignore`) e restrinja quem pode ver os artefatos do job no Jenkins.

## Arquivos

- `backup.sh`: valida as variáveis, conecta pelo SQLcl, confere o resultado, compacta e aplica a retenção.
- `backup.sql`: os exports e as consultas (chamado pelo `backup.sh`).
- `Jenkinsfile`: agenda (todo dia às 02h, horário de Brasília), roda por ambiente e arquiva os `.tar.gz`.
- `Dockerfile`: imagem do agente com Java 21 e SQLcl.
- `jenkins/`: Jenkins local em Docker para testar o pipeline (ver seção 3.1).
- `extrair-no-projeto.sh`: extrai um `.tar.gz` para `corlixhub/` e `database/` (ver seção 3.2).
- `publicar-no-git.sh`: commita o backup na `DEV` e abre PR para a `PROD` (ver seção 3.3).
- `Etapas-backup.md`: guia passo a passo da configuração, com conferências e erros comuns.

## 1. Preparar o banco (uma vez por ambiente)

O backup conecta como **dono do schema** (`WKSP_CORLIXHUB`), porque o `apex export` e as views `user_*` dependem disso. No Autonomous, conectado como `ADMIN` (Database Actions > SQL):

```sql
alter user WKSP_CORLIXHUB identified by "<senha-forte>" account unlock;
grant create session to WKSP_CORLIXHUB;
```

Baixe a wallet: OCI Console > Autonomous Database > **Database connection** > *Download wallet*. O alias do serviço (`<nome>_low`, `_medium`, `_high`) está no `tnsnames.ora` dentro do zip. Use o `_low` para não disputar recursos com a aplicação.

## 2. Rodar local (teste)

```bash
DB_USER=WKSP_CORLIXHUB DB_PASSWORD='<senha>' DB_SERVICE=corlixhub_low \
DB_WALLET=~/wallets/Wallet_corlixhub.zip \
MANTER_PASTA=true ./scripts/backup/backup.sh
```

Saída em `backups/local/`. Todas as variáveis estão no cabeçalho do `backup.sh`. Os caminhos não podem ter espaços, porque o SQLcl os recebe sem aspas.

## 3. Configurar o Jenkins

1. Plugins: *Pipeline*, *Docker Pipeline*, *Credentials Binding*. O agente precisa de Docker.
2. Credenciais (Manage Jenkins > Credentials), por ambiente:
   - `corlixhub-db-prd`: *Username with password* (`WKSP_CORLIXHUB` + senha)
   - `corlixhub-wallet-prd`: *Secret file* (o `Wallet_*.zip`)
   - `corlixhub-github` (uma só, para todos os ambientes): *Username with password* com o usuário do GitHub e um token. Só é usada com `PUBLICAR_GIT` (seção 3.3).
3. Ajuste o mapa `AMBIENTES` no `Jenkinsfile` com o alias de serviço de cada banco. Descomente o `DEV` quando ele existir.
4. Crie um job *Pipeline* > *Pipeline script from SCM*, com o repositório na branch `PROD` e o *Script Path* `scripts/backup/Jenkinsfile`.
5. Rode uma vez com **Build Now**. O primeiro build usa os valores padrão (`AMBIENTE = TODOS`) e registra os parâmetros e o agendamento. Depois aparece **Build with Parameters**.

### 3.1 Jenkins local em Docker

`jenkins/` sobe um Jenkins com o cliente Docker e os plugins acima, usando o Docker do host pelo `/var/run/docker.sock` para rodar o agente do `Dockerfile`:

```bash
cd scripts/backup/jenkins
docker compose up -d --build
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Abra http://localhost:8080, conclua o assistente e siga os passos 2 a 5 acima. O job busca o `Jenkinsfile` no remoto, então a branch configurada precisa ter `scripts/backup/` publicado.

- O container roda como `root` para acessar o socket do Docker Desktop. Use assim só na sua máquina.
- Mantenha o `jenkins_home` como volume nomeado: o Docker Pipeline repassa o workspace ao agente com `--volumes-from`, e uma pasta do host no lugar dele deixa o agente sem os arquivos.
- Cada build copia o `.tar.gz` e o `.sha256` para `backups/<ambiente>/` do projeto, apagando ali os arquivos com mais de 30 dias. Com `PUBLICAR_GIT` desmarcado, também extrai o backup do ambiente em `CORLIXHUB_EXTRAIR` (padrão `PRD`) com o `extrair-no-projeto.sh` (seção 3.2); marcado (padrão), as mudanças chegam pela `DEV` (seção 3.3). O projeto inteiro é montado em `/projeto` (variável `CORLIXHUB_PROJETO`). Num Jenkins sem essa variável não há cópia nem extração.
- Builds, credenciais e artefatos ficam no volume. `docker compose down` preserva tudo; `docker compose down -v` apaga, inclusive os backups arquivados.

No IntelliJ, os plugins *Jenkins Control* (jobs e builds) e *Jenkins Pipeline Linter Connector* (validar o `Jenkinsfile`) conectam em `http://localhost:8080` com um API token do seu usuário no Jenkins.

### 3.2 Extrair o backup no projeto

```bash
scripts/backup/extrair-no-projeto.sh backups/prd/corlixhub-prd-<data>.tar.gz
```

O Jenkins local roda isso sozinho a cada build. O script atualiza:

| Do backup | Para | Git |
|---|---|---|
| `apexlang/corlixhub/` | `corlixhub/` (pasta inteira trocada) | versionado |
| `sql/f100.sql` | `database/f100.sql` | versionado |
| `ddl/` | `database/ddl/` (pasta inteira trocada) | versionado |
| `dados/` + `manifesto.txt` | `database/dados/backup/` | **ignorado** (dados pessoais) |

- Um destino versionado com alteração não commitada, inclusive arquivo novo não rastreado, é pulado com aviso no log. Commite ou descarte suas mudanças e rode de novo. Na primeira extração, `database/ddl/` só volta a ser atualizada depois de commitada.
- Os arquivos de texto têm o fim de linha convertido para LF, como pede o `.gitattributes`.
- Depois da extração, revise com `git status` e `git diff` antes de commitar: o que mudou no APEX Builder aparece como alteração em `corlixhub/` e `database/f100.sql`.

### 3.3 Commit na DEV e PR para a PROD

Com o parâmetro `PUBLICAR_GIT` marcado (padrão, inclusive na execução agendada), o stage **Publicar no Git** roda o `publicar-no-git.sh` com o backup do ambiente em `AMBIENTE_GIT` (`PRD`) gerado no build:

1. Clona a `DEV` numa pasta temporária e extrai o backup nela com o `extrair-no-projeto.sh`.
2. Commita só `corlixhub/`, `database/f100.sql` e `database/ddl/` (os CSVs nunca entram), com a mensagem `chore(backup): Backup - Corlix Hub - dd/MM/yyyy as HH:mm` no horário de Brasília, e faz push para a `DEV`. Se nada mudou no banco, o commit é vazio, só como registro de que o backup rodou.
3. Abre um PR `DEV` → `PROD` com o título `Backup - Corlix Hub - dd/MM/yyyy as HH:mm`. Se já houver um aberto, o push só o atualiza.

Requisitos:
- Credencial `corlixhub-github` (*Username with password*): usuário do GitHub e um *fine-grained token* com acesso ao `CorlixStartup/corlix-hub` e permissões **Contents: Read and write** e **Pull requests: Read and write**.
- A `DEV` precisa aceitar push direto desse usuário. Se ela tiver proteção de branch que exige PR, libere o usuário no *bypass* da regra; senão o log mostra `push para DEV recusado`.
- O PR inclui qualquer outro commit da `DEV` que ainda não está na `PROD`: revise antes do merge.

Desmarque `PUBLICAR_GIT` para voltar ao fluxo antigo (extração na pasta local e commit manual, seção 3.2).

Retenção: os artefatos ficam 30 dias e o histórico dos builds 90 (`buildDiscarder`). Rodando local, o `backup.sh` apaga `.tar.gz` com mais de `RETENCAO_DIAS` (30).

## 4. Restauração

Ensaie a restauração num ambiente de teste antes de precisar dela de verdade.

```bash
shasum -a 256 -c corlixhub-prd-*.tar.gz.sha256   # ou sha256sum -c
tar -xzf corlixhub-prd-*.tar.gz
```

**Aplicação:** use `apex import -input <pasta>/apexlang/...` ou `@<pasta>/sql/f100.sql`, conectado no workspace de destino. Ver também o guia de import em `docs/ai-context/01-arquitetura-e-ambiente.md`.

**Schema vazio:** rode `ddl/01-tipos.sql` até `ddl/11-sinonimos.sql`, nessa ordem, e depois recompile:

```sql
exec dbms_utility.compile_schema(schema => user, compile_all => false);
```

**Dados**, no SQLcl, na ordem que as FKs exigirem (ou com as FKs desabilitadas):

```sql
-- Mesmos formatos usados no backup
alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
alter session set nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS.FF6';
alter session set nls_timestamp_tz_format = 'YYYY-MM-DD HH24:MI:SS.FF6 TZH:TZM';
alter session set nls_numeric_characters = '.,';

alter table COLABORADOR disable all triggers;   -- evita disparar auditoria na carga
load table COLABORADOR dados/COLABORADOR.csv
alter table COLABORADOR enable all triggers;
```

Pontos de atenção:
- **Colunas BLOB** (anexos, imagens, logotipo) estão em base64 (ver `_colunas-especiais.csv`). Carregue o CSV numa tabela de apoio com essa coluna como `CLOB` e converta no insert com `apex_web_service.clobbase642blob(coluna)`.
- **Identity `GENERATED ALWAYS`** (ex.: `APP_LOG.ID`) não aceita valor no insert. Troque temporariamente para `generated by default` e depois ajuste o próximo valor com `alter table ... modify ... generated always as identity (start with limit value)`.
- Confira as linhas carregadas contra `dados/_contagens.csv`.

## O que não está no backup

- Arquivos de wallet, credenciais e configuração do ORDS.
- Módulos REST do ORDS e jobs do `dbms_scheduler` do schema.
- Colunas marcadas como `nao exportada` em `_colunas-especiais.csv` (BFILE, LONG, tipos de objeto). No DDL de 07/10/2026, a única é `HTMLDB_PLAN_TABLE.OTHER` (LONG), da tabela de plano de execução criada pelo APEX, que não guarda dados de negócio.

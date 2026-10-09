# Backup do Corlix Hub · passo a passo

Este guia leva do zero até o backup diário funcionando: preparar o banco na OCI, subir o Jenkins local, cadastrar as credenciais, criar o job, conferir o primeiro backup e manter a rotina. No fim há uma seção de erros comuns, com a causa e a solução de cada um.

O [`README.md`](./README.md) desta pasta é a referência técnica: o que vai no backup, as variáveis e a restauração. Este guia é o roteiro para executar.

> **Os backups têm dados pessoais dos colaboradores.** O repositório é público. Nunca commite `backups/` nem `database/dados/backup/` (os dois estão no `.gitignore`), não exponha a porta 8080 do Jenkins e não mande senha ou wallet por chat ou pelo Git.

---

## 0. Como funciona

```
Seu computador (Docker)                         OCI
┌─────────────────────────────────┐             ┌──────────────────────────────┐
│ Jenkins  http://localhost:8080  │             │ Autonomous Database          │
│  └─ agente (Java 21 + SQLcl) ───┼─ wallet ──▶ │  ├─ APEX: app 100 CORLIXHUB  │
│        │                        │   (mTLS)    │  └─ schema WKSP_CORLIXHUB    │
│        ▼                        │             └──────────────────────────────┘
│ pasta do projeto (corlix-hub/)  │
│  ├─ backups/prd/*.tar.gz        │  ← cópia de cada backup (fora do Git)
│  ├─ corlixhub/                  │  ← app em APEXlang, atualizada pelo backup
│  └─ database/                   │  ← f100.sql, ddl/ e dados/backup/ (CSVs, fora do Git)
└─────────────────────────────────┘
```

Todo dia, entre 02:00 e 02:59 (horário de Brasília), o Jenkins:

1. Baixa o `Jenkinsfile` do GitHub e monta o agente a partir de `scripts/backup/Dockerfile`.
2. Roda o `backup.sh`, que conecta no banco pelo SQLcl e exporta a app, o workspace, o DDL e os dados.
3. Gera um `corlixhub-prd-<AAAAMMDD-HHMMSS>.tar.gz` com `.sha256` e o guarda como artefato do build por 30 dias.
4. Clona a `DEV`, extrai o backup nela, commita `corlixhub/`, `database/f100.sql` e `database/ddl/` com a mensagem `chore(backup): Backup - Corlix Hub - dd/MM/yyyy as HH:mm` (vazio se nada mudou no banco) e abre um PR `DEV` → `PROD` (stage **Publicar no Git**).
5. Copia o arquivo para `backups/prd/` do projeto. Com `PUBLICAR_GIT` desmarcado, em vez do passo 4 ele extrai o backup na pasta local do projeto.

Hoje existe um único ambiente, chamado `PRD` no `Jenkinsfile`. O nome é só um rótulo do banco atual.

---

## 1. Pré-requisitos

| Item | Para quê | Como conferir |
|---|---|---|
| Docker Desktop rodando | Jenkins e agente rodam em containers | `docker ps` responde sem erro |
| Clone do repositório | O Jenkins grava os backups na pasta do projeto | `git -C ~/www/corlix-hub status` |
| Acesso ao OCI Console | Baixar a wallet | Você vê o Autonomous Database do Corlix Hub |
| Usuário `ADMIN` do banco (ou alguém que o tenha) | Liberar o `WKSP_CORLIXHUB` | Login no Database Actions como `ADMIN` |

O caminho da pasta do projeto não pode ter espaços, porque o SQLcl recebe os caminhos sem aspas.

---

## 2. Preparar o banco (uma vez)

O backup conecta como **dono do schema**, `WKSP_CORLIXHUB`. **Não use o `ADMIN`**: com ele a app é exportada, mas o DDL e os dados saem vazios e o build falha (ver [erros comuns](#9-erros-comuns)).

### 2.1 Liberar o `WKSP_CORLIXHUB`

1. OCI Console > **Autonomous Database** > clique no banco do Corlix Hub.
2. **Database Actions** > **SQL**, conectado como `ADMIN`.
3. Rode, trocando a senha:
   ```sql
   alter user WKSP_CORLIXHUB identified by "<senha-forte>" account unlock;
   grant create session to WKSP_CORLIXHUB;
   ```
4. Guarde a senha num gerenciador de senhas. Ela vai para o Jenkins no passo 4.

A senha não pode ter aspas duplas (`"`).

### 2.2 Baixar a wallet

1. Na página do banco: **Database connection** > **Download wallet**.
2. Defina a senha da wallet que o console pede. O backup não a usa, mas o download exige.
3. Salve o `Wallet_<nome>.zip` fora do projeto, por exemplo em `~/wallets/`.

### 2.3 Conferir o alias do serviço

O `Jenkinsfile` usa o alias `corlixhub_low`. Confira se ele existe na sua wallet:

```bash
unzip -p ~/wallets/Wallet_*.zip tnsnames.ora | grep -o '^[a-z0-9_]*_low'
```

**Confira:** a saída deve ser `corlixhub_low`. Se for outro nome, troque o valor de `servico` no mapa `AMBIENTES` do `scripts/backup/Jenkinsfile`, commite e faça push. Use sempre o `_low`, para não disputar recursos com a aplicação.

---

## 3. Subir o Jenkins local

### 3.1 Iniciar o container

```bash
cd ~/www/corlix-hub/scripts/backup/jenkins
docker compose up -d --build
```

O primeiro `--build` leva alguns minutos: ele baixa a imagem do Jenkins, instala o cliente Docker e os plugins.

**Confira:**
```bash
docker ps --filter name=jenkins     # STATUS "Up"
curl -sI http://localhost:8080 | grep X-Jenkins
```

### 3.2 Assistente inicial

1. Pegue a senha temporária:
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```
2. Abra http://localhost:8080 e cole a senha em **Unlock Jenkins**.
3. **Customize Jenkins** > **Install suggested plugins**. Os plugins que o backup exige (*Pipeline*, *Docker Pipeline*, *Credentials Binding*, *Git*) já vêm na imagem.
4. **Create First Admin User**: crie o seu usuário. A partir daqui, use sempre ele, não o `admin`.
5. **Instance Configuration**: mantenha `http://localhost:8080/` > **Save and Finish** > **Start using Jenkins**.

### 3.3 O que o container monta

| No container | No seu computador | Para quê |
|---|---|---|
| `/var/jenkins_home` | volume Docker `jenkins_home` | Jobs, credenciais, builds e artefatos |
| `/projeto` | a raiz do projeto | Cópia e extração dos backups |
| `/var/run/docker.sock` | Docker Desktop | O Jenkins sobe o agente |

- `docker compose down` para o Jenkins e **mantém** tudo.
- `docker compose down -v` **apaga** o volume: jobs, credenciais e backups arquivados.
- O container roda como `root` para acessar o Docker Desktop. Use essa configuração só na sua máquina.

---

## 4. Cadastrar as credenciais

> **Atenção:** a tela **Manage Jenkins > Credential Providers** (com *Restrictions*, *Excludes*, *Provider*) **não** é o lugar do cadastro. Ela serve para bloquear tipos de credencial. Deixe-a como está.

Caminho: **Manage Jenkins** > **Credentials** > na tabela *Stores scoped to Jenkins*, clique em **System** > **Global credentials (unrestricted)** > **+ Add Credentials**.

### 4.1 Credencial do banco

| Campo | Valor |
|---|---|
| Kind | **Username with password** |
| Scope | Global |
| Username | `WKSP_CORLIXHUB` (**não** `ADMIN`) |
| Password | a senha do passo 2.1 |
| ID | `corlixhub-db-prd` (exatamente assim) |
| Description | `Banco PRD - dono do schema` (opcional) |

### 4.2 Credencial da wallet

| Campo | Valor |
|---|---|
| Kind | **Secret file** |
| Scope | Global |
| File | o `Wallet_<nome>.zip` do passo 2.2 |
| ID | `corlixhub-wallet-prd` (exatamente assim) |

### 4.3 Credencial do GitHub

Usada pelo stage **Publicar no Git** para commitar na `DEV` e abrir o PR para a `PROD`.

1. No GitHub: **Settings** > **Developer settings** > **Personal access tokens** > **Fine-grained tokens** > **Generate new token**. *Resource owner* `CorlixStartup`, *Repository access* só `corlix-hub`, permissões **Contents: Read and write** e **Pull requests: Read and write**.
2. No Jenkins:

| Campo | Valor |
|---|---|
| Kind | **Username with password** |
| Scope | Global |
| Username | seu usuário do GitHub |
| Password | o token |
| ID | `corlixhub-github` (exatamente assim) |

Se a `DEV` tiver proteção de branch que exige PR, adicione esse usuário no *bypass* da regra.

**Confira:** a lista *Global credentials* mostra os três IDs. Se o campo ID ficar em branco, o Jenkins gera um ID aleatório e o build falha com *credentials not found*.

---

## 5. Criar o job

1. **Dashboard** > **New Item**.
2. Nome: `corlixhub-backup`. Tipo: **Pipeline**. **OK**.
3. Na seção **Pipeline**:

   | Campo | Valor |
   |---|---|
   | Definition | **Pipeline script from SCM** |
   | SCM | **Git** |
   | Repository URL | `https://github.com/CorlixStartup/corlix-hub.git` |
   | Credentials | *- none -* (o repositório é público) |
   | Branch Specifier | `*/PROD` (veja a observação abaixo) |
   | Script Path | `scripts/backup/Jenkinsfile` |

4. **Save**.

**Qual branch usar:** o Jenkins lê o `Jenkinsfile` e os scripts dessa branch. Use `*/PROD` quando `scripts/backup/` já estiver na `PROD`. Enquanto as mudanças ainda estiverem só na `DEV` (ou numa `feature/*` ainda não mergeada), aponte para ela e troque depois. Se a branch configurada for apagada, o backup das 02h falha.

---

## 6. Primeiro backup

### 6.1 Rodar

1. No job, clique em **Build Now**. O primeiro build roda com os valores padrão (`AMBIENTE = TODOS`, que hoje é só o `PRD`) e registra os parâmetros e o agendamento.
2. Daí em diante, o botão vira **Build with Parameters**. Para um backup manual, use `AMBIENTE = PRD`, `APP_ID = 100` e `EXPORTAR_WORKSPACE` marcado.

O primeiro build demora mais, porque monta a imagem do agente (Java 21, SQLcl e git). Os seguintes reaproveitam a imagem e levam de 1 a 2 minutos.

### 6.2 Conferir o log

No build, abra **Console Output**. Um build correto tem estas linhas, nesta ordem:

```
+ rm -rf backups
+ bash scripts/backup/backup.sh
[hh:mm:ss] Backup de PRD (app 100, serviço corlixhub_low) em /var/jenkins_home/workspace/...
[hh:mm:ss] OK: .../corlixhub-prd-<data>.tar.gz (11M, 17 tabelas, 41 arquivos APEXlang)
+ dest=/projeto/backups/prd
[extrair] corlixhub atualizado.
[extrair] database/f100.sql atualizado.
[extrair] database/ddl atualizado.
[extrair] database/dados/backup atualizado.
+ rm -rf backups
Finished: SUCCESS
```

Os números (tamanho, tabelas, arquivos) crescem com o projeto. Linhas `AVISO:` não derrubam o build, mas leia cada uma (ver [erros comuns](#9-erros-comuns)).

### 6.3 Conferir os arquivos

```bash
cd ~/www/corlix-hub

# 1. O backup chegou e está íntegro
ls -lh backups/prd/
(cd backups/prd && shasum -a 256 -c "$(ls -t *.sha256 | head -1)")   # deve dizer OK

# 2. O manifesto confere
cat database/dados/backup/manifesto.txt
#   usuario=WKSP_CORLIXHUB   (não ADMIN)
#   tabelas=17 (ou mais)     arquivos_workspace=1

# 3. Os dados estão fora do Git
git check-ignore database/dados/backup/COLABORADOR.csv   # imprime o caminho = ignorado

# 4. O que mudou no APEX desde o último commit
git status
```

Os arquivos também ficam em **Build Artifacts**, na página do build.

---

## 7. Rotina depois do backup

A cada backup, o Jenkins commita na `DEV` o que mudou no **APEX Builder** e deixa um PR `DEV` → `PROD` aberto (ou atualizado).

1. Abra o PR `Backup - Corlix Hub - …` no GitHub e revise o diff. As mudanças devem ser alterações feitas de propósito no Builder. O PR também traz outros commits da `DEV` que ainda não estão na `PROD`.
2. Faça o merge quando estiver tudo certo.
3. Na sua máquina, `git pull` na `DEV` traz o commit do backup.

**Com `PUBLICAR_GIT` desmarcado** (fluxo manual), a extração vai para a pasta do projeto e as mudanças aparecem no `git status`. Revise com `git diff`, commite numa branch `feature/*` e abra PR para `DEV`:
   ```bash
   git add corlixhub database/f100.sql database/ddl
   git commit -m "chore(apex): sincroniza a app e o DDL com o banco"
   ```

**Proteção do trabalho local:** se um desses destinos tiver alteração não commitada, inclusive arquivo novo, a extração **pula esse destino** e o log mostra:

```
[extrair] AVISO: corlixhub tem alterações não commitadas; não foi atualizado.
```

O `.tar.gz` é salvo do mesmo jeito. Commite ou descarte suas mudanças e extraia de novo (passo 8.2), ou espere o próximo backup.

**Agendamento:** o Jenkins roda no seu computador. Se ele estiver desligado, dormindo ou com o Docker fechado às 02h, o backup daquele dia não acontece ou roda atrasado. Confira o histórico do job de vez em quando.

**Retenção:** os artefatos ficam 30 dias no Jenkins, e o histórico dos builds 90 dias. Em `backups/prd/`, arquivos com mais de 30 dias são apagados a cada build.

---

## 8. Rodar sem o Jenkins

### 8.1 Backup direto pelo terminal

Precisa do SQLcl instalado (`brew install sqlcl`):

```bash
cd ~/www/corlix-hub
DB_USER=WKSP_CORLIXHUB DB_PASSWORD='<senha>' DB_SERVICE=corlixhub_low \
DB_WALLET=~/wallets/Wallet_corlixhub.zip \
./scripts/backup/backup.sh
```

A saída vai para `backups/local/`. A senha fica no histórico do shell, então prefira o Jenkins para o dia a dia.

### 8.2 Extrair um backup que você já tem

```bash
scripts/backup/extrair-no-projeto.sh backups/prd/corlixhub-prd-<data>.tar.gz
```

Use para reaplicar um backup depois de commitar suas mudanças, ou para voltar o projeto ao estado de um backup antigo.

---

## 9. Erros comuns

| Mensagem no log | Causa | Solução |
|---|---|---|
| `ERRO: Nenhum CREATE TABLE em ddl/03-tabelas.sql.` | A credencial `corlixhub-db-prd` usa `ADMIN`. O `ADMIN` exporta a app, mas não enxerga as tabelas do schema. | Troque o *Username* da credencial para `WKSP_CORLIXHUB` (passos 2.1 e 4.1). |
| `ORA-01017: invalid username/password` | Senha errada na credencial. | Atualize a credencial (**Update**) com a senha do passo 2.1. |
| `ORA-28000: The account is locked` | O `WKSP_CORLIXHUB` foi bloqueado. | Rode de novo o `alter user ... account unlock` do passo 2.1. |
| `ORA-12154` / `ORA-12506` / `TNS: could not resolve` | O alias em `AMBIENTES` não existe na wallet. | Refaça o passo 2.3. |
| `Could not find credentials entry with ID 'corlixhub-...'` | ID da credencial digitado diferente. | Recrie a credencial com o ID exato (passo 4). |
| `Unable to find scripts/backup/Jenkinsfile` ou `Couldn't find any revision to build` | A branch do job não existe no GitHub ou não tem `scripts/backup/`. | Ajuste o *Branch Specifier* (passo 5). |
| `docker: not found` | O Jenkins não foi iniciado pelo `docker-compose.yml` desta pasta. | Suba com `docker compose up -d --build` (passo 3.1). |
| `PROJETO_LOCAL vazia no agente` | O container foi criado com um `docker-compose.yml` antigo. | `cd scripts/backup/jenkins && docker compose up -d` |
| `[extrair] AVISO: <pasta> tem alterações não commitadas` | Proteção do trabalho local (passo 7). | Commite ou descarte e rode o passo 8.2. |
| `push para DEV recusado` | Token sem **Contents: Read and write** ou a `DEV` exige PR. | Ajuste o token ou libere o usuário no *bypass* da proteção de branch (passo 4.3). |
| `não consegui listar os PRs` / `Bad credentials` | Token inválido, expirado ou sem acesso ao repositório. | Gere outro token e atualize a credencial `corlixhub-github` (passo 4.3). |
| `PR não aberto: ... No commits between PROD and DEV` | A `PROD` já tem tudo o que está na `DEV`. | Nada a fazer. |
| `AVISO: export do workspace não gerou arquivos` | O `WKSP_CORLIXHUB` não tem permissão para exportar o workspace. O resto do backup está completo. | Opcional: desmarque `EXPORTAR_WORKSPACE` ou peça a permissão ao administrador do APEX. |
| `--- erros nos arquivos em spool ---` seguido de `ORA-...` | Um erro do Oracle durante o DDL ou os dados. A linha mostra o arquivo e a mensagem. | Pesquise o código ORA-. Se for passageiro (rede, banco reiniciando), rode o build de novo. |
| `ERRO: SQLcl terminou com erro.` sem detalhe | Conexão interrompida, por exemplo com o computador dormindo durante o build. | Rode de novo. Se repetir, mande o `sqlcl.log` dos *Build Artifacts* para o time. |

**Outros sintomas:**

- **Vários `.tar.gz` iguais de uma vez em `backups/prd/`:** acontecia em versões antigas do `Jenkinsfile`, quando um build falhava na cópia. A versão atual limpa o workspace no início e no fim. Apague os arquivos repetidos e mantenha o mais recente.
- **Arquivos `.css` do tema aparecem como modificados, mas o `git diff` está vazio:** o índice do Git guardava o tamanho de uma versão antiga com fim de linha Windows. Rode `git add` nesses arquivos. Isso não muda conteúdo e resolve de vez.
- **O backup das 02h não rodou:** confira se o computador e o Docker Desktop estavam ligados. Rode manualmente com **Build with Parameters**.

---

## 10. Adicionar outro ambiente (quando existir)

1. Repita o passo 2 no banco novo e confira o alias (por exemplo `corlixhubdev_low`).
2. Cadastre `corlixhub-db-dev` e `corlixhub-wallet-dev` (passo 4, com os IDs trocados).
3. No `Jenkinsfile`, descomente a linha `DEV` do mapa `AMBIENTES` e ajuste o `servico`.
4. Commite, faça push e rode **Build with Parameters** com `AMBIENTE = DEV`.

A extração no projeto continua usando só o ambiente definido em `CORLIXHUB_EXTRAIR` no `jenkins/docker-compose.yml` (hoje `PRD`). Os backups de `DEV` ficam em `backups/dev/`.

---

## 11. Opcional: acompanhar pelo IntelliJ

1. **Settings > Plugins > Marketplace**: instale **Jenkins Control** e **Jenkins Pipeline Linter Connector**.
2. No Jenkins, gere um token: clique no seu usuário (canto superior direito) > **Security** > **API Token** > **Add new token**.
3. **Settings > Tools > Jenkins Plugin**: URL `http://localhost:8080`, seu usuário e o token.
4. O painel *Jenkins* mostra o job, permite disparar builds com parâmetros e ler o log. **Tools > Validate Jenkinsfile** confere a sintaxe antes do commit.

---

## 12. Checklist

- [ ] `WKSP_CORLIXHUB` desbloqueado, com senha guardada (2.1)
- [ ] Wallet baixada e alias `_low` conferido (2.2, 2.3)
- [ ] Jenkins em http://localhost:8080 com o seu usuário admin (3)
- [ ] Credenciais `corlixhub-db-prd` (usuário `WKSP_CORLIXHUB`), `corlixhub-wallet-prd` e `corlixhub-github` (4)
- [ ] Job `corlixhub-backup` apontando para a branch certa (5)
- [ ] Build com `Finished: SUCCESS` e as linhas `[extrair]` e `[publicar]` no log (6.2)
- [ ] Commit `chore(backup): Backup - Corlix Hub - …` na `DEV` e PR para a `PROD` aberto (7)
- [ ] `.sha256` confere e `manifesto.txt` mostra `usuario=WKSP_CORLIXHUB` (6.3)
- [ ] Restauração ensaiada num schema de teste ([README, seção 4](./README.md#4-restauração))

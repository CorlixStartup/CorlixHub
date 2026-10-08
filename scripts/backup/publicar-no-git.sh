#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Corlix Hub — publica um backup (.tar.gz do backup.sh) no GitHub
#
# Uso: scripts/backup/publicar-no-git.sh <corlixhub-*.tar.gz>
#
# 1. Clona a branch GIT_BRANCH (DEV) numa pasta temporária.
# 2. Extrai o backup nela com o extrair-no-projeto.sh.
# 3. Commita só corlixhub/, database/f100.sql e database/ddl/ (os CSVs com dados
#    pessoais nunca entram) com a mensagem
#    "chore(backup): Backup - Corlix Hub - dd/MM/yyyy as HH:mm" e faz push.
# 4. Abre um PR de GIT_BRANCH para GIT_BRANCH_PR (PROD), se ainda não houver um
#    aberto. Com um PR aberto, o push já o atualiza.
#
# Variáveis de ambiente:
#   GIT_USER        obrigatória  usuário do GitHub dono do token
#   GIT_TOKEN       obrigatória  token com Contents e Pull requests (leitura e escrita)
#   GITHUB_REPO     opcional     dono/repositório (padrão: CorlixStartup/CorlixHub)
#   GIT_BRANCH      opcional     branch que recebe o commit (padrão: DEV)
#   GIT_BRANCH_PR   opcional     base do PR (padrão: PROD)
#   GIT_AUTOR_NOME  opcional     autor do commit (padrão: Jenkins Backup Corlix Hub)
#   GIT_AUTOR_EMAIL opcional     e-mail do autor (padrão: backup@corlixhub.local)
#   BUILD_URL       opcional     link do build, citado no commit e no PR (o Jenkins define)
# -----------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ARQUIVO="${1:?Uso: $0 <corlixhub-*.tar.gz>}"
: "${GIT_USER:?Defina GIT_USER}"
: "${GIT_TOKEN:?Defina GIT_TOKEN}"
GITHUB_REPO="${GITHUB_REPO:-CorlixStartup/CorlixHub}"
GIT_BRANCH="${GIT_BRANCH:-DEV}"
GIT_BRANCH_PR="${GIT_BRANCH_PR:-PROD}"
GIT_AUTOR_NOME="${GIT_AUTOR_NOME:-Jenkins Backup Corlix Hub}"
GIT_AUTOR_EMAIL="${GIT_AUTOR_EMAIL:-backup@corlixhub.local}"

log() { printf '[publicar] %s\n' "$*"; }
falhar() { echo "ERRO: $*" >&2; exit 1; }

[ -f "$ARQUIVO" ] || falhar "arquivo não encontrado: $ARQUIVO"
command -v jq >/dev/null 2>&1 || falhar "jq não encontrado (ver scripts/backup/Dockerfile)."
ARQUIVO="$(cd "$(dirname "$ARQUIVO")" && pwd)/$(basename "$ARQUIVO")"

# Horário de Brasília, independente do fuso do agente.
DATA="$(TZ=America/Sao_Paulo date +'%d/%m/%Y as %H:%M')"
MENSAGEM="chore(backup): Backup - Corlix Hub - $DATA"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
CLONE="$TMP/repo"

# O token vai por um credential helper que lê as variáveis de ambiente: não
# aparece na URL, no .git/config nem na lista de processos.
export GIT_TERMINAL_PROMPT=0
AUTH='!f() { test "$1" = get && printf "username=%s\npassword=%s\n" "$GIT_USER" "$GIT_TOKEN"; }; f'

log "Clonando $GITHUB_REPO ($GIT_BRANCH)."
git -c credential.helper= -c "credential.helper=$AUTH" \
  clone --quiet --depth 1 --single-branch --branch "$GIT_BRANCH" \
  "https://github.com/$GITHUB_REPO.git" "$CLONE"
git -C "$CLONE" config credential.helper "$AUTH"
git -C "$CLONE" config user.name "$GIT_AUTOR_NOME"
git -C "$CLONE" config user.email "$GIT_AUTOR_EMAIL"

bash "$SCRIPT_DIR/extrair-no-projeto.sh" "$ARQUIVO" "$CLONE"

# Só os destinos versionados. database/dados/backup/ (CSVs) fica de fora mesmo
# se o .gitignore mudar.
git -C "$CLONE" add -A -- corlixhub database/f100.sql database/ddl

if git -C "$CLONE" diff --cached --quiet; then
  log "Nada mudou no banco desde o último commit em $GIT_BRANCH; sem commit."
else
  git -C "$CLONE" diff --cached --stat | tail -n 1 | sed 's/^/[publicar] /'
  git -C "$CLONE" commit --quiet --no-verify \
    -m "$MENSAGEM" \
    -m "Gerado pelo Jenkins a partir de $(basename "$ARQUIVO").${BUILD_URL:+ Build: $BUILD_URL}"
  git -C "$CLONE" push --quiet origin "HEAD:refs/heads/$GIT_BRANCH" \
    || falhar "push para $GIT_BRANCH recusado. Confira o token e se a branch exige PR (proteção de branch)."
  log "Commit $(git -C "$CLONE" rev-parse --short HEAD) enviado para $GIT_BRANCH: $MENSAGEM"
fi

# --- Pull request GIT_BRANCH -> GIT_BRANCH_PR --------------------------------
api() {
  curl -sS -H "Authorization: Bearer $GIT_TOKEN" \
       -H "Accept: application/vnd.github+json" \
       -H "X-GitHub-Api-Version: 2022-11-28" "$@"
}

DONO="${GITHUB_REPO%%/*}"
ABERTO="$(api "https://api.github.com/repos/$GITHUB_REPO/pulls?state=open&head=$DONO:$GIT_BRANCH&base=$GIT_BRANCH_PR" \
  | jq -r 'if type == "array" then (.[0].html_url // "") else error(.message // "resposta inesperada") end')" \
  || falhar "não consegui listar os PRs de $GITHUB_REPO."

if [ -n "$ABERTO" ]; then
  log "PR $GIT_BRANCH -> $GIT_BRANCH_PR já aberto, atualizado pelo push: $ABERTO"
  exit 0
fi

CORPO="$(jq -n \
  --arg title "Backup - Corlix Hub - $DATA" \
  --arg head "$GIT_BRANCH" --arg base "$GIT_BRANCH_PR" \
  --arg body "Backup automático gerado pelo Jenkins a partir de \`$(basename "$ARQUIVO")\`.${BUILD_URL:+ Build: $BUILD_URL}

Atualiza \`corlixhub/\`, \`database/f100.sql\` e \`database/ddl/\` com o que está no banco. Revise o diff antes do merge: ele inclui também qualquer outro commit da $GIT_BRANCH que ainda não está na $GIT_BRANCH_PR." \
  '{title: $title, head: $head, base: $base, body: $body}')"

RESPOSTA="$TMP/pr.json"
STATUS="$(api -o "$RESPOSTA" -w '%{http_code}' -X POST -d "$CORPO" "https://api.github.com/repos/$GITHUB_REPO/pulls")"
case "$STATUS" in
  201) log "PR aberto: $(jq -r .html_url "$RESPOSTA")" ;;
  422) log "PR não aberto: $(jq -r '[.message] + [.errors[]?.message // empty] | join(" ")' "$RESPOSTA")" ;;
  *)   falhar "GitHub respondeu $STATUS ao abrir o PR: $(jq -r '.message // .' "$RESPOSTA")" ;;
esac

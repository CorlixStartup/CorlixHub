#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Corlix Hub — extrai um backup (.tar.gz do backup.sh) para dentro do projeto
#
# Uso: scripts/backup/extrair-no-projeto.sh <corlixhub-*.tar.gz> [raiz-do-projeto]
#
# Destinos (relativos à raiz do projeto):
#   apexlang/corlixhub/  ->  corlixhub/               (fonte APEXlang da app)
#   sql/f100.sql         ->  database/f100.sql        (export SQL da app)
#   ddl/                 ->  database/ddl/            (DDL do schema)
#   dados/ + manifesto   ->  database/dados/backup/   (CSVs; fora do Git)
#
# Um destino versionado com alterações não commitadas é pulado com aviso, para
# não perder trabalho local. Os dados não passam por essa checagem porque não
# são versionados. Sem git disponível, os destinos versionados são pulados.
# -----------------------------------------------------------------------------
set -euo pipefail

ARQUIVO="${1:?Uso: $0 <corlixhub-*.tar.gz> [raiz-do-projeto]}"
RAIZ="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

log() { printf '[extrair] %s\n' "$*"; }

[ -f "$ARQUIVO" ] || { echo "ERRO: arquivo não encontrado: $ARQUIVO" >&2; exit 1; }
[ -d "$RAIZ/corlixhub" ] && [ -d "$RAIZ/database" ] \
  || { echo "ERRO: $RAIZ não parece a raiz do Corlix Hub (faltam corlixhub/ ou database/)." >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
tar -xzf "$ARQUIVO" -C "$TMP"
BASE="$(find "$TMP" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
[ -f "$BASE/apexlang/corlixhub/application.apx" ] \
  || { echo "ERRO: $ARQUIVO não tem apexlang/corlixhub/application.apx." >&2; exit 1; }

# O APEX devolve alguns static files com CRLF; o .gitattributes do projeto usa LF.
# Sem isso o git os mostraria como alterados e a próxima extração pularia corlixhub/.
grep -rIl $'\r' "$BASE/apexlang" "$BASE/sql" "$BASE/ddl" 2>/dev/null | while IFS= read -r f; do
  tr -d '\r' < "$f" > "$f.lf" && cat "$f.lf" > "$f" && rm -f "$f.lf"
done

TEM_GIT=false
if command -v git >/dev/null 2>&1 && git -C "$RAIZ" -c safe.directory="$RAIZ" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  TEM_GIT=true
else
  log "AVISO: git indisponível em $RAIZ; só os dados serão extraídos."
fi

# Verdadeiro se o destino versionado pode ser sobrescrito (sem alterações locais).
livre() {
  [ "$TEM_GIT" = true ] || return 1
  local pendentes
  # --no-optional-locks: só lê, não reescreve o índice do repositório.
  pendentes="$(git -C "$RAIZ" -c safe.directory="$RAIZ" --no-optional-locks status --porcelain -- "$1")"
  if [ -n "$pendentes" ]; then
    log "AVISO: $1 tem alterações não commitadas; não foi atualizado."
    return 1
  fi
}

# Troca uma pasta inteira (remove arquivos que saíram do banco).
trocar_pasta() {
  local origem="$1" destino="$2"
  rm -rf "${RAIZ:?}/$destino"
  mkdir -p "$(dirname "$RAIZ/$destino")"
  cp -R "$origem" "$RAIZ/$destino"
  log "$destino atualizado."
}

if livre corlixhub; then
  trocar_pasta "$BASE/apexlang/corlixhub" corlixhub
fi

if [ -f "$BASE/sql/f100.sql" ] && livre database/f100.sql; then
  cp "$BASE/sql/f100.sql" "$RAIZ/database/f100.sql"
  log "database/f100.sql atualizado."
fi

if livre database/ddl; then
  trocar_pasta "$BASE/ddl" database/ddl
fi

trocar_pasta "$BASE/dados" database/dados/backup
cp "$BASE/manifesto.txt" "$RAIZ/database/dados/backup/manifesto.txt"

log "Concluído a partir de $(basename "$ARQUIVO"). Revise com: git status"

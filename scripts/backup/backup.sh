#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Corlix Hub — backup da aplicação APEX (APEXlang + SQL), do DDL e dos dados
#
# Roda local ou no Jenkins (scripts/backup/Jenkinsfile). Conecta no Autonomous
# Database pelo SQLcl como o dono do schema e executa scripts/backup/backup.sql.
#
# Variáveis de ambiente:
#   DB_USER             obrigatória  dono do schema (ex.: WKSP_CORLIXHUB)
#   DB_PASSWORD         obrigatória  senha (não pode conter aspas duplas)
#   DB_SERVICE          obrigatória  alias do tnsnames da wallet (ex.: corlixhub_low)
#                                    ou EZConnect host:porta/servico
#   DB_WALLET           opcional     caminho do Wallet_*.zip (mTLS do Autonomous)
#   APP_ID              opcional     ID da aplicação APEX (padrão: 100)
#   AMBIENTE            opcional     rótulo usado no nome do arquivo (padrão: local)
#   BACKUP_ROOT         opcional     pasta dos backups (padrão: <repo>/backups)
#   RETENCAO_DIAS       opcional     apaga .tar.gz mais antigos que N dias; 0 desliga (padrão: 30)
#   EXPORTAR_WORKSPACE  opcional     exporta usuários/grupos do workspace (padrão: true)
#   MANTER_PASTA        opcional     mantém a pasta descompactada além do .tar.gz (padrão: false)
#   SQLCL_BIN           opcional     executável do SQLcl (padrão: sql ou sqlcl no PATH)
#
# Exemplo:
#   DB_USER=WKSP_CORLIXHUB DB_PASSWORD='...' DB_SERVICE=corlixhub_low \
#   DB_WALLET=~/wallets/Wallet_corlixhub.zip ./scripts/backup/backup.sh
#
# Saída: $BACKUP_ROOT/<ambiente>/corlixhub-<ambiente>-<AAAAMMDD-HHMMSS>.tar.gz
#        + .sha256. O conteúdo está descrito em scripts/backup/README.md.
# -----------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

: "${DB_USER:?Defina DB_USER (ex.: WKSP_CORLIXHUB)}"
: "${DB_PASSWORD:?Defina DB_PASSWORD}"
: "${DB_SERVICE:?Defina DB_SERVICE (alias do tnsnames da wallet, ex.: corlixhub_low)}"
DB_WALLET="${DB_WALLET:-}"
APP_ID="${APP_ID:-100}"
AMBIENTE="${AMBIENTE:-local}"
BACKUP_ROOT="${BACKUP_ROOT:-$ROOT_DIR/backups}"
RETENCAO_DIAS="${RETENCAO_DIAS:-30}"
EXPORTAR_WORKSPACE="${EXPORTAR_WORKSPACE:-true}"
MANTER_PASTA="${MANTER_PASTA:-false}"

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }

falhar() {
  echo "ERRO: $*" >&2
  if [ -n "${OUT:-}" ] && [ -f "$OUT/sqlcl.log" ]; then
    echo "--- últimas linhas de $OUT/sqlcl.log ---" >&2
    tail -n 40 "$OUT/sqlcl.log" >&2
  fi
  # O DDL e os dados rodam com termout off: os erros ficam nos arquivos em spool.
  # Mostra só as linhas ORA-/SP2- (sem conteúdo dos dados) e o arquivo de cada uma.
  if [ -n "${OUT:-}" ] && [ -d "$OUT/ddl" ]; then
    ERROS_SPOOL="$(grep -rHE '^(ORA|SP2)-[0-9]+' "$OUT/ddl" "$OUT/dados" 2>/dev/null | sed "s|^$OUT/||" | head -n 20 || true)"
    if [ -n "$ERROS_SPOOL" ]; then
      echo "--- erros nos arquivos em spool ---" >&2
      echo "$ERROS_SPOOL" >&2
    fi
  fi
  exit 1
}

contar() { find "$1" -type f -name "$2" 2>/dev/null | wc -l | tr -d ' '; }

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi
}

# --- Pré-requisitos ----------------------------------------------------------
if [ -z "${SQLCL_BIN:-}" ]; then
  if command -v sql >/dev/null 2>&1; then SQLCL_BIN=sql
  elif command -v sqlcl >/dev/null 2>&1; then SQLCL_BIN=sqlcl
  else falhar "SQLcl não encontrado. Instale (brew install sqlcl) ou defina SQLCL_BIN."
  fi
fi

case "$APP_ID" in ''|*[!0-9]*) falhar "APP_ID inválido: $APP_ID" ;; esac
case "$RETENCAO_DIAS" in ''|*[!0-9]*) falhar "RETENCAO_DIAS inválido: $RETENCAO_DIAS" ;; esac
case "$DB_PASSWORD" in *'"'*) falhar "DB_PASSWORD não pode conter aspas duplas." ;; esac

if [ -n "$DB_WALLET" ] && [ ! -f "$DB_WALLET" ]; then
  falhar "Wallet não encontrada: $DB_WALLET"
fi

AMB="$(printf '%s' "$AMBIENTE" | tr '[:upper:]' '[:lower:]')"
TS="$(date +%Y%m%d-%H%M%S)"
NOME="corlixhub-$AMB-$TS"
DEST="$BACKUP_ROOT/$AMB"
OUT="$DEST/$NOME"

# Os comandos "apex export" e "spool" do SQLcl recebem esses caminhos sem aspas.
for caminho in "$OUT" "$SCRIPT_DIR" "$DB_WALLET"; do
  case "$caminho" in *[[:space:]]*) falhar "Caminho com espaço não é suportado: $caminho" ;; esac
done

mkdir -p "$OUT/apexlang" "$OUT/sql" "$OUT/workspace" "$OUT/ddl" "$OUT/dados"

# --- Exportação --------------------------------------------------------------
log "Backup de $AMBIENTE (app $APP_ID, serviço $DB_SERVICE) em $OUT"

# O script vai pelo stdin para a senha não aparecer na lista de processos.
{
  echo "set echo off"
  echo "whenever sqlerror exit failure"
  echo "whenever oserror exit failure"
  if [ -n "$DB_WALLET" ]; then
    echo "set cloudconfig $DB_WALLET"
  fi
  echo "connect $DB_USER/\"$DB_PASSWORD\"@$DB_SERVICE"
  echo "@$SCRIPT_DIR/backup.sql $OUT $APP_ID"
  if [ "$EXPORTAR_WORKSPACE" = "true" ]; then
    # Opcional: depende de permissão no workspace. Falha aqui só gera aviso.
    echo "whenever sqlerror continue"
    echo "define WS_ID = 0"
    echo "column workspace_id new_value WS_ID noprint"
    # to_char: como número, o SQLcl arredonda o ID (16+ dígitos) ao formatar a coluna.
    echo "select to_char(workspace_id) as workspace_id from apex_applications where application_id = $APP_ID;"
    echo "apex export -expworkspace -workspaceid &WS_ID -expminimal -dir $OUT/workspace -skipexportdate -overwrite-files"
  fi
  echo "exit"
} | "$SQLCL_BIN" -S /nolog > "$OUT/sqlcl.log" 2>&1 || falhar "SQLcl terminou com erro."

# --- Conferência -------------------------------------------------------------
N_APX="$(contar "$OUT/apexlang" '*.apx')"
N_SQL="$(contar "$OUT/sql" '*.sql')"
N_TABELAS_DDL="$(grep -ci 'create table' "$OUT/ddl/03-tabelas.sql" || true)"
N_CSV="$(find "$OUT/dados" -type f -name '*.csv' ! -name '_*' | wc -l | tr -d ' ')"
N_CONTAGENS="$( (grep -Evi '^"?TABELA"?,' "$OUT/dados/_contagens.csv" 2>/dev/null || true) | grep -c . || true)"
N_WS="$(contar "$OUT/workspace" '*')"

[ "$N_APX" -gt 0 ] || falhar "Export APEXlang vazio em $OUT/apexlang."
[ "$N_SQL" -gt 0 ] || falhar "Export SQL vazio em $OUT/sql."
[ "$N_TABELAS_DDL" -gt 0 ] || falhar "Nenhum CREATE TABLE em ddl/03-tabelas.sql."
[ "$N_CSV" -eq "$N_CONTAGENS" ] || falhar "Foram gerados $N_CSV CSVs, mas _contagens.csv lista $N_CONTAGENS tabelas."

if [ "$EXPORTAR_WORKSPACE" = "true" ] && [ "$N_WS" -eq 0 ]; then
  log "AVISO: export do workspace não gerou arquivos (ver sqlcl.log). O resto do backup está completo."
fi
if grep -qE '^(ORA|SP2)-[0-9]+' "$OUT/sqlcl.log"; then
  log "AVISO: o sqlcl.log tem mensagens ORA-/SP2-; confira antes de confiar no backup."
fi

{
  echo "projeto=corlixhub"
  echo "ambiente=$AMBIENTE"
  echo "aplicacao=$APP_ID"
  echo "gerado_em=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "usuario=$DB_USER"
  echo "servico=$DB_SERVICE"
  echo "commit_git=${GIT_COMMIT:-$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo desconhecido)}"
  echo "sqlcl=$("$SQLCL_BIN" -V 2>/dev/null | head -n 1)"
  echo "arquivos_apexlang=$N_APX"
  echo "arquivos_sql=$N_SQL"
  echo "tabelas=$N_CSV"
  echo "arquivos_workspace=$N_WS"
} > "$OUT/manifesto.txt"

# --- Compactação e retenção --------------------------------------------------
(
  cd "$DEST"
  tar -czf "$NOME.tar.gz" "$NOME"
  sha256 "$NOME.tar.gz" > "$NOME.tar.gz.sha256"
)
[ "$MANTER_PASTA" = "true" ] || rm -rf "$OUT"

if [ "$RETENCAO_DIAS" -gt 0 ]; then
  find "$DEST" -maxdepth 1 -type f \( -name 'corlixhub-*.tar.gz' -o -name 'corlixhub-*.tar.gz.sha256' \) \
    -mtime +"$RETENCAO_DIAS" -print -delete | sed 's/^/Removido pela retenção: /'
fi

log "OK: $DEST/$NOME.tar.gz ($(du -h "$DEST/$NOME.tar.gz" | cut -f1), $N_CSV tabelas, $N_APX arquivos APEXlang)"

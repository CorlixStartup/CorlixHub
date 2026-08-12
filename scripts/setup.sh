#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Corlix Hub — setup do ambiente de desenvolvimento (macOS / Linux)
#
# O que este script faz:
#   1. Confere se Docker e Docker Compose estão instalados
#   2. Cria o .env a partir do .env.example (se ainda não existir)
#   3. Confere se a distribuição do Oracle APEX 26.1 já foi baixada em ./apex
#   4. Sobe os containers (docker compose up -d)
#
# O que este script NÃO faz:
#   - Baixar a distribuição do Oracle APEX automaticamente (é preciso aceitar
#     os termos da Oracle manualmente — ver instruções abaixo)
#   - Rodar os scripts de instalação da aplicação (schema, seed, f100) —
#     isso é feito manualmente na primeira vez, ver README.md
# -----------------------------------------------------------------------------
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Verificando pré-requisitos..."

if ! command -v docker >/dev/null 2>&1; then
  echo "ERRO: Docker não encontrado. Instale o Docker Desktop (macOS/Windows) ou Docker Engine (Linux)."
  echo "      https://docs.docker.com/get-docker/"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "ERRO: 'docker compose' (plugin v2) não encontrado. Atualize o Docker Desktop/Engine."
  exit 1
fi

echo "==> Docker OK: $(docker --version)"
echo "==> Docker Compose OK: $(docker compose version --short)"

if [ ! -f .env ]; then
  echo "==> Criando .env a partir de .env.example"
  cp .env.example .env
  echo "    ATENÇÃO: edite o .env e defina senhas seguras antes de continuar (ORACLE_PWD, APEX_PWD)."
else
  echo "==> .env já existe, mantendo como está."
fi

if [ ! -d "apex/core" ]; then
  echo ""
  echo "==> AVISO: a pasta ./apex não contém a distribuição do Oracle APEX 26.1."
  echo "    Baixe manualmente antes de continuar (é necessário aceitar os termos da Oracle):"
  echo "      1. Acesse https://www.oracle.com/tools/downloads/apex-downloads/"
  echo "      2. Baixe a versão 26.1 (apex_26.1.zip)"
  echo "      3. Descompacte o conteúdo do zip diretamente na raiz do projeto,"
  echo "         de forma que exista ./apex/core, ./apex/images, ./apex/builder etc."
  echo ""
  read -r -p "Pressione ENTER quando terminar, ou Ctrl+C para sair e fazer isso depois... "
fi

echo "==> Subindo os containers (isso pode levar alguns minutos na primeira vez)..."
docker compose up -d

echo ""
echo "==> Containers iniciados. Acompanhe a inicialização com:"
echo "      docker compose logs -f"
echo ""
echo "    A primeira subida instala o APEX no banco e pode levar de 5 a 15 minutos."
echo "    Quando o serviço 'db' estiver 'healthy' (docker compose ps), acesse:"
echo "      ORDS/APEX: http://localhost:\${ORDS_HOST_PORT:-8081}/ords"
echo ""
echo "    Próximo passo: siga a seção 'Instalação passo a passo' do README.md"
echo "    para carregar o schema, os dados de seed e a aplicação f100."

# -----------------------------------------------------------------------------
# Corlix Hub - setup do ambiente de desenvolvimento (Windows / PowerShell)
#
# Equivalente ao scripts/setup.sh. Requer Docker Desktop com o backend
# WSL2 habilitado. Execute em um terminal PowerShell (nao precisa ser admin).
#
# Se o PowerShell bloquear a execucao de scripts, rode uma vez:
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
# -----------------------------------------------------------------------------

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $PSScriptRoot
Set-Location $RootDir

Write-Host "==> Verificando pre-requisitos..."

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERRO: Docker nao encontrado. Instale o Docker Desktop: https://docs.docker.com/get-docker/"
    exit 1
}

docker compose version | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: 'docker compose' (plugin v2) nao encontrado. Atualize o Docker Desktop."
    exit 1
}

Write-Host "==> Docker OK: $(docker --version)"

if (-not (Test-Path ".env")) {
    Write-Host "==> Criando .env a partir de .env.example"
    Copy-Item ".env.example" ".env"
    Write-Host "    ATENCAO: edite o .env e defina senhas seguras antes de continuar (ORACLE_PWD, APEX_PWD)."
} else {
    Write-Host "==> .env ja existe, mantendo como esta."
}

if (-not (Test-Path "apex/core")) {
    Write-Host ""
    Write-Host "==> AVISO: a pasta .\apex nao contem a distribuicao do Oracle APEX 26.1."
    Write-Host "    Baixe manualmente antes de continuar (e necessario aceitar os termos da Oracle):"
    Write-Host "      1. Acesse https://www.oracle.com/tools/downloads/apex-downloads/"
    Write-Host "      2. Baixe a versao 26.1 (apex_26.1.zip)"
    Write-Host "      3. Descompacte o conteudo do zip diretamente na raiz do projeto,"
    Write-Host "         de forma que exista .\apex\core, .\apex\images, .\apex\builder etc."
    Write-Host ""
    Read-Host "Pressione ENTER quando terminar (ou Ctrl+C para sair e fazer isso depois)"
}

Write-Host "==> Subindo os containers (isso pode levar alguns minutos na primeira vez)..."
docker compose up -d

Write-Host ""
Write-Host "==> Containers iniciados. Acompanhe a inicializacao com:"
Write-Host "      docker compose logs -f"
Write-Host ""
Write-Host "    A primeira subida instala o APEX no banco e pode levar de 5 a 15 minutos."
Write-Host "    Quando o servico 'db' estiver 'healthy' (docker compose ps), acesse:"
Write-Host "      ORDS/APEX: http://localhost:8081/ords  (ou a porta definida em ORDS_HOST_PORT no .env)"
Write-Host ""
Write-Host "    Proximo passo: siga a secao 'Instalacao passo a passo' do README.md"
Write-Host "    para carregar o schema, os dados de seed e a aplicacao f100."

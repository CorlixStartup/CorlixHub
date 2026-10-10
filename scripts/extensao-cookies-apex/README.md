# Extensão do Chrome: Cookies do APEX

Extensão local, sem publicação na Chrome Web Store, para o erro `400 Request Header Or Cookie Too Large` e para o logout inesperado do APEX no Autonomous Database (OCI). Contexto e diagnóstico: [`docs/ai-context/09-erro-400-cookies.md`](../../docs/ai-context/09-erro-400-cookies.md).

## O que ela faz

| Recurso | Como |
|---|---|
| **Medidor no ícone** | Mostra o tamanho, em KB, do cabeçalho `Cookie` enviado para a aba do Autonomous. Verde < 60%, laranja < 85%, vermelho ≥ 85% de 8 KB. |
| **Limpa sozinha no 400** | Se uma navegação volta com 400 e o cabeçalho tem ≥ 4 KB, apaga os cookies do host (menos os de "nunca apagar") e recarrega a aba. Não repete se já tiver limpado há menos de 15 s, para não entrar em loop. |
| **Limpeza preventiva** | Quando passa de 60%, apaga os cookies cujo nome casa com as regex de "apagar sempre". A lista começa vazia: preencha depois do diagnóstico. |
| **Registro de descartes** | Guarda os cookies que o Chrome descartou por limite (`evicted`) ou por expiração. Se um `evicted` aparece logo antes de um logout, a causa é perda de cookie e não timeout (§8 do guia). |
| **Relatório** | *Copiar relatório* gera uma tabela Markdown (nome, path, bytes, HttpOnly, repetido) para colar na §6 do guia. **Os valores dos cookies nunca são lidos para relatório nem salvos**, porque contêm a sessão. |

Ela só tem acesso a `https://*.oraclecloudapps.com/*`. Não faz nenhuma chamada de rede.

## Instalar (uma vez)

1. Abra `chrome://extensions`.
2. Ative o **Modo do desenvolvedor** (canto superior direito).
3. Clique em **Carregar sem compactação** e escolha esta pasta (`scripts/extensao-cookies-apex`).
4. Fixe o ícone na barra (ícone de quebra-cabeça → alfinete).

Depois de um `git pull` que mude esta pasta, clique em ↻ no card da extensão em `chrome://extensions`.

## Usar

- Trabalhe normalmente. Se o 400 acontecer, a aba recarrega sozinha na tela de login.
- Quando o número no ícone ficar laranja, abra o popup → **Cookies enviados para esta página**. Os nomes em vermelho existem em mais de um path, e todas as cópias vão no cabeçalho.
- Quando souber quais cookies crescem, cadastre em **Configuração**:
  - **Apagar sempre**: o padrão do nome dos cookies que se acumulam (ex.: `^NOME_DO_COOKIE_`).
  - **Nunca apagar**: o cookie que lembra o workspace e o usuário no login, para não precisar digitar o workspace de novo depois de uma limpeza.

## Limites

- O limite de 8 KB (`LIMITE` em `comum.js`) é o padrão do nginx. O valor que a Oracle usa não é público: se o 400 aparecer com o ícone ainda laranja, diminua o valor.
- A limpeza no 400 só age em navegações de página. Uma chamada AJAX do Page Designer que falhe com 400 não dispara a limpeza: o ícone fica vermelho e você limpa pelo popup.
- Apagar a sessão desloga. Nenhum script resolve isso, porque a sessão vive no cookie. O que a extensão evita é o acúmulo que leva até esse ponto.

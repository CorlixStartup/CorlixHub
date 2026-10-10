# 09 · Cookies e sessão no APEX (OCI): erro 400 e logout inesperado

> Parte do pacote de contexto para IAs (`docs/ai-context/`). Comece pelo [`README.md`](./README.md) desta pasta.
> Escrito em 09/10/2026. Ambiente: APEX 26.1 no **Autonomous Database da OCI** (URL `https://<id>.adb.<região>.oraclecloudapps.com/ords/...`).

## 1. Sintoma

Depois de muito tempo desenvolvendo (Builder + app rodando), qualquer página do host do Autonomous passa a responder com uma página branca:

```
400 Bad Request
Request Header Or Cookie Too Large
```

Só volta a funcionar depois de limpar os cookies. Como limpar o navegador inteiro derruba todos os outros logins, o trabalho para.

## 2. Por que acontece

- O navegador envia **todos os cookies do host** (e de todos os `Path` que casam com a URL) no cabeçalho `Cookie` de **cada** requisição.
- No Autonomous, o mesmo host serve o **Builder do APEX**, a **app em execução**, o **Database Actions** (SQL Developer Web) e os **REST do ORDS**. Os cookies de todos eles se somam no mesmo cabeçalho.
- Na frente do ORDS do Autonomous há um proxy gerenciado pela Oracle. A mensagem `Request Header Or Cookie Too Large` é a página padrão do **nginx** quando o cabeçalho passa do buffer configurado (no nginx o padrão é `large_client_header_buffers 4 8k`; o valor usado pela Oracle não é público).
- **Não dá para aumentar esse limite** no endpoint padrão do Autonomous, porque o proxy não é nosso. A solução fica do lado do navegador: não deixar cookies se acumularem nesse host.
- **A app Corlix Hub não cria cookies próprios.** Em `corlixhub/` o único uso é o padrão da página de login (p9999): `apex_authentication.send_login_username_cookie` e `get_login_username_cookie` ("lembrar usuário"), um cookie pequeno e único. A autenticação usa o cookie de sessão padrão do esquema `oracle-apex-accounts`, sem nome ou path customizado (`application.apx`). O acúmulo vem do uso do host ao longo do dia (Builder, execuções, Database Actions, sessões expiradas), e não do código da app.

> ⚠️ **Ainda falta confirmar qual cookie cresce.** Faça o diagnóstico da §3 na próxima vez que o erro estiver perto de acontecer e preencha a §6.

## 3. Diagnóstico (5 minutos, uma vez)

Os cookies de sessão do APEX são `HttpOnly`, então `document.cookie` no console **não** mostra todos. Use o painel do DevTools:

1. Com o APEX aberto no Chrome, abra o DevTools (`Cmd+Option+I`) e vá em **Application → Storage → Cookies → `https://<id>.adb.<região>.oraclecloudapps.com`**.
2. Ordene pela coluna **Size** (decrescente) e observe as colunas **Name**, **Path** e **Expires**.
3. Procure um destes padrões:
   - **Muitos cookies com o mesmo prefixo e sufixos diferentes** (um por sessão, workspace ou instância) → acúmulo por nome.
   - **O mesmo nome repetido com `Path` diferentes** (`/ords/`, `/ords/r/...`, `/ords/sql-developer`…) → acúmulo por path. Todas as cópias vão juntas no cabeçalho.
   - **Um único cookie muito grande** → algo grava estado no cookie.
4. Para medir o tamanho total: aba **Network**, clique numa requisição do APEX → **Headers → Request Headers → Cookie**. Se o valor passar de alguns KB, o erro está perto.
5. Tire um print do painel de cookies e anexe aqui (§6) ou mande para o time.

## 4. Alívio rápido: limpar só o host do Autonomous (≈10 s)

Não limpe o navegador inteiro. Apague só os dados do host do Autonomous:

- **Pelo DevTools (mais rápido quando o erro já apareceu):** na própria página do erro, `Cmd+Option+I` → **Application → Storage → Clear site data** → recarregue (`Cmd+R`). Isso apaga só os dados desse host. Você sai do Builder e da app, mas continua logado no resto (GitHub, OCI Console, e-mail…).
- **Pelo ícone de informações do site** (à esquerda da URL) → *Cookies e dados do site* → apagar os dados desse site. O nome exato do menu muda entre versões do Chrome.
- **Cirúrgico:** em **Application → Cookies**, selecione só os cookies antigos ou duplicados encontrados na §3 e apague com `Delete`. Assim você mantém a sessão atual.

## 5. Prevenção (para o erro não voltar)

Em ordem de custo:

1. **Perfil do Chrome só para o APEX/OCI** (*Perfil → Adicionar*). Assim o OCI Console, o Database Actions e outras abas ficam separados do Builder, e limpar tudo nesse perfil não afeta o resto.
2. **Limpar os dados do host ao fechar o navegador:** em `chrome://settings/content/siteData`, adicione `[*.]oraclecloudapps.com` à lista de sites que **sempre limpam os dados ao fechar todas as janelas**. Cada dia começa com zero cookies nesse host. Desvantagem: é preciso fazer login de novo depois de reabrir o Chrome.
3. **Database Actions em outro perfil ou numa janela anônima.** Ele usa o mesmo host e soma cookies aos do Builder. Abra-o fora do perfil de desenvolvimento.
4. **Sair (logout) do Builder e da app** em vez de só fechar a aba no fim do dia. Fazer logout apaga a sessão; sessões que só expiram podem deixar cookies para trás.
5. **Extensão de cookies** (ex.: *Cookie-Editor*), se o diagnóstico mostrar um padrão de nome claro: ela apaga só aquele padrão em um clique, sem mexer na sessão atual.
6. **Só se nada disso bastar:** ORDS gerenciado pelo cliente (*customer-managed ORDS*) ou URL própria (*vanity URL*) com um load balancer da OCI na frente. Nesse caso o limite de cabeçalho passa a ser configurável por nós (no ORDS standalone/Jetty, ver nota MOS 2894799.1). Para o tamanho do projeto, é infraestrutura demais. Não faça isso sem falar com o time.

## 6. Causa confirmada (preencher após o diagnóstico)

| Data | Cookie(s) que crescem | Padrão (nome / path / tamanho) | Origem provável | Ação adotada |
|---|---|---|---|---|
| _pendente_ | | | | |

## 7. Caso parecido no Jenkins local (não é o mesmo problema)

O Jenkins do backup (`scripts/backup/jenkins/`, `http://localhost:8080`) tem um problema conhecido parecido: a cada reinício ele cria um cookie de sessão com nome novo (`JSESSIONID.<hash>`), e os cookies antigos se acumulam no `localhost` ([JENKINS-25046](https://issues.jenkins.io/browse/JENKINS-25046)). Isso **não afeta o APEX na OCI**, porque o host é outro. Se o Jenkins começar a responder 400, 413 ou 431, apague os cookies de `localhost` (§4) ou faça logout no Jenkins: desde a versão 2.184, o logout remove os cookies de sessão obsoletos. Atenção: cookies não são separados por porta, então tudo o que roda em `localhost` (Jenkins, um APEX em Docker na 8081, o servidor interno da IDE) compartilha o mesmo cabeçalho `Cookie`.

## 8. A sessão do Builder cai "do nada" e pede o workspace de novo

### 8.1 Sintoma
No meio do trabalho, o Builder (ou a app) volta para a tela de login. Além da senha, é preciso **informar o workspace de novo**.

### 8.2 Causas possíveis, da mais para a menos provável

| # | Causa | Como reconhecer |
|---|---|---|
| 1 | **Os cookies foram perdidos** (é o mesmo problema da §2). O Chrome tem limite de cookies por domínio e, quando ele estoura, descarta os mais antigos. Os cookies de sessão do Builder e o que lembra o workspace podem estar entre eles. | O workspace e o usuário **não** vêm preenchidos no login. Acontece perto dos episódios de erro 400 ou depois de uma limpeza (§4 ou §5.2). |
| 2 | **Tempo de inatividade** (`MAX_SESSION_IDLE_SEC`, padrão do APEX de 1 h). | Acontece quando você volta de uma pausa ou depois de ficar muito tempo numa aba sem salvar nem navegar. |
| 3 | **Duração máxima da sessão** (`MAX_SESSION_LENGTH_SEC`, padrão do APEX de 8 h). | Acontece depois de várias horas, mesmo com uso contínuo. |
| 4 | **Limpeza que você mesma fez**: o *Clear site data* da §4 e o "limpar ao fechar" da §5.2 também apagam a sessão e a lembrança do workspace. | É o comportamento esperado depois dessas ações. |

A app Corlix Hub não define timeout próprio (não há nada sobre sessão em `corlixhub/application.apx`), então vale o que estiver configurado no workspace ou na instância.

### 8.3 Diagnóstico
1. Rode o bloco 1 de [`scripts/apex-sessao-timeouts.sql`](../../scripts/apex-sessao-timeouts.sql) como `ADMIN` (Database Actions → SQL). Valor nulo significa que vale o nível de cima e, no fim, o padrão do APEX (1 h / 8 h).
2. Quando a sessão cair, anote: o horário, há quanto tempo estava parada, há quanto tempo tinha feito login e se o workspace veio preenchido. Abra também **DevTools → Application → Cookies** e veja quantos cookies o host tem.
3. Compare com a tabela da §8.2: queda depois de pausa = inatividade; queda depois de ~8 h = duração máxima; workspace em branco e muitos cookies = perda de cookies.

### 8.4 Correção
- **Perda de cookies:** é a mesma correção das §4–5. Mantenha o host do Autonomous enxuto (perfil dedicado, Database Actions fora dele, logout no fim do dia).
- **Timeout:** aumente os valores **só no workspace** com o bloco 2 do script (sugestão para desenvolvimento: 4 h de inatividade e 12 h de duração). Isso vale para o Builder e para as apps do workspace sem timeout próprio, e não mexe na instância.
  - ⚠️ Sessão mais longa é menos segura. Antes de publicar a app para usuários reais, defina um timeout próprio na app (atributos de segurança da aplicação), para não herdar os valores generosos de desenvolvimento.
- Registre o que foi encontrado na tabela da §6.

## 9. Automação: extensão do Chrome e script de timeouts

Não há como resolver o erro 400 dentro da app ou do APEX: o nginx da Oracle recusa a requisição **antes** de ela chegar ao ORDS, então nenhum processo PL/SQL, página ou handler REST chega a rodar. Quem controla os cookies (inclusive os `HttpOnly`) é o navegador. Por isso a automação tem duas partes:

| Problema | Ferramenta | O que automatiza |
|---|---|---|
| Erro 400 por cookies | [`scripts/extensao-cookies-apex/`](../../scripts/extensao-cookies-apex/README.md) (extensão local do Chrome) | Medidor no ícone; ao dar 400, limpa só o host e recarrega; limpeza preventiva por regex; relatório para a §6. |
| Logout por perda de cookie | Mesma extensão | Registra os cookies descartados pelo Chrome (`evicted`) e protege, por regex ("nunca apagar"), o cookie que lembra o workspace. |
| Logout por timeout | [`scripts/apex-sessao-timeouts.sql`](../../scripts/apex-sessao-timeouts.sql) | Lê os timeouts e, opcionalmente, aumenta os do workspace (§8.4). É configuração de uma vez, não precisa de módulo. |

A lógica da extensão foi testada com uma API `chrome` simulada no Node (medição, limpeza no 400 com proteção contra loop, regras por regex e registro de descartes). Ela **ainda não foi carregada num Chrome de verdade**: na primeira vez, confira se o ícone mostra o tamanho do cabeçalho numa aba do Autonomous.

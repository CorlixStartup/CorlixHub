# Organograma · guia de implantação (página 3)

> Passo a passo completo para instalar, configurar, testar e manter o módulo de Organograma no app **CorlixHub** (APEX 26.1, app `100`, workspace `WKSP_CORLIXHUB`).
> Atualizado em 09/10/2026. Página alvo: **3 · Organograma** (`corlixhub/pages/p00003-organograma.apx`).
> Referência técnica (arquitetura, API JS, HTML gerado, classes CSS): [`docs/ai-context/06-modulos.md`](../../docs/ai-context/06-modulos.md) §1.

## Sumário

1. [O que o módulo faz](#1-o-que-o-módulo-faz)
2. [Arquivos do módulo](#2-arquivos-do-módulo)
3. [Pré-requisitos](#3-pré-requisitos)
4. [Etapa 1 · Banco de dados](#4-etapa-1--banco-de-dados)
5. [Etapa 2 · App APEX: escolha o caminho](#5-etapa-2--app-apex-escolha-o-caminho)
6. [Caminho A · Importar pelo APEXlang (SQLcl)](#6-caminho-a--importar-pelo-apexlang-sqlcl)
7. [Caminho B · Montar no App Builder, campo a campo](#7-caminho-b--montar-no-app-builder-campo-a-campo)
8. [Etapa 3 · Testes de aceite](#8-etapa-3--testes-de-aceite)
9. [Etapa 4 · Sincronizar o repositório (não pule)](#9-etapa-4--sincronizar-o-repositório-não-pule)
10. [Como funciona](#10-como-funciona)
11. [Configuração (constantes do package)](#11-configuração-constantes-do-package)
12. [Solução de problemas](#12-solução-de-problemas)
13. [Manutenção](#13-manutenção)
14. [Limitações conhecidas e pendências](#14-limitações-conhecidas-e-pendências)
15. [Histórico de mudanças](#15-histórico-de-mudanças)

---

## 1. O que o módulo faz

Mostra a estrutura da empresa a partir das relações de gestão (`COLABORADOR.ID_GESTOR`), **um nível por vez**, seguindo os protótipos desta pasta:

| Protótipo | Tela |
|---|---|
| `Organograma — redesign (navegação por níveis).png` | Página com o caminho na hierarquia, a pessoa em foco e os subordinados diretos em cards |
| `Organograma · detalhes da pessoa (Drawer) — redesign.png` | Painel lateral (drawer) com contato, posição na estrutura e dados da pessoa |

Comportamento resumido:

- Ao abrir a página, a **pessoa em foco é o usuário logado** (por `COLABORADOR.LOGIN_APEX`). Se a conta não tiver colaborador vinculado, abre no **topo da hierarquia**.
- **Clicar num card** (ou em "Ver perfil") abre o **drawer de detalhes** sem sair da página.
- **"Ver equipe"** desce um nível: aquela pessoa passa a ser o foco.
- O **caminho** acima ("Corlix › Fulano › Ciclano") volta para qualquer nível anterior.
- A **busca** ("Buscar pessoa no organograma") leva direto para qualquer colaborador ativo.
- **Contas inativas não aparecem** (`COLABORADOR.STATUS` nulo ou `false`).

Tudo é nativo do APEX: uma região *Dynamic Content* cujo HTML é gerado por PL/SQL (`pkg_organograma.render`) e um *Ajax Callback* para o drawer (`pkg_organograma.render_detalhes`). Não há biblioteca externa (a antiga OrgChart JS foi abandonada).

---

## 2. Arquivos do módulo

| Arquivo | Para que serve | Onde vai parar |
|---|---|---|
| `modulos/organograma/organograma.sql` | View `vw_org_colaborador` + package `pkg_organograma` (spec e body) | Banco (schema `WKSP_CORLIXHUB`) |
| `modulos/organograma/organograma.css` | Estilos da região (`.org`) e do drawer (`.org-drawer`). **Fonte de verdade do CSS** | Copiado para `corlixhub/shared-components/static-files/organograma.css` |
| `corlixhub/shared-components/static-files/organograma.css` e `organograma.min.css` | Cópia publicada como *Static Application File* + versão minificada | App APEX (`#APP_FILES#organograma#MIN#.css`) |
| `modulos/organograma/organograma.js` | JS em 3 blocos comentados (declarações, page load, DA da busca) | Atributos da página 3 e DA (já colado no `.apx`) |
| `corlixhub/pages/p00003-organograma.apx` | Definição da página 3 em APEXlang, já com tudo montado | App APEX (import) |
| `corlixhub/shared-components/static-files.apx` | Registro dos arquivos `organograma.css` e `organograma.min.css` | App APEX (import) |
| `*.png` | Protótipos de referência visual | Só documentação |

---

## 3. Pré-requisitos

### 3.1 Acesso

- Usuário do banco **dono do schema** `WKSP_CORLIXHUB` (para criar view e package), ou acesso ao **SQL Workshop** do workspace.
- Para o Caminho A: **SQLcl 26.x** com o comando `apex` (ex.: `/opt/homebrew/Caskroom/sqlcl/<versão>/sqlcl/bin/sql`) e a **wallet** do Autonomous Database (a mesma usada pelo backup; ver `scripts/backup/Etapas-backup.md`).
- Para o Caminho B: login de **desenvolvedor** no App Builder do workspace.

### 3.2 Tabelas e colunas usadas

A view lê só estas tabelas e colunas. Se algum nome for diferente no seu banco, ajuste a view antes de rodar o script.

| Tabela | Colunas |
|---|---|
| `COLABORADOR` | `ID_COLABORADOR`, `ID_GESTOR`, `NOME_COMPLETO`, `EMAIL`, `LOGIN_APEX`, `DATA_ADMISSAO`, `DATA_DE_NASCIMENTO`, `ID_CARGO`, `ID_DEPARTAMENTO`, `FOTO_URL`, `IMAGEM_PERFIL`, `STATUS` (BOOLEAN) |
| `CARGO` | `ID_CARGO`, `NOME` |
| `DEPARTAMENTO` | `ID_DEPARTAMENTO`, `NOME` |

### 3.3 Dados que precisam estar corretos

| Dado | Por que importa | Se estiver errado |
|---|---|---|
| `COLABORADOR.LOGIN_APEX` igual ao usuário APEX (a comparação ignora maiúsculas e espaços) | Define a pessoa em foco ao abrir a página e esconde o botão "Conversar" da própria pessoa | A página abre no topo da hierarquia, não no usuário |
| `COLABORADOR.STATUS = true` | Só ativos entram na view | A pessoa some do organograma, da busca e do caminho |
| `ID_CARGO` e `ID_DEPARTAMENTO` preenchidos e existentes | A view usa *inner join* com `CARGO` e `DEPARTAMENTO` | A pessoa some do organograma |
| `ID_GESTOR` apontando para um colaborador **ativo** | Monta a árvore | Quem se reporta a um gestor inativo some da navegação |
| Só **um** "topo" real (ativo e sem gestor) com a estrutura abaixo dele | O topo é o ativo sem gestor com mais pessoas abaixo | Contas técnicas sem gestor (ex.: equipe de desenvolvimento) também ficam "sem gestor"; não atrapalham o topo, mas aparecem como raízes soltas no banco |
| `FOTO_URL` com o **nome do arquivo** que existe em `static-files/Fotos Colaboradores/` (ex.: `aline_alves.jpg`) | O avatar monta `#APP_FILES#Fotos Colaboradores/<arquivo>` | Aparecem as iniciais no lugar da foto (sem ícone de imagem quebrada) |

---

## 4. Etapa 1 · Banco de dados

### 4.1 Rodar o script

O `organograma.sql` é **idempotente** (`create or replace`): pode rodar quantas vezes quiser. Rode **sempre** que o arquivo mudar.

**Opção 1 · SQLcl (recomendado)**

```bash
cd /caminho/para/corlix-hub
sql -cloudconfig /caminho/para/Wallet_xxx.zip WKSP_CORLIXHUB@<servico>_high
```

```sql
@modulos/organograma/organograma.sql
show errors package body pkg_organograma
```

**Opção 2 · SQL Workshop**

1. **SQL Workshop › SQL Scripts › Upload** e escolha `modulos/organograma/organograma.sql`.
2. Clique em **Run** (e em **Run Now** na confirmação).
3. Abra o resultado: todas as instruções devem estar como *Success*.

> Não use o **SQL Commands** para este arquivo: ele executa um comando por vez e não entende a barra `/` que encerra o package.

### 4.2 Conferir a instalação

Rode no SQL Commands (um comando por vez) ou no SQLcl:

```sql
-- 1. Os dois objetos existem e estão válidos (STATUS = VALID)
select object_name, object_type, status
  from user_objects
 where object_name in ('VW_ORG_COLABORADOR', 'PKG_ORGANOGRAMA');

-- 2. Nenhum erro de compilação (deve voltar vazio)
select line, position, text
  from user_errors
 where name = 'PKG_ORGANOGRAMA';

-- 3. Quantos colaboradores ativos entram no organograma
select count(*) from vw_org_colaborador;

-- 4. Ativos que ficaram de fora (sem cargo ou departamento válido)
select c.id_colaborador, c.nome_completo, c.id_cargo, c.id_departamento
  from colaborador c
 where c.status = true
   and c.id_colaborador not in (select id_colaborador from vw_org_colaborador);

-- 5. Quem não tem gestor (candidatos a topo) e o tamanho da estrutura de cada um
select connect_by_root nome_completo as raiz, count(*) as pessoas
  from vw_org_colaborador
 start with id_gestor is null
connect by nocycle prior id_colaborador = id_gestor
 group by connect_by_root nome_completo
 order by pessoas desc;

-- 6. O topo escolhido pelo package (deve ser a primeira linha da consulta 5)
select pkg_organograma.id_raiz from dual;

-- 7. A conta que vai testar está vinculada? (troque pelo seu login APEX)
select id_colaborador, nome_completo, login_apex, status
  from colaborador
 where upper(trim(login_apex)) = upper(trim('SEU_LOGIN_APEX'));
```

> `pkg_organograma.id_usuario` usa `APP_USER`, que só existe dentro de uma sessão do APEX. No SQL Commands ele devolve `null`; por isso a consulta 7 faz a mesma busca à mão.

---

## 5. Etapa 2 · App APEX: escolha o caminho

A página 3 **já está montada no repositório** (`p00003-organograma.apx`). Falta levar isso para o app que roda no APEX:

| Caminho | Quando usar | Vantagem | Cuidado |
|---|---|---|---|
| **A · Importar pelo APEXlang** | Você tem SQLcl + wallet e o repositório está em dia com o app | Fica idêntico ao repositório, sem digitar nada | O import **substitui o app inteiro**: o que foi feito no Builder e não está no repositório se perde |
| **B · Montar no App Builder** | Não há SQLcl, ou o app tem mudanças que ainda não estão no repositório | Mexe só na página 3 | Mais passos manuais; siga a seção 7 campo a campo |

Na dúvida, use o **Caminho B**.

---

## 6. Caminho A · Importar pelo APEXlang (SQLcl)

### 6.1 Fazer um backup do app atual

No App Builder: **App 100 › Export / Import › Export**, formato padrão, e guarde o `f100.sql`. Ou, no SQLcl:

```sql
apex export -applicationid 100
```

### 6.2 Conferir se o repositório está em dia

```bash
git checkout DEV && git pull
git log --oneline -5 -- corlixhub/   # o último "chore(backup)" deve ser recente
```

Se alguém alterou o app no Builder **depois** do último backup, essas alterações não estão no repositório e seriam apagadas pelo import. Nesse caso use o Caminho B.

### 6.3 Validar o APEXlang

Não precisa de conexão:

```bash
sql -S /nolog <<'EOF'
apex validate -input corlixhub
exit
EOF
```

Resultado esperado: `Validation successful.` Hoje aparecem só dois avisos antigos que não têm a ver com o organograma (alias da p7 e `templateOptions` da p4).

### 6.4 Importar

```bash
sql -cloudconfig /caminho/para/Wallet_xxx.zip WKSP_CORLIXHUB@<servico>_high
```

```sql
apex import -input corlixhub -workspace WKSP_CORLIXHUB
```

O import envia também os arquivos estáticos novos (`organograma.css` e `organograma.min.css`).

### 6.5 Depois do import

1. Rode de novo o `organograma.sql` (Etapa 1) se ainda não rodou.
2. Siga para os **Testes de aceite** (seção 8).

---

## 7. Caminho B · Montar no App Builder, campo a campo

Abra **App Builder › CorlixHub (100) › Página 3 · Organograma**. A página já tem a região *Breadcrumb*, a região *Organograma Principal*, o item `P3_BUSCA` e o item `P3_ID_FOCO`. Os passos abaixo completam o que falta e corrigem o que estava errado.

### 7.1 Subir o CSS como arquivo estático

1. **Shared Components › Files and Reports › Static Application Files › Create File**.
2. Envie `corlixhub/shared-components/static-files/organograma.css`.
   - **Directory:** deixe em branco (o arquivo fica na raiz).
   - **File Name:** `organograma.css` (exatamente assim).
3. Repita com `corlixhub/shared-components/static-files/organograma.min.css` → **File Name** `organograma.min.css`.

> Os **dois** arquivos são necessários. O `#MIN#` da URL vira `.min` quando o app roda sem debug e some quando o debug está ligado.

### 7.2 Atributos da página 3

Clique no nó **Page 3: Organograma** (raiz da árvore à esquerda) e preencha no painel de propriedades:

| Grupo | Propriedade | Valor |
|---|---|---|
| JavaScript | Function and Global Variable Declaration | Todo o **bloco 1** de `organograma.js`: da linha `const ORG_ITEM_FOCO = "P3_ID_FOCO";` até o fim da função `orgCliqueNoDrawer` (antes do comentário "Execute when Page Loads") |
| JavaScript | Execute when Page Loads | Todo o **bloco 2** de `organograma.js`: os dois `$("#" + ORG_REGIAO).on(...)` (antes do comentário "Dynamic Action") |
| CSS | File URLs | `#APP_FILES#organograma#MIN#.css` |
| Security | Page Access Protection | *Arguments Must Have Checksum* (mantenha) |

Confira que a constante do bloco 1 está como `"P3_ID_FOCO"`. Se aparecer `P10_ID_FOCO`, o arquivo é de uma versão antiga.

### 7.3 Item `P3_ID_FOCO` (pessoa em foco)

| Grupo | Propriedade | Valor |
|---|---|---|
| Identification | Name | `P3_ID_FOCO` |
| Identification | Type | *Hidden* |
| Settings | **Value Protected** | **No** (obrigatório: o JS troca o valor) |
| Layout | Sequence | `20` |
| Layout | Region | *(nenhuma)* · slot *Body* |
| Source | Type | *Null* (padrão) |

> Com *Value Protected = Yes*, "Ver equipe", o caminho e a busca falham com erro de proteção de estado da sessão.

### 7.4 Região "Organograma Principal"

| Grupo | Propriedade | Valor |
|---|---|---|
| Identification | Title | `Organograma Principal` |
| Identification | Type | *Dynamic Content* |
| Source | Language | *PL/SQL* |
| Source | PL/SQL Function Body returning a CLOB | ver abaixo |
| Source | Page Items to Submit | `P3_ID_FOCO` |
| Layout | Sequence | `10` · slot *Body* |
| Appearance | Template | *Blank with Attributes* |
| Advanced | **Static ID** | `organograma` (minúsculo, exatamente assim: o JS procura `#organograma`) |

```sql
return pkg_organograma.render(
         to_number(:P3_ID_FOCO default null on conversion error));
```

### 7.5 Item `P3_BUSCA` (busca de pessoa)

| Grupo | Propriedade | Valor |
|---|---|---|
| Identification | Name | `P3_BUSCA` |
| Identification | Type | *Popup LOV* |
| Label | Label | `Buscar pessoa no organograma` (fica oculto, mas é lido por leitores de tela) |
| Layout | Sequence | **`5`** (menor que o da região, para ficar **acima** do organograma) · slot *Body* |
| Appearance | Template | **Hidden** (era *Optional - Floating*, que mostrava o rótulo "Novo") |
| Appearance | Value Placeholder | `Buscar pessoa no organograma` |
| Appearance | Width | `30` |
| List of Values | Type | *SQL Query* |
| List of Values | SQL Query | ver abaixo |

```sql
select nome_completo || ' — ' || cargo d,
       id_colaborador r
from vw_org_colaborador
order by nome_completo
```

O CSS (`#P3_BUSCA_CONTAINER`) limita o campo a 300px e o alinha à direita, como no protótipo.

### 7.6 Dynamic Action "Ir para pessoa buscada"

1. Aba **Dynamic Actions › Events › Change › Create Dynamic Action**.

| Grupo | Propriedade | Valor |
|---|---|---|
| Identification | Name | `Ir para pessoa buscada` |
| When | Event | *Change* |
| When | Selection Type | *Item(s)* |
| When | Item(s) | `P3_BUSCA` |

2. Na ação **True** criada automaticamente:

| Grupo | Propriedade | Valor |
|---|---|---|
| Identification | Action | *Execute JavaScript Code* |
| Settings | Code | **bloco 3** de `organograma.js` (abaixo) |
| Execution | Fire on Initialization | *No* |

```javascript
const id = $v("P3_BUSCA");
if (id) {
  orgIrPara(id);
  apex.item("P3_BUSCA").setValue("", null, true); // limpa sem disparar Change de novo
}
```

### 7.7 Processo Ajax Callback `ORG_DETALHES` (drawer)

1. Aba **Processing** (ícone de engrenagens) › clique com o botão direito em **Ajax Callback › Create Process**.

| Grupo | Propriedade | Valor |
|---|---|---|
| Identification | Name | **`ORG_DETALHES`** (maiúsculas, exatamente assim: é o nome chamado pelo JS) |
| Identification | Type | *Execute Code* |
| Source | Language | *PL/SQL* |
| Source | PL/SQL Code | ver abaixo |
| Execution | Point | *Ajax Callback* |
| Execution | Sequence | `10` |

```sql
apex_util.prn(
  p_clob   => pkg_organograma.render_detalhes(
                to_number(apex_application.g_x01 default null on conversion error)),
  p_escape => false);
```

> `p_escape => false` é intencional: o package já escapa todos os dados com `apex_escape`.

### 7.8 Salvar e rodar

1. **Save**.
2. **Run** (página 3) e siga a seção 8.

---

## 8. Etapa 3 · Testes de aceite

Faça os testes logado com uma conta **vinculada** a um colaborador (ex.: a da diretoria) e depois com uma conta **sem vínculo** (ex.: `SARAHSILVA`, `EDUARDOMARINS` ou `ALAIRTONROCHA`, que são da equipe técnica).

| # | Ação | Resultado esperado |
|---|---|---|
| 1 | Abrir **Organograma** no menu lateral com conta vinculada | A pessoa em foco é o **próprio usuário**; o caminho mostra "Corlix › … › seu nome" |
| 2 | Abrir com conta **sem** vínculo | A pessoa em foco é o **topo da hierarquia**, com a tag "Topo da hierarquia" e a estrutura abaixo dela |
| 3 | Olhar o card em foco | Avatar (foto ou iniciais), nome, "cargo · departamento", resumo "N subordinados diretos · M pessoas na estrutura", botões "Ver perfil" e "Conversar" |
| 4 | Card do **próprio** usuário | O botão "Conversar" **não** aparece |
| 5 | Clicar em **"Ver equipe"** num card de subordinado | Só a região atualiza (sem recarregar a página); o subordinado vira o foco e o caminho ganha um nível |
| 6 | Clicar num nome do **caminho** | Volta para aquele nível |
| 7 | Clicar em **"Corlix"** no caminho | Vai para o topo da cadeia da pessoa em foco |
| 8 | Clicar no **card** de um subordinado (fora do "Ver equipe") | Abre o **drawer** à direita com fundo escurecido, primeiro "Carregando detalhes…" e depois o conteúdo |
| 9 | Clicar em **"Ver perfil"** no card em foco | Abre o drawer da pessoa em foco |
| 10 | No drawer: seção **Contato** | E-mail clicável (`mailto:`); o botão de copiar mostra ✓ por 2 segundos e o e-mail fica na área de transferência |
| 11 | No drawer: **Reporta-se a** / **Equipe direta** | Clicar numa pessoa troca o conteúdo do drawer **sem fechar** |
| 12 | No drawer: **"Ver equipe no organograma"** | Fecha o drawer e navega para a equipe daquela pessoa |
| 13 | No drawer: **Sobre** | Departamento, Empresa, "Na Corlix desde" (ex.: "fevereiro de 2026 · 7 meses") e Aniversário só com dia e mês |
| 14 | Fechar o drawer com **Esc**, com o **X** e clicando no **fundo escurecido** | Fecha nos três casos |
| 15 | Digitar um nome na **busca** e escolher | O organograma vai para a pessoa escolhida e o campo é limpo |
| 16 | Colaborador **sem foto** ou com foto inexistente | Aparecem as **iniciais**, sem ícone de imagem quebrada |
| 17 | Abrir com **Debug** ligado (barra de desenvolvedor) | Tudo funciona igual (o CSS carrega o `organograma.css` sem `.min`) |
| 18 | Tela estreita (< 760px) | Cards em uma coluna, sem a linha horizontal dos conectores |

---

## 9. Etapa 4 · Sincronizar o repositório (não pule)

O job de backup no Jenkins (diário, 02h) **exporta o app de PRD e commita em `DEV`** (`chore(backup): …`). Ou seja:

- Se você mudou o **repositório** e **não** levou a mudança para o app, o próximo backup **desfaz** a mudança no `DEV` (ele sobrescreve `corlixhub/` com o que está no APEX).
- Se você mudou o **app no Builder** (Caminho B), o próximo backup traz a mudança para o `DEV`. Confira o diff do commit de backup: a página 3 deve ficar igual à do repositório (JS, CSS, `ORG_DETALHES`, `valueProtected: false`, `P3_BUSCA` com sequence 5 e template hidden).

O que **não** vem pelo backup e precisa ser commitado à mão: `modulos/organograma/*` (SQL, CSS e JS fonte) e `docs/ai-context/*`.

---

## 10. Como funciona

### 10.1 Fluxo da página

```
Abrir a p3
 └─ região "organograma" executa pkg_organograma.render(:P3_ID_FOCO)
     ├─ P3_ID_FOCO nulo        → id_usuario (LOGIN_APEX = APP_USER)
     ├─ id inválido / inativo / sem vínculo → id_raiz (ativo sem gestor com a maior estrutura)
     └─ devolve o HTML: caminho + card em foco + cards dos subordinados + texto de ajuda

Clique em "Ver equipe" / caminho / busca
 └─ orgIrPara(id): grava P3_ID_FOCO e dá refresh só na região

Clique no card / "Ver perfil"
 └─ orgAbrirDetalhes(id): abre o <dialog> com spinner
     └─ apex.server.process("ORG_DETALHES", {x01: id}) → render_detalhes(id) → HTML do drawer
```

### 10.2 Pessoa em foco

| Situação | Quem aparece em foco |
|---|---|
| Página aberta pelo menu | O usuário logado |
| Usuário sem colaborador ativo vinculado | O topo da hierarquia |
| `P3_ID_FOCO` com o id de um ativo | Essa pessoa |
| `P3_ID_FOCO` inválido ou de um inativo | O topo da hierarquia |
| Nenhum colaborador ativo | Mensagem "Nenhum colaborador ativo encontrado." |

### 10.3 Abrir o organograma numa pessoa a partir de outra página

A página exige checksum nos parâmetros, então gere a URL pelo APEX:

```sql
apex_page.get_url(p_page => 3, p_items => 'P3_ID_FOCO', p_values => <id_colaborador>)
```

Ou, num botão/link do Builder: **Target › Page 3**, **Set Items** `P3_ID_FOCO` = `&ID_COLABORADOR.` (ou o item da sua página). O histórico de carreira já usa esse padrão (`c_pagina_organograma = 3`, `c_item_organograma = 'P3_ID_FOCO'`).

### 10.4 Fotos

1. `FOTO_URL` preenchido:
   - URL completa (`https://…`), caminho absoluto (`/…`) ou substituição (`#APP_FILES#…`) → usado como está.
   - Só o nome do arquivo → `#APP_FILES#Fotos Colaboradores/<arquivo>` (com o espaço codificado).
2. Sem `FOTO_URL` mas com `IMAGEM_PERFIL` (BLOB) → `APPLICATION_PROCESS=DOWNLOAD_FOTO` com o item `ID_COLABORADOR` (**ainda não existe no app**, ver seção 14).
3. As **iniciais** ficam sempre por baixo. Se a imagem não carregar, o `onerror` remove a `<img>` e as iniciais aparecem.

### 10.5 Contagens

- **Subordinados diretos:** ativos com `ID_GESTOR` = pessoa em foco.
- **Pessoas na estrutura:** todos os ativos abaixo dela, em qualquer nível (`connect by`), sem contar ela mesma.
- **Prévia da equipe** nos cards: até 3 avatares e nomes; acima disso, "+N" e "e mais N".
- **Equipe direta** no drawer: até 8 pessoas (`c_max_equipe`); acima disso, "e mais N na equipe".

---

## 11. Configuração (constantes do package)

Ficam na **spec** de `pkg_organograma` (`organograma.sql`). Depois de mudar, rode o script de novo.

| Constante | Valor atual | O que controla |
|---|---|---|
| `c_nome_empresa` | `'Corlix'` | Primeiro item do caminho, "Empresa" e "Na Corlix desde" no drawer |
| `c_pagina_perfil` / `c_item_perfil` | `2` / `null` | Destino de "Ver perfil completo" (p2 Meu perfil, sem parâmetro) |
| `c_pagina_chat` / `c_item_chat` | `4` / `null` | Destino de "Conversar" (p4 Chat, sem parâmetro) |
| `c_pasta_fotos` | `'Fotos Colaboradores/'` | Pasta das fotos dentro dos *Static Application Files* |
| `c_max_equipe` | `8` | Quantas pessoas listar em "Equipe direta" no drawer |

Com o item `null`, o link abre a página sem dizer qual pessoa. Quando a p2 ou a p4 aceitarem um colaborador pela URL, preencha o item (ex.: `c_item_perfil := 'P2_ID_COLABORADOR'`) e o package passa o id automaticamente.

---

## 12. Solução de problemas

| Sintoma | Causa provável | Como resolver |
|---|---|---|
| Abre em outra pessoa (ex.: alguém sem equipe), não no usuário logado | `LOGIN_APEX` do colaborador não bate com o usuário APEX, ou o colaborador está inativo / sem cargo ou departamento | Consultas 4 e 7 da seção 4.2; corrija `LOGIN_APEX`, `STATUS`, `ID_CARGO` ou `ID_DEPARTAMENTO` |
| Abre no usuário, mas "0 subordinados" | A pessoa não tem ninguém ativo com `ID_GESTOR` apontando para ela | Confira a hierarquia: `select nome_completo from vw_org_colaborador where id_gestor = <id>` |
| O topo é a pessoa errada | Há mais de um ativo sem gestor e o "topo real" tem estrutura menor | Consulta 5 da seção 4.2; preencha `ID_GESTOR` de quem deveria estar abaixo |
| Clicar no card **não faz nada** | JS não está na página, ou a região não tem Static ID `organograma` | Seções 7.2 e 7.4. No console do navegador (F12), `typeof orgAbrirDetalhes` deve ser `"function"` e `document.getElementById("organograma")` não pode ser `null` |
| O drawer abre mas mostra "Não foi possível carregar os detalhes." | O processo `ORG_DETALHES` não existe, tem outro nome ou não é *Ajax Callback*; ou o package está inválido | Seção 7.7 e consultas 1 e 2 da seção 4.2. Teste no console: `apex.server.process("ORG_DETALHES", {x01: 1}, {dataType: "text"}).done(console.log)` |
| "Ver equipe", o caminho ou a busca dão erro de proteção de sessão | `P3_ID_FOCO` com *Value Protected = Yes* | Seção 7.3 |
| "Ver equipe" atualiza mas continua na mesma pessoa | `P3_ID_FOCO` fora de *Page Items to Submit* da região | Seção 7.4 |
| A página aparece sem estilo (texto corrido) | CSS não foi enviado ou a URL está errada | Seção 7.1 e 7.2; confira se existem **os dois** arquivos (`.css` e `.min.css`) |
| Estilo funciona com debug e quebra sem debug (ou o contrário) | Falta um dos dois arquivos | Envie o que faltar (seção 7.1) |
| A busca aparece embaixo, com o rótulo "Novo" | Versão antiga do item | Seção 7.5: sequence `5` e template *Hidden* |
| Ícone de imagem quebrada no avatar | Package antigo (sem o fallback) | Rode o `organograma.sql` atual |
| Só iniciais, mesmo com `FOTO_URL` | O arquivo não existe em `Fotos Colaboradores/` ou o nome difere (maiúsculas, extensão) | Compare `FOTO_URL` com os nomes em *Static Application Files* |
| "Conversar" ou "Ver perfil completo" abrem a página errada | Constantes `c_pagina_*` | Seção 11 |
| Mudança do repositório sumiu no dia seguinte | O backup sobrescreveu `corlixhub/` com o app de PRD | Seção 9: leve a mudança para o app antes do backup |
| `ORA-04063` / `ORA-06508` na região | Package inválido depois de alterar tabelas | Rode o `organograma.sql` de novo |

---

## 13. Manutenção

### 13.1 Alterar o CSS

1. Edite **`modulos/organograma/organograma.css`** (fonte).
2. Copie para `corlixhub/shared-components/static-files/organograma.css`.
3. Gere de novo o `organograma.min.css` (não há script de minificação no projeto; qualquer minificador de CSS serve) e confira que o número de `{` e `}` é igual.
4. No APEX, substitua os dois arquivos em *Static Application Files* (ou importe o app).
5. Use as variáveis `--org-*` (que leem os tokens `--cx-*` do tema) em vez de cores fixas, e mantenha a política **sem sombras** do tema.

### 13.2 Alterar o JS

1. Edite `modulos/organograma/organograma.js`, respeitando os três blocos.
2. Copie cada bloco para o lugar correspondente na página 3 (seções 7.2 e 7.6) ou para o `p00003-organograma.apx`.
3. Novas ações no HTML seguem o contrato `data-acao` + `data-id` (ações atuais: `foco`, `detalhe`, `equipe`, `fechar`, `copiar`).

### 13.3 Alterar o HTML / regras

1. Edite o package em `organograma.sql`. Todo dado do banco deve passar por `e()` (texto) ou `a()` (atributo); textos fixos com acento usam entidades HTML (`&atilde;`).
2. Rode o script (Etapa 1) e repita os testes da seção 8.
3. Atualize `docs/ai-context/06-modulos.md` §1 e este guia.

---

## 14. Limitações conhecidas e pendências

- **Multiempresa:** a view e a busca **não filtram por `ID_EMPRESA`**. Com mais de uma empresa no schema, o topo e a busca misturam empresas. Solução prevista: filtrar por `G_ID_EMPRESA`, como o histórico de carreira.
- **Privacidade:** a nota do drawer diz que só aparecem dados visíveis a todos, mas e-mail, admissão e aniversário aparecem para qualquer usuário logado. `render_detalhes` também não verifica permissão. Se necessário, criar uma flag de visibilidade no cadastro.
- **Perfil e chat:** os links vão para as p2 e p4 **sem** indicar a pessoa, porque essas páginas ainda não recebem o colaborador pela URL.
- **Fotos em BLOB:** precisam do Application Item `ID_COLABORADOR` e do Application Process `DOWNLOAD_FOTO`, que não existem no app.
- **Mais de 2 subordinados:** os cards quebram em linhas de 2 e os conectores ligam só a primeira linha.
- **Gestor inativo:** quem se reporta a ele some da navegação até ser realocado.
- **Título da página:** a descrição "Estrutura da Corlix a partir das relações de gestão." do protótipo ainda não aparece, e a busca fica acima do organograma (não dentro da barra de título).

---

## 15. Histórico de mudanças

| Data | Mudança |
|---|---|
| — | Versão com OrgChart JS (removida): região `painel-detalhes`, processos `GET_ORGANOGRAMA`/`GET_DETALHES_SETOR`, função `fn_organograma_json`. Se ainda existirem no seu banco/app, podem ser apagados; a tabela `departamento_metrica` e a coluna `id_lider` ficaram sem uso |
| — | Redesign por níveis + drawer de detalhes (`render_detalhes`, `ORG_DETALHES`), ainda fora do app (guia usava a página 10) |
| 09/10/2026 | **Integração na página 3:** JS com `P3_`, CSS publicado como arquivo estático, Ajax Callback `ORG_DETALHES`, `P3_ID_FOCO` sem proteção de valor, busca acima do organograma sem o rótulo "Novo", DA de busca |
| 09/10/2026 | **Foco inicial no usuário logado** (`id_usuario`); **topo** passa a ser o ativo sem gestor com a maior estrutura (antes era o menor id, que caía numa conta técnica sem equipe) |
| 09/10/2026 | **Fotos:** `FOTO_URL` com nome de arquivo vira `#APP_FILES#Fotos Colaboradores/<arquivo>`; iniciais por baixo como fallback. Links de perfil e chat apontam para as p2 e p4 |

# Histórico de Carreira · passo a passo no APEX

Este guia monta as páginas do módulo no App Builder do **APEX 26.1.5**, a versão do ambiente (o app já é versionado em APEXlang, `mmdVersion 26.1.0`). O banco precisa estar instalado antes: rode o `instalar.sql` (veja o `README-historico-carreira.md`).

Depois de montar as páginas no Builder, exporte o app em APEXlang como já é feito hoje, para que as páginas novas entrem no Git em `corlixhub/pages/`.

> Os nomes de menus e atributos abaixo seguem o Builder. Se algum rótulo estiver diferente na 26.1, o atributo equivalente costuma ficar na mesma seção do painel de propriedades.

| Página | Nome | Tipo | Quem acessa |
|---|---|---|---|
| 13 | Histórico de carreira (já existe, vazia) | Normal | ADMIN_RH, gestor da equipe, o próprio colaborador |
| 18 | Movimentação | Modal Dialog | ADMIN_RH |
| 19 | Formações e certificações | Normal | ADMIN_RH |
| 20 | Dashboard RH | Normal | ADMIN_RH |
| 21 | Anexo da formação | Modal Dialog | ADMIN_RH |
| 22 | Solicitar correção | Modal Dialog | O próprio colaborador |
| 23 | Responder solicitação | Modal Dialog | ADMIN_RH |

Se algum desses números já estiver em uso, troque o prefixo `P18_`, `P19_` etc. nos itens, no `historico-carreira.js` e nas constantes do `08_pkg_historico_carreira_ui.sql`.

---

## 1. Shared Components

### 1.1 Isolamento por empresa: `G_ID_EMPRESA`

1. **Application Items > Create**
   - Name: `G_ID_EMPRESA`
   - Scope: Application
   - Session State Protection: **Restricted - May not be set from browser**
2. **Application Processes > Create**
   - Name: `SET_G_ID_EMPRESA`
   - Process Point: **After Authentication**
   - Source:
     ```sql
     begin
       select id_empresa
         into :G_ID_EMPRESA
         from colaborador
        where upper(trim(login_apex)) = upper(trim(:APP_USER));
     exception
       when no_data_found or too_many_rows then
         :G_ID_EMPRESA := null;
     end;
     ```
3. Sessões já abertas não passam pelo After Authentication. Depois de publicar, saia e entre de novo.

O package recusa qualquer operação em sessão APEX sem `G_ID_EMPRESA`. Toda query das páginas abaixo também filtra por `:G_ID_EMPRESA`.

### 1.2 Papel e esquemas de autorização

1. O papel `Admin RH` (Static ID `admin-rh`) e o esquema `ADMIN_RH` já existem na app (módulo `modulos/perfis-acesso/`). Os usuários do RH recebem o papel automaticamente ao serem cadastrados na P14. Crie aqui só `GESTOR` e `COLABORADOR`.
2. **Authorization Schemes > Create** (os nomes precisam ser exatamente estes, porque o package e a view consultam `ADMIN_RH` pelo nome):

| Nome | Tipo | Configuração |
|---|---|---|
| `ADMIN_RH` | Is In Role or Group | Type: Application Role · Names: `Admin RH` · Evaluation Point: Once per session |
| `GESTOR` | PL/SQL Function Returning Boolean | Código abaixo · Once per session |
| `COLABORADOR` | PL/SQL Function Returning Boolean | Código abaixo · Once per session |

`GESTOR`: tem pelo menos um subordinado direto na mesma empresa.
```sql
declare
  l_qt pls_integer;
begin
  select count(*)
    into l_qt
    from colaborador s
    join colaborador g on g.id_colaborador = s.id_gestor
   where upper(g.login_apex) = upper(:APP_USER)
     and g.id_empresa = :G_ID_EMPRESA;
  return l_qt > 0;
end;
```

`COLABORADOR`: tem cadastro na empresa ou é do RH. Esse é o esquema de leitura da página 13.
```sql
declare
  l_qt pls_integer;
begin
  if apex_authorization.is_authorized('ADMIN_RH') then
    return true;
  end if;
  select count(*)
    into l_qt
    from colaborador
   where upper(login_apex) = upper(:APP_USER)
     and id_empresa = :G_ID_EMPRESA;
  return l_qt > 0;
end;
```

O detalhe "gestor só vê a própria equipe" fica na função `pkg_historico_carreira.fn_pode_ver_colaborador`, chamada pela página 13 (item 2.2). Ela libera o colaborador para o gestor de qualquer nível acima dele.

### 1.3 Mensagens de erro amigáveis

A aplicação já usa `log_pkg.apex_error_handler` como Error Handling Function. Para os erros do módulo (-20001 a -20099) aparecerem sem "ORA-" e sem pilha, escolha uma das opções:

- **Opção A (recomendada):** dentro do `log_pkg.apex_error_handler`, depois de registrar o log, delegue esses códigos:
  ```sql
  if p_error.ora_sqlcode between -20099 and -20001 then
    return pkg_historico_carreira.fn_tratar_erro(p_error);
  end if;
  ```
- **Opção B:** nas páginas 18, 19 e 21, em *Page > Error Handling > Error Handling Function*, informe `pkg_historico_carreira.fn_tratar_erro`. Essas páginas deixam de passar pelo `log_pkg` nesse caso.

### 1.4 Listas de valores (Shared Components > List of Values)

Todas do tipo *SQL Query*:

`LOV_TIPO_MOVIMENTACAO`
```sql
select ds_tipo d, id_tipo_movimentacao r
  from tipo_movimentacao
 where id_empresa = :G_ID_EMPRESA
   and fl_ativo = true
 order by nr_ordem, ds_tipo
```

`LOV_DEPARTAMENTO_EMPRESA`
```sql
select nome d, id_departamento r
  from departamento
 where id_empresa = :G_ID_EMPRESA
 order by nome
```

`LOV_COLABORADOR_ATIVO`
```sql
select nome_completo d, id_colaborador r
  from colaborador
 where id_empresa = :G_ID_EMPRESA
   and status = true
 order by nome_completo
```

`LOV_TIPO_FORMACAO` (Static): Graduação `GRADUACAO`, Pós-graduação `POS`, MBA `MBA`, Curso `CURSO`, Certificação `CERTIFICACAO`, Idioma `IDIOMA`.

---

## 2. Página 13 · Histórico de carreira

A página segue o protótipo *"Histórico de carreira — nova página"*. Como no organograma, o conteúdo é uma região **Dynamic Content** que chama `pkg_historico_carreira_ui.render`. O package monta o resumo, a faixa "Cargos ao longo do tempo", a linha do tempo com abas e filtro de ano, a posição atual e o quadro "Sobre este histórico".

O que cada perfil vê:
- **Colaborador:** o próprio histórico, inclusive reajustes por mérito, e o botão "Solicitar correção".
- **Gestor:** a equipe, sem os reajustes por mérito e sem o motivo de afastamentos.
- **RH:** tudo, mais a contagem de solicitações abertas daquela pessoa.

Salário nunca aparece nessa região: o valor fica só na lista "Lançamentos (RH)".

### 2.1 Atributos da página

- Authorization Scheme: `COLABORADOR`
- Item `P13_ID_COLABORADOR`: Hidden · Value Protected: Yes · Session State Protection: **Checksum Required - Session Level**
- Remova a região de breadcrumb (`title-bar`) que a página tem hoje: o título e o botão "Exportar PDF" já vêm na região.

### 2.2 Processos Before Header (nesta ordem)

1. **Colaborador padrão** (PL/SQL, seq. 10): sem parâmetro, abre o histórico do próprio usuário.
   ```sql
   if :P13_ID_COLABORADOR is null then
     select id_colaborador
       into :P13_ID_COLABORADOR
       from colaborador
      where upper(login_apex) = upper(:APP_USER)
        and id_empresa = :G_ID_EMPRESA;
   end if;
   ```
2. **Validar acesso** (PL/SQL, seq. 20):
   ```sql
   if :P13_ID_COLABORADOR is null
      or pkg_historico_carreira.fn_pode_ver_colaborador(:P13_ID_COLABORADOR) = 'N' then
     raise_application_error(-20012, 'Você não tem acesso ao histórico deste colaborador.');
   end if;
   ```
3. **Registrar acesso salarial** (PL/SQL, seq. 30) · Authorization Scheme `ADMIN_RH`. Só é necessário por causa da região "Lançamentos (RH)", que mostra salário.
   ```sql
   pkg_historico_carreira.registrar_acesso_salarial(
     p_id_colaborador => :P13_ID_COLABORADOR,
     p_contexto       => 'P13 · lançamentos do histórico');
   ```

### 2.3 CSS e JavaScript

1. Suba `historico-carreira.css` em *Shared Components > Static Application Files* e informe `#APP_FILES#historico-carreira#MIN#.css` em *Page > CSS > File URLs*. Também dá para colar o conteúdo em *CSS > Inline*. Se usar `#MIN#`, suba também uma versão minificada, como o app já faz com o `custom.css`.
2. `historico-carreira-pagina.js` tem dois blocos. Cole o primeiro em *JavaScript > Function and Global Variable Declaration* e o segundo em *Execute when Page Loads*.
3. Template da página: para a região ocupar a largura toda sobre o fundo `#F1EFED` do protótipo, use o page template **Standard** com a região em *Body*, e a Template Option *Remove Body Padding*, se existir no seu tema.

### 2.4 Região "Histórico de carreira"

- Type: **Dynamic Content** · Static ID: `historico_carreira` (o JS usa esse ID)
- Appearance > Template: *Blank with Attributes*
- Source > PL/SQL Function Body returning a CLOB:
  ```sql
  return pkg_historico_carreira_ui.render(:P13_ID_COLABORADOR);
  ```
- Page Items to Submit: `P13_ID_COLABORADOR`

Ajuste as constantes no topo de `08_pkg_historico_carreira_ui.sql` para o seu app, e rode o arquivo de novo:

| Constante | Padrão | Uso |
|---|---|---|
| `c_pagina_organograma` / `c_item_organograma` | 3 / `P3_ID_FOCO` | "Ver no organograma". Use o item de foco que você criou no organograma (no guia daquele módulo ele aparece como `P10_ID_FOCO`). |
| `c_pagina_comunicado` / `c_item_comunicado` | 11 / nulo | "Ver comunicado". Com item nulo, abre a lista de comunicados. |
| `c_pagina_holerite` | nulo | "Ver holerite" no mérito. Nulo esconde o link até o holerite existir. |
| `c_pagina_solicitacao` / `c_item_solicitacao` | nulo / `P22_ID_COLABORADOR` | Botão "Solicitar correção". Fica nulo até a página 22 existir (§6); com 22 e sem o item, a página 13 dá `ERR-1002` |
| `c_pagina_painel_rh` | 20 | Link para o RH ver as solicitações abertas |

### 2.5 Região "Lançamentos (RH)"

Lista de todos os lançamentos, incluindo rascunhos. É por aqui que o RH edita um rascunho ou estorna. Fica abaixo da região principal.

- Type: Interactive Report · Authorization Scheme: `ADMIN_RH` · Template Options: Collapsible (fechada)
- Source:
  ```sql
  select id_historico_carreira, dt_efetiva, ds_tipo, st_registro, fl_estorno,
         nm_cargo_anterior, nm_cargo_novo, nm_departamento_anterior, nm_departamento_novo,
         nm_gestor_novo, vl_salario_anterior, vl_salario_novo, ds_motivo,
         usr_efetivacao, dt_efetivacao
    from vw_historico_carreira
   where id_colaborador = :P13_ID_COLABORADOR
     and id_empresa     = :G_ID_EMPRESA
   order by dt_efetiva desc, id_historico_carreira desc
  ```
- Colunas `VL_SALARIO_ANTERIOR` e `VL_SALARIO_NOVO`: Server-side Condition **Authorization Scheme `ADMIN_RH`**. A view já mascara o salário para outros perfis; a condição tira até o cabeçalho da coluna.
- Coluna `ID_HISTORICO_CARREIRA`: Type Link · Target página 18 · Items `P18_ID_HISTORICO_CARREIRA` = `#ID_HISTORICO_CARREIRA#`, `P18_ID_COLABORADOR` = `&P13_ID_COLABORADOR.` · Clear Cache 18 · Link Text `<span class="fa fa-edit"></span>`

### 2.6 Botões do RH

Em uma região *Buttons Container* acima da região principal, com Authorization `ADMIN_RH`:

| Botão | Ação |
|---|---|
| `NOVA_MOVIMENTACAO` ("Nova movimentação", Hot) | Redirect página 18 · `P18_ID_COLABORADOR` = `&P13_ID_COLABORADOR.` · Clear Cache 18 |
| `FORMACOES` ("Formações") | Redirect página 19 · `P19_ID_COLABORADOR` = `&P13_ID_COLABORADOR.` |

### 2.7 Dynamic Action "Atualizar depois da modal"

- Event: **Dialog Closed** · Selection Type: JavaScript Expression · `document`
- True actions: Refresh `Histórico de carreira` e Refresh `Lançamentos (RH)`

Esse refresh vale também para a modal "Solicitar correção" (página 22): a contagem de solicitações em análise aparece logo depois.

### 2.8 Seletor de colaborador (RH)

Sem parâmetro, a página abre no próprio usuário. Para o RH abrir o histórico de qualquer pessoa sem depender da página 12 (Colaboradores), coloque um seletor no topo, visível só para `ADMIN_RH`.

**Região**
- Na região *Buttons Container* do §2.6, ou numa região Static Content própria acima de "Histórico de carreira", com Authorization `ADMIN_RH`.

**Item `P13_COLABORADOR_SELECIONADO`**
- Type: **Popup LOV** · Label "Ver histórico de" · Authorization Scheme `ADMIN_RH`
- Source: nenhum · Default › Type **Item** › `P13_ID_COLABORADOR` (abre mostrando quem está na tela)
- List of Values › Type **SQL Query** (inclui inativos, porque o RH também consulta quem saiu):
  ```sql
  select nome_completo
         || case when status then null else ' (inativo)' end as d,
         id_colaborador as r
    from colaborador
   where id_empresa = :G_ID_EMPRESA
   order by nome_completo
  ```
- Display Null Value: Off

**Dynamic Action "Trocar colaborador"**
- Event: **Change** · Item: `P13_COLABORADOR_SELECIONADO`
- Client-side Condition: Item **is not null** › `P13_COLABORADOR_SELECIONADO`
- True action: **Submit Page** · Request/Button Name: `TROCAR_COLABORADOR` · Show Processing: On

**Processo "Trocar colaborador"** (Processing, Sequence 5)
- Type: Execute Code · Server-side Condition: **Request = Value** › `TROCAR_COLABORADOR` · Authorization `ADMIN_RH`
  ```sql
  :P13_ID_COLABORADOR := :P13_COLABORADOR_SELECIONADO;
  ```

**Branch "Recarregar"** (After Processing)
- Target: página **13**, sem itens nem Clear Cache. O valor novo já está na sessão.
- Server-side Condition: Request = Value › `TROCAR_COLABORADOR`

Por que assim: a página recarrega inteira, então os processos Before Header do §2.2 rodam de novo para o colaborador escolhido (validação de acesso e log de acesso salarial). Trocar o item só no navegador e dar Refresh pularia esses dois. `P13_ID_COLABORADOR` continua protegido por checksum, porque quem muda o valor é o processo no servidor.

O valor escolhido fica na sessão. Para o menu "Histórico de carreira" voltar sempre ao próprio usuário, coloque **Clear Cache: `13`** nessa entrada do Navigation Menu.

O caminho definitivo continua sendo o link "Histórico" na lista da página 12 (§7). O seletor resolve o RH enquanto ela não existe e pode ficar depois.

### 2.9 O que o protótipo mostra e ainda não tem dado

- **PDI e Resultados 360:** os módulos de Avaliações, Resultados 360 e Plano de desenvolvimento não existem no app. A aba "Desenvolvimento" mostra, por enquanto, as formações e certificações. Quando esses módulos existirem, basta acrescentar um `union all` no cursor `c_eventos`, com `ds_grupo = 'DEV'`.
- **"Aprovado por":** não há fluxo de aprovação no app. O RH informa quem aprovou (`P18_ID_APROVADOR` → `HISTORICO_CARREIRA.ID_APROVADOR`) ao lançar a movimentação, e o rodapé mostra "Aprovado por ..." ao lado de "Registrado por ... (RH) em ...". Sem aprovador informado, só a linha do registro aparece.
- **"CLT · efetivado":** o cadastro não guarda o regime de contratação. A linha "Contrato" aparece como "Efetivado em dd/mm/aaaa" quando existe uma movimentação `EFETIVACAO_CONTRATO`.

---

## 3. Página 18 · Modal Nova/Editar Movimentação

### 3.1 Atributos

- Page Mode: **Modal Dialog** · Authorization Scheme: `ADMIN_RH`
- JavaScript: cole os blocos 1 e 2 do `historico-carreira.js` em *Function and Global Variable Declaration* e *Execute when Page Loads*

### 3.2 Região "Movimentação"

- Type: **Form** · Source: Table/View `VW_HISTORICO_CARREIRA` · Primary Key: `ID_HISTORICO_CARREIRA`
- **Não** crie o processo "Automatic Row Processing (DML)". A view serve só para carregar; toda gravação passa pelo package.
- Processo Before Header **Initialize form** (Form - Initialization): mantenha o que o assistente cria.

Itens (crie os que não vierem do assistente):

| Item | Tipo | Detalhes |
|---|---|---|
| `P18_ID_HISTORICO_CARREIRA` | Hidden | PK · Value Protected |
| `P18_ID_COLABORADOR` | Hidden | Value Protected · Session State Protection: Checksum Required - Session Level |
| `P18_ST_REGISTRO` | Display Only | Label "Situação" · Default `RASCUNHO` |
| `P18_FL_ESTORNO` | Hidden | |
| `P18_CD_TIPO` | Hidden | Value Protected: **No** (o JS lê o valor) |
| `P18_ID_DEPARTAMENTO_ATUAL` | Hidden | Source: nenhum · Default (SQL): `select id_departamento from colaborador where id_colaborador = :P18_ID_COLABORADOR and id_empresa = :G_ID_EMPRESA` |
| `P18_ID_TIPO_MOVIMENTACAO` | Select List | LOV `LOV_TIPO_MOVIMENTACAO` · obrigatório |
| `P18_DT_EFETIVA` | Date Picker | Format Mask `DD/MM/YYYY` · obrigatório |
| `P18_NM_CARGO_ANTERIOR` | Display Only | Label "Cargo atual" · Source: Database Column `NM_CARGO_ANTERIOR` · Settings › Based On: **Page Item Value** · **Default** › Type: **SQL Query** (não use List of Values): `select cg.nome from colaborador c join cargo cg on cg.id_cargo = c.id_cargo where c.id_colaborador = :P18_ID_COLABORADOR and c.id_empresa = :G_ID_EMPRESA` |
| `P18_NM_DEPARTAMENTO_ANTERIOR` | Display Only | Label "Departamento atual" · mesma configuração do item acima, com Source `NM_DEPARTAMENTO_ANTERIOR` e Default (SQL Query): `select d.nome from colaborador c join departamento d on d.id_departamento = c.id_departamento where c.id_colaborador = :P18_ID_COLABORADOR and c.id_empresa = :G_ID_EMPRESA` |
| `P18_ID_DEPARTAMENTO_NOVO` | Popup LOV | LOV `LOV_DEPARTAMENTO_EMPRESA` · Label "Novo departamento" |
| `P18_ID_CARGO_NOVO` | Popup LOV | Label "Novo cargo" · LOV em cascata (abaixo) |
| `P18_ID_GESTOR_NOVO` | Popup LOV | LOV `LOV_COLABORADOR_ATIVO` · Label "Novo gestor" |
| `P18_VL_SALARIO_ANTERIOR` | Number Field | Server-side Condition: Authorization `ADMIN_RH` · sem Format Mask |
| `P18_VL_SALARIO_NOVO` | Number Field | Server-side Condition: Authorization `ADMIN_RH` · sem Format Mask |
| `P18_DS_MOTIVO` | Textarea | Max 1000 |
| `P18_ID_APROVADOR` | Popup LOV | LOV `LOV_COLABORADOR_ATIVO` · Label "Aprovado por" · opcional (em geral a gestão que aprovou; não pode ser o próprio colaborador) · aparece em todos os tipos |
| `P18_DS_OBSERVACAO` | Textarea | |
| `P18_DS_MOTIVO_ESTORNO` | Textarea | Source: nenhum · Label "Motivo do estorno" · **fica fora da região do formulário**, numa região própria "Estorno" (abaixo) |

**Região "Estorno"** (só para o motivo do estorno):
- Type: **Static Content** · Slot: Body · Sequence 20 (depois de "Movimentação") · Template: Standard
- Server-side Condition (Expression): `:P18_ST_REGISTRO = 'EFETIVADO' and :P18_FL_ESTORNO = 'N'`
- Mova `P18_DS_MOTIVO_ESTORNO` para ela (*Layout › Region*: `Estorno`) e tire a condição do item, que passa a ser da região.

Dentro da região de formulário, ao abrir um lançamento existente, o campo não aceita digitação: o motivo do estorno não é coluna da view, então fica numa região à parte.

Os campos de cargo e departamento anteriores aparecem preenchidos com a situação atual do colaborador. Na efetivação o package grava o snapshot definitivo.

**Cascading LOV do cargo** (`P18_ID_CARGO_NOVO` > List of Values > SQL Query):
```sql
select cg.nome d, cg.id_cargo r
  from cargo cg
 where cg.id_empresa = :G_ID_EMPRESA
   and cg.id_departamento = coalesce(to_number(:P18_ID_DEPARTAMENTO_NOVO),
                                     to_number(:P18_ID_DEPARTAMENTO_ATUAL))
 order by cg.nome
```
- Cascading List of Values > Parent Item(s): `P18_ID_DEPARTAMENTO_NOVO` · Items to Submit: `P18_ID_DEPARTAMENTO_ATUAL` · Parent Required: **No**

Para edição só de rascunho: em todos os itens editáveis, *Read Only* com condição `:P18_ST_REGISTRO <> 'RASCUNHO'`.

### 3.3 Dynamic Action "Tipo mudou"

Quando o RH troca o tipo da movimentação, a página descobre o código do tipo (`PROMOCAO`, `MERITO`…) e mostra só os campos que fazem sentido para ele. São duas ações em sequência: a primeira busca o código no banco e guarda em `P18_CD_TIPO`; a segunda roda o JS que mostra e esconde os campos lendo esse item.

**Antes de começar, confira:**

- [ ] Os blocos 1 e 2 do `historico-carreira.js` já estão na página (§3.1). Sem o bloco 1, a ação 2 dá `carreira is not defined` no console.
- [ ] `P18_CD_TIPO` existe, é **Hidden**, tem **Value Protected: No** e Source **Database Column** `CD_TIPO` (a view tem essa coluna; é assim que o tipo vem preenchido ao editar um rascunho).
- [ ] `P18_ID_TIPO_MOVIMENTACAO` tem opção vazia: *List of Values > Display Null Value* **On**, com *Null Display Value* `- Selecione -`. Sem ela o select abre já com "Admissão", nenhum Change dispara e `P18_CD_TIPO` fica vazio, então os campos de Admissão não aparecem.
- [ ] `P18_ID_CARGO_NOVO`, `P18_ID_DEPARTAMENTO_NOVO`, `P18_ID_GESTOR_NOVO` e os dois salários estão com **Validation > Value Required: Off**. Eles ficam escondidos em vários tipos, e um item obrigatório escondido trava o envio. A obrigatoriedade é feita pelo JS (marca visual) e validada de novo pelo package.

#### Passo 1 · Criar a Dynamic Action

1. Abra a página 18 no Page Designer.
2. Na aba **Rendering** (painel da esquerda), localize o item `P18_ID_TIPO_MOVIMENTACAO` dentro da região "Movimentação".
3. Clique com o botão direito no item e escolha **Create Dynamic Action**. O APEX cria a DA já ligada ao item, com uma ação *Show* de exemplo.
4. Com a DA selecionada (o nó com o raio), preencha no painel da direita:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Tipo mudou` |
| When | Event | **Change** |
| When | Selection Type | Item(s) |
| When | Item(s) | `P18_ID_TIPO_MOVIMENTACAO` |
| Client-side Condition | Type | (nenhuma) |

#### Passo 2 · Ação 1: Set Value (busca o código do tipo)

1. Embaixo da DA, abra **True** e clique na ação *Show* que o APEX criou.
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Action | **Set Value** |
| Settings | Set Type | **SQL Statement** |
| Settings | SQL Statement | (SQL abaixo) |
| Settings | Items to Submit | `P18_ID_TIPO_MOVIMENTACAO` |
| Settings | Escape Special Characters | On (padrão) |
| Settings | Suppress Change Event | On |
| Affected Elements | Selection Type | Item(s) |
| Affected Elements | Item(s) | `P18_CD_TIPO` |
| Execution | Sequence | 10 |
| Execution | Fire on Initialization | **Off** |
| Execution | Wait For Result | **On** |

```sql
select cd_tipo
  from tipo_movimentacao
 where id_tipo_movimentacao = :P18_ID_TIPO_MOVIMENTACAO
   and id_empresa = :G_ID_EMPRESA
```

Por que cada um importa:
- **Items to Submit:** o SQL roda no servidor e só enxerga o valor novo do select list se ele for enviado. Sem isso, `:P18_ID_TIPO_MOVIMENTACAO` chega vazio (ou com o valor antigo) e `P18_CD_TIPO` fica em branco. `G_ID_EMPRESA` é app item e já está na sessão, então não precisa entrar aqui.
- **Wait For Result:** faz a ação 2 esperar a resposta do servidor. Desligado, o JS roda antes de `P18_CD_TIPO` mudar e mostra os campos do tipo *anterior*.
- **Fire on Initialization Off:** no carregamento quem ajusta os campos é o bloco 2 do JS, com o `CD_TIPO` que já veio da view.

#### Passo 3 · Ação 2: Execute JavaScript Code (mostra/esconde os campos)

1. Clique com o botão direito em **True** e escolha **Create TRUE Action**.
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Action | **Execute JavaScript Code** |
| Settings | Code | `carreira.ajustarCampos(true);` (bloco 3 do `.js`) |
| Affected Elements | Selection Type | (nenhum) |
| Execution | Sequence | 20 (precisa ser **maior** que a da ação 1) |
| Execution | Fire on Initialization | **Off** |

O `true` manda limpar os campos que ficaram escondidos, para não gravar, por exemplo, um cargo "fantasma" num mérito. No carregamento o bloco 2 chama `ajustarCampos(false)`, que preserva os valores do rascunho.

3. Salve a página (**Save**, Ctrl+S).

A árvore deve ficar assim:

```
Dynamic Actions
└── Change
    └── Tipo mudou            (Change · P18_ID_TIPO_MOVIMENTACAO)
        └── True
            ├── Set Value                  seq 10 → P18_CD_TIPO
            └── Execute JavaScript Code    seq 20
```

#### O que aparece em cada tipo

| Tipo | Novo cargo | Novo departamento | Novo gestor | Salários |
|---|---|---|---|---|
| Admissão | sim | sim | sim | sim |
| Promoção | **obrigatório** | – | sim | sim |
| Mudança de cargo | **obrigatório** | – | sim | sim |
| Transferência de área | sim | **obrigatório** | sim | – |
| Mudança de gestão | – | – | **obrigatório** | – |
| Mérito | – | – | – | sim |
| Efetivação, Jornada, Afastamento, Retorno, Desligamento | – | – | – | – |

Tipo, data, motivo, aprovador e observação aparecem sempre. Os salários só existem para quem tem `ADMIN_RH` (o JS ignora itens que não foram renderizados). Para mudar essas regras, edite `carreira.visivelEm` e `carreira.obrigatorioEm` no bloco 1 do JS; o package também descarta cargo, departamento e gestor nos tipos que não mexem na estrutura.

#### Passo 4 · Testar

1. Rode a página 13 de um colaborador e clique em **Nova movimentação**.
2. Abra o console do navegador (F12) e escolha **Promoção**: devem aparecer Novo cargo (com marca de obrigatório), Novo gestor e os salários. Digite `$v('P18_CD_TIPO')` no console: deve responder `"PROMOCAO"`.
3. Escolha um cargo, troque para **Mérito**: o cargo some e, ao voltar para Promoção, aparece vazio.
4. Salve um rascunho de Transferência, feche e reabra pelo ícone de edição na lista "Lançamentos (RH)": o departamento novo continua visível e preenchido.

#### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Nenhum campo some ao trocar o tipo | `P18_CD_TIPO` vazio | Confira *Items to Submit* da ação 1 e se o tipo tem `id_empresa` igual ao `G_ID_EMPRESA` da sessão |
| Os campos mostrados são os do tipo anterior | Ação 2 rodou antes da 1 terminar | *Wait For Result* On na ação 1 e sequência da ação 2 maior |
| `carreira is not defined` no console | Bloco 1 do JS não está na página | Cole-o em *Page > JavaScript > Function and Global Variable Declaration* |
| Ao salvar: "Session state protection violation" / item protegido alterado | `P18_CD_TIPO` com Value Protected On | Mude para **No** |
| Ao salvar: "... must have some value" num campo escondido | Item com Value Required On | Desligue *Value Required* nos itens da lista acima |
| Na movimentação nova o select já vem com um tipo e nenhum campo extra aparece | Select list sem opção vazia | *Display Null Value* On em `P18_ID_TIPO_MOVIMENTACAO` |
| Ao abrir um rascunho os campos certos não aparecem | `P18_CD_TIPO` sem Source | Source: Database Column `CD_TIPO` |

### 3.4 Botões

A modal tem cinco botões, e cada situação do lançamento mostra só os que fazem sentido:

| Situação | Botões visíveis |
|---|---|
| Nova movimentação | Cancelar · Salvar rascunho · Efetivar |
| Rascunho já salvo | Cancelar · Excluir rascunho · Salvar rascunho · Efetivar |
| Efetivado (não estornado) | Cancelar · Estornar |
| Estornado | Cancelar |

O nome do botão vira o *request* da submissão (`:REQUEST`), e é por ele que os processos da §3.5 decidem o que rodar. Por isso use **exatamente** os nomes da tabela, em maiúsculas.

**Antes de começar, confira:**

- [ ] O item `P18_ST_REGISTRO` tem Default `RASCUNHO` e `P18_FL_ESTORNO` tem Source `FL_ESTORNO` (§3.2). As condições dos botões leem esses dois itens.

#### Passo 1 · Criar a região dos botões

1. Na aba **Rendering**, clique com o botão direito em **Dialog Footer** e escolha **Create Region**.
2. Preencha:

| Seção | Atributo | Valor |
|---|---|---|
| Identification | Name | `Botões` |
| Identification | Type | **Static Content** |
| Layout | Slot (Position) | **Dialog Footer** |
| Appearance | Template | **Buttons Container** |

Com isso os botões ficam fixos no rodapé da modal, como na página 27 (Nova Equipe).

#### Passo 2 · Criar os botões

Para cada linha da tabela abaixo: clique com o botão direito na região **Botões** › **Create Button**, e preencha os atributos.

| Button Name | Label | Slot (Button Position) | Sequence | Appearance |
|---|---|---|---|---|
| `CANCELAR` | Cancelar | **Close** | 10 | padrão |
| `EXCLUIR` | Excluir rascunho | **Delete** | 20 | padrão |
| `ESTORNAR` | Estornar | **Delete** | 30 | Template Options › Type: **Danger** |
| `SALVAR_RASCUNHO` | Salvar rascunho | **Next** | 40 | padrão |
| `EFETIVAR` | Efetivar | **Next** | 50 | **Hot: On** |

Em todos os botões, preencha também **Security › Authorization Scheme:** `ADMIN_RH`. A página já exige esse papel, e a autorização no botão é uma segunda proteção.

#### Passo 3 · Comportamento e condição de cada botão

**`CANCELAR`**
- Behavior › Action: **Defined by Dynamic Action**
- Clique com o botão direito no botão › **Create Dynamic Action** › Name `Cancelar` (Event *Click* já vem preenchido) › True action: **Cancel Dialog**
- Server-side Condition: nenhuma (aparece sempre)

**`EXCLUIR`**
- Behavior › Action: **Submit Page** · Execute Validations: **Off** · Warn on Unsaved Changes: *Do Not Check*
- Behavior › Requires Confirmation: **On** › Message `Excluir este rascunho?` › Style **Danger**
- Server-side Condition › Type **Expression** (PL/SQL):
  ```sql
  :P18_ST_REGISTRO = 'RASCUNHO' and :P18_ID_HISTORICO_CARREIRA is not null
  ```

**`ESTORNAR`**
- Behavior › Action: **Submit Page** · Execute Validations: **Off**
- Behavior › Requires Confirmation: **On** › Message `Estornar este lançamento?` › Style **Danger**
- Server-side Condition › Type **Expression**:
  ```sql
  :P18_ST_REGISTRO = 'EFETIVADO' and :P18_FL_ESTORNO = 'N'
  ```

**`SALVAR_RASCUNHO`**
- Behavior › Action: **Submit Page** · Execute Validations: **On** (padrão)
- Server-side Condition › Type **Expression**:
  ```sql
  nvl(:P18_ST_REGISTRO, 'RASCUNHO') = 'RASCUNHO'
  ```

**`EFETIVAR`**
- Behavior › Action: **Submit Page** · Execute Validations: **On**
- Behavior › Requires Confirmation: **On** › Message `Depois de efetivado, o lançamento não pode ser alterado. Continuar?` › Style **Warning**
- Server-side Condition › Type **Expression**:
  ```sql
  nvl(:P18_ST_REGISTRO, 'RASCUNHO') = 'RASCUNHO'
  ```

Por que esses detalhes importam:
- **`nvl(..., 'RASCUNHO')`:** a condição do botão pode ser avaliada antes de o Default do item ser aplicado. Numa movimentação nova `P18_ST_REGISTRO` ainda está nulo, e sem o `nvl` os botões Salvar e Efetivar sumiriam.
- **Execute Validations Off em Excluir e Estornar:** essas ações não dependem do formulário. Sem isso, um campo obrigatório vazio (ou somente leitura num lançamento efetivado) impediria a exclusão ou o estorno. O motivo do estorno é validado pelo package.
- **Requires Confirmation:** é o diálogo nativo do APEX, o mesmo que a página 16 usa. Não precisa de DA nem de JavaScript para confirmar.

Salve a página (**Save**, Ctrl+S). A árvore deve ficar assim:

```
Dialog Footer
└── Botões                 (Static Content · Buttons Container)
    ├── Close    CANCELAR          seq 10
    ├── Delete   EXCLUIR           seq 20
    ├── Delete   ESTORNAR          seq 30  (Danger)
    ├── Next     SALVAR_RASCUNHO   seq 40
    └── Next     EFETIVAR          seq 50  (Hot)
```

No export APEXlang, cada botão fica parecido com este:

```
button efetivar (
    buttonName: EFETIVAR
    label: Efetivar
    layout {
        sequence: 50
        region: @botões
        slot: next
    }
    appearance {
        buttonTemplate: @/text
        hot: true
        templateOptions: #DEFAULT#
    }
    behavior {
        requiresConfirmation: true
    }
    confirmation {
        message: Depois de efetivado, o lançamento não pode ser alterado. Continuar?
        style: warning
    }
    serverSideCondition {
        type: expression
        plsqlExpression: nvl(:P18_ST_REGISTRO, 'RASCUNHO') = 'RASCUNHO'
    }
    security {
        authorizationScheme: @admin-rh
    }
)
```

#### Passo 4 · Testar

Os botões que enviam a página só gravam alguma coisa depois que os processos da §3.5 existirem. Por enquanto, teste se eles aparecem nas situações certas:

1. Na página 13, clique em **Nova movimentação**: devem aparecer só *Cancelar*, *Salvar rascunho* e *Efetivar*.
2. Clique em **Cancelar**: a modal fecha sem erro.
3. Clique em **Efetivar**: deve abrir a confirmação. Clique em *Cancelar* no diálogo, porque o processo ainda não existe.
4. Depois de montar a §3.5, repita com um rascunho salvo (deve aparecer *Excluir rascunho*) e com um lançamento efetivado (só *Cancelar* e *Estornar*).

#### Se não funcionar

| Sintoma | Causa provável | Correção |
|---|---|---|
| Salvar e Efetivar não aparecem numa movimentação nova | Condição sem `nvl` | Use `nvl(:P18_ST_REGISTRO, 'RASCUNHO') = 'RASCUNHO'` |
| Efetivar aparece antes de Salvar rascunho (ou a ordem muda sozinha) | Botões do mesmo slot com a mesma sequência | Use as sequências da tabela do Passo 2 (40 e 50) |
| Os botões aparecem no meio do formulário | Região criada no Body | Mova a região `Botões` para o slot **Dialog Footer** |
| Cancelar não fecha a modal | Action ficou *Submit Page* ou a DA não tem *Cancel Dialog* | Action **Defined by Dynamic Action** e DA Click com *Cancel Dialog* |
| Clicar no botão recarrega a modal e nada acontece | Processos da §3.5 ainda não existem, ou o nome do botão difere do request do processo | Confira a grafia exata (`SALVAR_RASCUNHO`, `EFETIVAR`…) |
| Excluir ou Estornar mostra "... must have some value" | Execute Validations On | Desligue *Execute Validations* nesses dois botões |
| Botão não aparece para o RH | Authorization Scheme errado no botão | Use `ADMIN_RH` e confira se o usuário tem o papel |

### 3.5 Processos (Processing, nesta ordem)

Nenhum faz DML direto: todos chamam o package.

1. **Salvar movimentação** · PL/SQL · roda com `SALVAR_RASCUNHO` **ou** `EFETIVAR`. *When Button Pressed* aceita um botão só, então deixe-o **vazio** e use *Server-side Condition* › Type **Request is contained in Value** › Value `SALVAR_RASCUNHO,EFETIVAR` (nomes dos botões, separados por vírgula, sem espaço). Sem isso, Efetivar numa movimentação nova chama `efetivar_movimentacao` com ID nulo.
   ```sql
   begin
     if :P18_ID_HISTORICO_CARREIRA is null then
       :P18_ID_HISTORICO_CARREIRA := pkg_historico_carreira.registrar_movimentacao(
         p_id_colaborador       => :P18_ID_COLABORADOR,
         p_id_tipo_movimentacao => :P18_ID_TIPO_MOVIMENTACAO,
         p_dt_efetiva           => to_date(:P18_DT_EFETIVA, 'DD/MM/YYYY'),
         p_id_cargo_novo        => :P18_ID_CARGO_NOVO,
         p_id_departamento_novo => :P18_ID_DEPARTAMENTO_NOVO,
         p_id_gestor_novo       => :P18_ID_GESTOR_NOVO,
         p_vl_salario_anterior  => to_number(:P18_VL_SALARIO_ANTERIOR),
         p_vl_salario_novo      => to_number(:P18_VL_SALARIO_NOVO),
         p_ds_motivo            => :P18_DS_MOTIVO,
         p_ds_observacao        => :P18_DS_OBSERVACAO,
         p_id_aprovador         => :P18_ID_APROVADOR);
     else
       pkg_historico_carreira.atualizar_rascunho(
         p_id_historico_carreira => :P18_ID_HISTORICO_CARREIRA,
         p_id_tipo_movimentacao  => :P18_ID_TIPO_MOVIMENTACAO,
         p_dt_efetiva            => to_date(:P18_DT_EFETIVA, 'DD/MM/YYYY'),
         p_id_cargo_novo         => :P18_ID_CARGO_NOVO,
         p_id_departamento_novo  => :P18_ID_DEPARTAMENTO_NOVO,
         p_id_gestor_novo        => :P18_ID_GESTOR_NOVO,
         p_vl_salario_anterior   => to_number(:P18_VL_SALARIO_ANTERIOR),
         p_vl_salario_novo       => to_number(:P18_VL_SALARIO_NOVO),
         p_ds_motivo             => :P18_DS_MOTIVO,
         p_ds_observacao         => :P18_DS_OBSERVACAO,
         p_id_aprovador          => :P18_ID_APROVADOR);
     end if;
   end;
   ```
2. **Efetivar** · When Button Pressed `EFETIVAR` · Success Message "Movimentação efetivada."
   ```sql
   pkg_historico_carreira.efetivar_movimentacao(:P18_ID_HISTORICO_CARREIRA);
   ```
3. **Estornar** · When Button Pressed `ESTORNAR` · Success Message "Lançamento estornado."
   ```sql
   pkg_historico_carreira.estornar_movimentacao(:P18_ID_HISTORICO_CARREIRA, :P18_DS_MOTIVO_ESTORNO);
   ```
4. **Excluir rascunho** · When Button Pressed `EXCLUIR`
   ```sql
   pkg_historico_carreira.excluir_rascunho(:P18_ID_HISTORICO_CARREIRA);
   ```
5. **Fechar** · Type: Close Dialog · Server-side Condition: Request is contained in Value `SALVAR_RASCUNHO,EFETIVAR,ESTORNAR,EXCLUIR`

Os processos 1 e 2 rodam na mesma submissão. Se a efetivação falhar, o APEX desfaz também o rascunho salvo no passo 1 (tudo é uma transação só) e a mensagem do package aparece na modal.

### 3.6 Log de acesso salarial

Processo Before Header (depois do *Initialize form*) · Authorization `ADMIN_RH` · Server-side Condition: `P18_ID_HISTORICO_CARREIRA` is not null
```sql
pkg_historico_carreira.registrar_acesso_salarial(
  p_id_colaborador => :P18_ID_COLABORADOR,
  p_contexto       => 'P18 · lançamento #' || :P18_ID_HISTORICO_CARREIRA);
```

---

## 4. Página 19 · Formações e certificações

- Authorization Scheme: `ADMIN_RH`
- Item `P19_ID_COLABORADOR`: Hidden · Checksum Required - Session Level
- Processo Before Header **Validar acesso**: o mesmo código do item 2.2 (passo 2), com `P19_`.

### 4.1 Região "Formações" (Interactive Grid)

- Source:
  ```sql
  select f.id_formacao,
         f.id_empresa,
         f.id_colaborador,
         f.tp_formacao,
         f.ds_titulo,
         f.ds_instituicao,
         f.dt_inicio,
         f.dt_conclusao,
         f.dt_validade,
         f.nr_carga_horaria,
         f.ds_link,
         f.ds_nome_arquivo,
         case
           when f.tp_formacao = 'CERTIFICACAO'
            and f.dt_validade < pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA)      then 'VENCIDA'
           when f.tp_formacao = 'CERTIFICACAO'
            and f.dt_validade <= pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA) + 60 then 'A VENCER'
         end as ds_alerta_validade
    from formacao_colaborador f
   where f.id_colaborador = :P19_ID_COLABORADOR
     and f.id_empresa     = :G_ID_EMPRESA
  ```
- Attributes > Edit: Enabled · Allowed Operations: Add, Update, Delete
- Colunas:
  - `ID_FORMACAO`: Hidden · Primary Key
  - `ID_EMPRESA`: Hidden · Value Protected · Default: Item `G_ID_EMPRESA`
  - `ID_COLABORADOR`: Hidden · Value Protected · Default: Item `P19_ID_COLABORADOR`
  - `TP_FORMACAO`: Select List · LOV `LOV_TIPO_FORMACAO`
  - `DT_INICIO`, `DT_CONCLUSAO`, `DT_VALIDADE`: Date Picker `DD/MM/YYYY`
  - `DS_ALERTA_VALIDADE`: Display Only · **Query Only: Yes**
  - `DS_NOME_ARQUIVO`: Link · Target página 21 · `P21_ID_FORMACAO` = `&ID_FORMACAO.` · Link Text: `&DS_NOME_ARQUIVO.` (ou "Anexar" quando vazio, via `nvl` na query) · Query Only: Yes
- Processo **Salvar formações**: Interactive Grid - Automatic Row Processing (DML). Para formações o DML nativo é aceitável: a imutabilidade vale só para movimentações. As constraints da tabela validam as datas, o tipo e o link.

**Destaque das certificações a vencer:** rode a página, abra *Actions > Format > Highlight* e crie:
- "A vencer": Column `DS_ALERTA_VALIDADE` = `A VENCER` · Background amarelo · Highlight: Row
- "Vencida": Column `DS_ALERTA_VALIDADE` = `VENCIDA` · Background vermelho claro

Depois salve como relatório **Primary** (*Actions > Report > Save*, como desenvolvedor).

> Até o APEX 24.2, o Interactive Grid não fazia upload de arquivo; por isso o anexo fica na página 21. Se a sua 26.1.5 já oferecer um tipo de coluna de upload no IG, dá para dispensar a página 21 e mapear `BL_ANEXO`, `DS_MIME_TYPE` e `DS_NOME_ARQUIVO` direto na grid.

### 4.2 Página 21 · Anexo da formação (Modal)

- Authorization: `ADMIN_RH`
- Região Form sobre `FORMACAO_COLABORADOR` · PK `ID_FORMACAO`, só com os itens:
  - `P21_ID_FORMACAO` (Hidden, Checksum Required)
  - `P21_BL_ANEXO`: **File Upload** (antigo *File Browse*; não use *Image Upload*, que é o tipo da página 17, porque o anexo pode ser PDF) · Storage Type: BLOB column specified in Item Source attribute · MIME Type Column `DS_MIME_TYPE` · Filename Column `DS_NOME_ARQUIVO` · Download Link Text "Baixar anexo"
  - `P21_DS_LINK`: Text Field (URL)
- Processos: Form - Initialization e Form - Automatic Row Processing (somente Update), depois Close Dialog.
- Validação **Formação da empresa** (PL/SQL Function Body Returning Boolean):
  ```sql
  declare
    l_qt pls_integer;
  begin
    select count(*) into l_qt
      from formacao_colaborador
     where id_formacao = :P21_ID_FORMACAO
       and id_empresa  = :G_ID_EMPRESA;
    return l_qt = 1;
  end;
  ```
- Na página 19, DA *Dialog Closed* > Refresh na grid.

---

## 5. Página 20 · Dashboard RH

- Authorization Scheme: `ADMIN_RH`
- Itens de período: `P20_DT_INICIO` e `P20_DT_FIM` (Date Picker `DD/MM/YYYY`). Defaults (PL/SQL Expression):
  - Início: `to_char(add_months(trunc(pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA), 'mm'), -11), 'DD/MM/YYYY')`
  - Fim: `to_char(pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA), 'DD/MM/YYYY')`
- DA Change nos dois itens: Refresh nos gráficos 5.1 e 5.2.

Todas as consultas usam só movimentações válidas: efetivadas, não estornadas e que não são lançamentos de estorno (`VW_MOVIMENTACAO_VALIDA`).

### 5.1 Promoções por departamento (Chart · Bar)

```sql
select nvl(d.nome, '(sem departamento)') as departamento,
       count(*)                          as promocoes
  from vw_movimentacao_valida v
  left join departamento d on d.id_departamento = v.id_departamento_novo
 where v.id_empresa = :G_ID_EMPRESA
   and v.cd_tipo    = 'PROMOCAO'
   and v.dt_efetiva between to_date(:P20_DT_INICIO, 'DD/MM/YYYY') and to_date(:P20_DT_FIM, 'DD/MM/YYYY')
 group by d.nome
 order by promocoes desc
```
Label `DEPARTAMENTO` · Value `PROMOCOES` · Items to Submit: `P20_DT_INICIO,P20_DT_FIM`

### 5.2 Turnover: admissões x desligamentos por mês (Chart · Bar, 2 séries)

```sql
with meses as (
  select add_months(trunc(to_date(:P20_DT_INICIO, 'DD/MM/YYYY'), 'mm'), level - 1) as mes
    from dual
 connect by add_months(trunc(to_date(:P20_DT_INICIO, 'DD/MM/YYYY'), 'mm'), level - 1)
            <= to_date(:P20_DT_FIM, 'DD/MM/YYYY')
)
select to_char(m.mes, 'mm/yyyy')                                          as mes,
       count(case when v.cd_tipo = 'ADMISSAO'     then 1 end)             as admissoes,
       count(case when v.cd_tipo = 'DESLIGAMENTO' then 1 end)             as desligamentos
  from meses m
  left join vw_movimentacao_valida v
         on v.id_empresa = :G_ID_EMPRESA
        and trunc(v.dt_efetiva, 'mm') = m.mes
        and v.cd_tipo in ('ADMISSAO', 'DESLIGAMENTO')
 group by m.mes
 order by m.mes
```
Série 1 "Admissões": Label `MES` · Value `ADMISSOES`. Série 2 "Desligamentos": a mesma query, Value `DESLIGAMENTOS`.

> A carga inicial cria admissões com a data de `DATA_ADMISSAO`, então o histórico de admissões já começa preenchido. Desligamentos só existem a partir do uso do módulo.

### 5.3 Tempo médio no cargo por departamento (Chart · Bar horizontal)

```sql
select nvl(s.nm_departamento, '(sem departamento)') as departamento,
       round(avg(months_between(pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA),
                                s.dt_inicio_funcao)) / 12, 1) as anos_no_cargo
  from vw_situacao_atual_colaborador s
 where s.id_empresa       = :G_ID_EMPRESA
   and s.fl_vinculo_ativo = 'S'
 group by s.nm_departamento
 order by anos_no_cargo desc
```
Value Axis title: "anos"

### 5.4 Certificações a vencer (Classic Report)

```sql
select c.nome_completo        as colaborador,
       f.ds_titulo            as certificacao,
       f.ds_instituicao       as emissor,
       f.dt_validade          as validade,
       f.dt_validade - pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA) as dias_restantes
  from formacao_colaborador f
  join colaborador c on c.id_colaborador = f.id_colaborador
 where f.id_empresa  = :G_ID_EMPRESA
   and f.tp_formacao = 'CERTIFICACAO'
   and f.dt_validade between pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA)
                         and pkg_historico_carreira.fn_hoje(:G_ID_EMPRESA) + 60
 order by f.dt_validade
```
Coluna `COLABORADOR` como link para a página 19 (`P19_ID_COLABORADOR`).

---

### 5.5 Solicitações de correção abertas (Interactive Report)

```sql
select s.id_solicitacao,
       c.nome_completo                         as colaborador,
       s.ds_mensagem                           as solicitacao,
       h.dt_efetiva                            as data_lancamento,
       t.ds_tipo                               as lancamento,
       pkg_historico_carreira.fn_data_local(s.id_empresa, s.dt_criacao) as aberta_em,
       s.id_colaborador
  from solicitacao_correcao s
  join colaborador c             on c.id_colaborador        = s.id_colaborador
  left join historico_carreira h on h.id_historico_carreira = s.id_historico_carreira
  left join tipo_movimentacao  t on t.id_tipo_movimentacao  = h.id_tipo_movimentacao
 where s.id_empresa     = :G_ID_EMPRESA
   and s.st_solicitacao = 'ABERTA'
 order by s.dt_criacao
```
- Coluna `COLABORADOR`: link para a página 13 (`P13_ID_COLABORADOR` = `#ID_COLABORADOR#`), onde o RH estorna e lança de novo.
- Coluna `ID_SOLICITACAO`: link "Responder" para uma modal simples com `P23_ID_SOLICITACAO`, um Radio Group `P23_ST_SOLICITACAO` (Resolvida `RESOLVIDA` / Recusada `RECUSADA`) e `P23_DS_RESPOSTA`. O processo da modal:
  ```sql
  pkg_historico_carreira.responder_solicitacao(:P23_ID_SOLICITACAO, :P23_ST_SOLICITACAO, :P23_DS_RESPOSTA);
  ```

---

## 6. Página 22 · Solicitar correção (Modal)

> Ao terminar esta página, volte `c_pagina_solicitacao` para `22` em `08_pkg_historico_carreira_ui.sql` e rode o arquivo de novo, para o botão "Solicitar correção" aparecer na página 13.

- Page Mode: **Modal Dialog** · Authorization Scheme: `COLABORADOR` · Title "Solicitar correção"
- Itens:
  - `P22_ID_COLABORADOR`: Hidden · Checksum Required - Session Level
  - `P22_ID_HISTORICO_CARREIRA`: Select List opcional, Label "Qual registro?", Null display "Não sei / vários". Query:
    ```sql
    select to_char(h.dt_efetiva, 'dd/mm/yyyy') || ' · ' || t.ds_tipo d, h.id_historico_carreira r
      from historico_carreira h
      join tipo_movimentacao t on t.id_tipo_movimentacao = h.id_tipo_movimentacao
     where h.id_colaborador = :P22_ID_COLABORADOR
       and h.id_empresa     = :G_ID_EMPRESA
       and h.st_registro    = 'EFETIVADO'
       and h.id_registro_estornado is null
     order by h.dt_efetiva desc
    ```
  - `P22_DS_MENSAGEM`: Textarea obrigatório, Label "O que está incorreto?", Max 2000
- Texto de apoio: "O RH revisa o pedido. Se houver correção, ela também fica registrada no histórico."
- Botões: `CANCELAR` (Cancel Dialog) e `ENVIAR` (Hot)
- Processo **Enviar** · When Button Pressed `ENVIAR`:
  ```sql
  declare
    l_id number;
  begin
    l_id := pkg_historico_carreira.solicitar_correcao(
              p_id_colaborador        => :P22_ID_COLABORADOR,
              p_ds_mensagem           => :P22_DS_MENSAGEM,
              p_id_historico_carreira => :P22_ID_HISTORICO_CARREIRA);
  end;
  ```
- Processo **Fechar** · Close Dialog · Server-side Condition: When Button Pressed `ENVIAR` · Success Message "Pedido enviado ao RH."

O package confere que quem pede é o próprio colaborador. Mesmo com o checksum, ninguém consegue abrir pedidos em nome de outra pessoa.

---

## 7. Ligações com páginas existentes

1. **Página 14 · Cadastro de usuários:** gera a admissão automática.
   - Novo processo **Registrar admissão** · PL/SQL · Point: Processing · Sequence **15** (logo depois de "Salvar Dados Colaborador", antes de "Criar usuário APEX"):
     ```sql
     pkg_historico_carreira.registrar_admissao_automatica(:P14_ID_COLABORADOR);
     ```
     Além da admissão, isso publica o comunicado de boas-vindas para a equipe (se `CONFIG_CARREIRA.FL_COMUNICADO_AUTOMATICO` estiver ligado, o padrão).
   - Server-side Condition: Item `P14_ID_COLABORADOR` is not null. O processamento automático do form devolve a PK nesse item depois do insert.
   - Botão **Histórico de carreira** (condição: `P14_ID_COLABORADOR` is not null · Authorization `ADMIN_RH`) · Redirect página 13 com `P13_ID_COLABORADOR` = `&P14_ID_COLABORADOR.`
2. **Página 12 · Colaboradores:** quando a lista for criada, adicione uma coluna link "Histórico" para a página 13 com `P13_ID_COLABORADOR` = `#ID_COLABORADOR#`.
3. **Página 2 · Meu perfil:** botão **Meu histórico** para a página 13 sem parâmetro. A página abre no próprio usuário.
4. **Navegação:** entradas "Histórico de carreira" (página 13, sem parâmetro) e "Dashboard RH" (página 20, Authorization `ADMIN_RH`) no menu.

---

## 8. Checklist de teste no APEX

- [ ] Usuário sem o papel Admin RH não vê o botão "Nova movimentação", nem a região de lançamentos, nem as colunas de salário.
- [ ] Trocar o `P13_ID_COLABORADOR` na URL dá erro de checksum.
- [ ] Gestor abre o histórico de alguém da equipe (inclusive indireto), mas não o de um colega de outra equipe.
- [ ] Na modal, trocar o tipo para Mérito esconde e limpa cargo, departamento e gestor.
- [ ] Efetivar uma promoção muda o cargo no organograma (página 3).
- [ ] Estornar a promoção devolve o cargo anterior, e a timeline mostra o estorno.
- [ ] Cada abertura de lançamento com salário gera uma linha em `LOG_ACESSO_SALARIAL`.
- [ ] Erros do package aparecem como mensagem simples, sem "ORA-20005".
- [ ] A página 13 fica igual ao protótipo: resumo com 3 indicadores, faixa de cargos, abas com contagem, filtro de ano, posição atual e "Sobre este histórico".
- [ ] Trocar de aba ou de ano esconde os eventos e atualiza a contagem de cada ano.
- [ ] Um gestor não vê o "Reajuste por mérito" de quem é da equipe; o próprio colaborador vê.
- [ ] Efetivar uma promoção cria um comunicado na página de comunicados, e o evento mostra "Equipe de ... avisada automaticamente".
- [ ] "Exportar PDF" abre a impressão só com o conteúdo do histórico, sem menu e sem cabeçalho.
- [ ] "Solicitar correção" grava o pedido, e a página passa a mostrar "1 solicitação em análise pelo RH".

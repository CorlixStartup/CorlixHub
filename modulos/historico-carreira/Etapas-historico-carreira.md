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
| `c_pagina_solicitacao` / `c_item_solicitacao` | 22 / `P22_ID_COLABORADOR` | Botão "Solicitar correção" |
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

### 2.8 O que o protótipo mostra e ainda não tem dado

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
| `P18_DS_MOTIVO_ESTORNO` | Textarea | Source: nenhum · Label "Motivo do estorno" · Server-side Condition (Expression): `:P18_ST_REGISTRO = 'EFETIVADO' and :P18_FL_ESTORNO = 'N'` |

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

- Event: Change · Item: `P18_ID_TIPO_MOVIMENTACAO`
- Ação 1 · Set Value · SQL Statement:
  ```sql
  select cd_tipo
    from tipo_movimentacao
   where id_tipo_movimentacao = :P18_ID_TIPO_MOVIMENTACAO
     and id_empresa = :G_ID_EMPRESA
  ```
  Items to Submit: `P18_ID_TIPO_MOVIMENTACAO` · Affected Element: `P18_CD_TIPO`
- Ação 2 · Execute JavaScript Code: `carreira.ajustarCampos(true);` (bloco 3 do `.js`)

Com isso, o cargo novo só aparece em promoção, mudança de cargo, transferência e admissão; o departamento novo em transferência e admissão; o gestor novo também em mudança de gestão (onde é obrigatório); e o salário em promoção, mudança de cargo, mérito e admissão. Campos escondidos são limpos, e o package também descarta cargo, departamento e gestor nos tipos que não mexem na estrutura.

### 3.4 Botões

| Botão | Request | Condição (Server-side, Expression) | Observação |
|---|---|---|---|
| `CANCELAR` | | sempre | Ação: Defined by Dynamic Action > Cancel Dialog |
| `EXCLUIR` | `EXCLUIR` | `:P18_ST_REGISTRO = 'RASCUNHO' and :P18_ID_HISTORICO_CARREIRA is not null` | Confirmação: "Excluir este rascunho?" |
| `SALVAR_RASCUNHO` | `SALVAR_RASCUNHO` | `nvl(:P18_ST_REGISTRO, 'RASCUNHO') = 'RASCUNHO'` | |
| `EFETIVAR` (Hot) | `EFETIVAR` | `nvl(:P18_ST_REGISTRO, 'RASCUNHO') = 'RASCUNHO'` | Confirmação: "Depois de efetivado, o lançamento não pode ser alterado. Continuar?" |
| `ESTORNAR` (Danger) | `ESTORNAR` | `:P18_ST_REGISTRO = 'EFETIVADO' and :P18_FL_ESTORNO = 'N'` | Confirmação: "Estornar este lançamento?" |

Todos com Authorization Scheme `ADMIN_RH`.

### 3.5 Processos (Processing, nesta ordem)

Nenhum faz DML direto: todos chamam o package.

1. **Salvar movimentação** · PL/SQL · When Button Pressed: `SALVAR_RASCUNHO` **ou** `EFETIVAR` (use Server-side Condition *Request is contained in Value*: `SALVAR_RASCUNHO,EFETIVAR`)
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

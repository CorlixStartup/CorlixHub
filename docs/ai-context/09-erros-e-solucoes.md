# 09 · Erros já vistos e como evitá-los (SQL, PL/SQL e APEX)

> Referência de diagnóstico. Cada entrada traz o **sintoma** (a mensagem como aparece), a **causa**, a **correção** e a **prevenção**.
> Origem: instalação e integração do módulo de histórico de carreira (página 13), em 09/10/2026.
> Antes de escrever SQL ou PL/SQL, leia a [§5 (checklist)](#5-checklist-antes-de-entregar-sqlplsql). Antes de configurar uma página, leia a [§4](#4-apex-configuração-de-páginas).

## 1. Como ler uma mensagem de erro

### 1.1 Erros de compilação (`Error at line N`)
- O número da linha é contado **a partir do `create or replace`**, não do início do arquivo. Se o arquivo tem um cabeçalho de comentários, some essas linhas. Exemplo: o `04_pkg_historico_carreira.pkb` tem 4 linhas antes do `create`, então a linha 490 do erro é a linha 494 do arquivo.
- O APEX (SQL Commands e SQL Scripts) mostra só a primeira linha de cada erro. Para ver a lista completa:
  ```sql
  select line, position, text from user_errors where name = 'PKG_X' order by sequence
  ```
- Mensagens como `PL/SQL: SQL Statement ignored` e `Compilation unit analysis terminated` são **consequência** de outro erro. Procure o erro de verdade nas linhas vizinhas.

### 1.2 Erros em tempo de execução (página de erro do APEX)
Na seção *Technical Info*:
| Campo | O que diz |
|---|---|
| `component.type` / `component.name` | O componente que falhou: `APEX_APPLICATION_PAGE_PROCESS` (processo), `APEX_APPLICATION_AUTHORIZATION` (authorization scheme), `APEX_APPLICATION_PAGES` + "Error during rendering of region" (região) |
| `ora_sqlerrm` | O erro Oracle original |
| `error_backtrace` | A pilha. A **primeira linha `WKSP_CORLIXHUB.<objeto>`** é onde o erro aconteceu, com o número de linha contado como em 1.1 |
| `error_statement` | O código que o APEX executou (o processo ou a fonte da região) |

As linhas `APEX_260100.*` e `SYS.*` são internas do APEX. Ignore-as.

---

## 2. Instalação e compilação

### 2.1 `ORA-12704: character set mismatch` ao criar uma view
**Sintoma:** `create or replace view …` falha com ORA-12704, e o `comment on table` seguinte dá `ORA-00942: table or view does not exist`.

**Causa:** `unistr()` sempre devolve **NVARCHAR2**. Num `case`, `decode`, `coalesce` ou `union`, todos os ramos precisam ter o mesmo tipo. Misturar `unistr(...)` com texto `VARCHAR2` quebra a view. O ORA-00942 é só consequência: a view não foi criada.

**Correção:** envolva com `to_char`:
```sql
nvl(ca.nome, '?') || to_char(unistr(' \2192 ')) || nvl(cn.nome, '?')
```
**Prevenção:** em SQL (views e queries), use sempre `to_char(unistr(...))`. Em PL/SQL, atribuir a uma variável `varchar2` já converte sozinho.

### 2.2 `PLS-00201` + `PLS-00304`: body sem especificação
**Sintoma:**
```
PLS-00201: identifier 'PKG_HISTORICO_CARREIRA' must be declared
PLS-00304: cannot compile body of 'PKG_HISTORICO_CARREIRA' without its specification
```
**Causa:** o `.pkb` (body) foi executado sem que a spec (`.pks`) existisse no schema. Ou só o `.pkb` foi rodado, ou a spec falhou antes.

**Correção:** execute o `.pks` e depois o `.pkb`.

**Prevenção:**
- Instale pelo `instalar.sql` do módulo no SQLcl, que já segue a ordem certa.
- No APEX (SQL Workshop › SQL Scripts), `@@` não funciona. Envie e execute um arquivo por vez, **na ordem do `instalar.sql`**.
- Se a spec deu erro, corrija-a antes de rodar o body.

### 2.3 `PLS-00905: object … is invalid`
**Causa:** um package dependente (ex.: `pkg_historico_carreira_ui` → `pkg_historico_carreira`) foi compilado antes da dependência, ou a dependência ficou inválida.

**Correção:** `alter package pkg_x compile;` e depois `alter package pkg_x compile body;`. Confira com:
```sql
select object_type, object_name from user_objects where status = 'INVALID'
```

### 2.4 `PLS-00231: function 'X' may not be used in SQL`
**Sintoma:** vários blocos de
```
PLS-00231: function 'USUARIO_ATUAL' may not be used in SQL
PL/SQL: ORA-03066: invalid PL/SQL expression
PL/SQL: SQL Statement ignored
```
**Causa:** uma função **privada** (declarada só no body, sem estar na spec) foi chamada dentro de um comando SQL (`select … where`, `insert … values`, `update … set`). Quem executa esse comando é o motor SQL, e ele só enxerga funções de schema e funções **públicas** de package. O mesmo vale para funções locais declaradas dentro de uma procedure.

**Correção:** leia o valor numa variável local antes do SQL:
```sql
procedure efetivar_movimentacao (p_id in number) is
  l_usuario constant varchar2(255) := usuario_atual;  -- função privada não pode ser chamada dentro de SQL
begin
  update historico_carreira set usr_efetivacao = l_usuario where …;
```
**Prevenção:** em PL/SQL puro (`if`, atribuições) a função privada funciona normalmente. Dentro de SQL, use variável. Só coloque a função na spec se ela realmente fizer parte da API do package.

---

## 3. PL/SQL em tempo de execução (compila, mas falha ao rodar)

### 3.1 `ORA-02000: missing AS keyword` com `AT TIME ZONE`
**Sintoma:** a página falha com "Error during rendering of region", `ora_sqlerrm: ORA-02000: missing AS keyword`, e o backtrace aponta para `PKG_HISTORICO_CARREIRA` (`fn_data_local`, chamada por `fn_hoje`). O package compila sem erro.

**Causa:** em SQL dentro de PL/SQL, toda variável vira bind (`:B1`). O Oracle não aceita bind em `AT TIME ZONE`, então `cast(p_momento at time zone l_fuso as date)` só falha quando a linha executa. Tirar a conversão de dentro do `CAST` ou colocar parênteses **não resolve**.

**Correção** (aplicada em `fn_data_local`): passar o fuso como literal em SQL dinâmico, validando o valor:
```sql
if l_fuso is null or not regexp_like(l_fuso, '^[A-Za-z0-9_/+:-]{1,64}$') then
  l_fuso := c_fuso_padrao;
end if;
execute immediate
  'select cast(:momento at time zone ''' || l_fuso || ''' as date) from dual'
  into l_data
  using p_momento;
```
**Prevenção:**
- Nunca use variável PL/SQL depois de `AT TIME ZONE`.
- Sempre que concatenar um valor em SQL dinâmico, valide-o antes com `regexp_like` ou uma lista fixa. Isso impede injeção de SQL.
- Teste funções de data isoladas antes de usar na página: `select pkg_historico_carreira.fn_hoje(1) from dual`.

### 3.2 `ORA-01403: no data found` em `select … into`
**Sintoma:** página de erro com `component.type: APEX_APPLICATION_PAGE_PROCESS` e o `select … into` no `error_statement`.

**Causa:** um `select … into` sem tratamento de exceção não encontrou nenhuma linha. Na página 13, o processo "Colaborador padrão" procura o colaborador do usuário logado, e as contas da equipe (SARAHSILVA, EDUARDOMARINS, ALAIRTONROCHA) não têm cadastro em `COLABORADOR`.

**Correção:** trate `no_data_found` e `too_many_rows` com uma mensagem clara:
```sql
begin
  if :P13_ID_COLABORADOR is null then
    select id_colaborador
      into :P13_ID_COLABORADOR
      from colaborador
     where upper(trim(login_apex)) = upper(trim(:APP_USER))
       and id_empresa = :G_ID_EMPRESA;
  end if;
exception
  when no_data_found or too_many_rows then
    raise_application_error(-20012,
      'Sua conta não está vinculada a um colaborador desta empresa. Fale com o RH.');
end;
```
**Prevenção:** todo `select … into` em processo de página precisa de `exception`. Use códigos do módulo (-20001 a -20099) para que `fn_tratar_erro` mostre a mensagem sem "ORA-".

---

### 3.3 Carga inicial "com sucesso" que não cria nada
**Sintoma:** `06_carga_inicial.sql` termina sem erro no **SQL Workshop**, mas nenhum colaborador ganha a `ADMISSAO`. A conferência no fim do script lista todos.

**Causa:** o SQL Workshop roda dentro de uma sessão APEX (`sys_context('APEX$SESSION', 'APP_SESSION')` não é nulo). O package entende que está no app e exige `G_ID_EMPRESA`, que não existe nessa sessão: cada colaborador falha com "Sua sessão não está vinculada a uma empresa". O script captura o erro por colaborador e segue, e o resumo sai por `dbms_output`, que o SQL Scripts não mostra.

**Correção:** rode o script fora do APEX, no SQLcl ou no SQL Developer (desktop ou extensão do VS Code), conectado como `WKSP_CORLIXHUB`. O script é reexecutável.

No Autonomous o schema do workspace costuma não ter login; conectado como `ADMIN`, o script dá `ORA-00942: table or view "ADMIN"."COLABORADOR" does not exist`. Aponte a sessão para o schema antes: `alter session set current_schema = WKSP_CORLIXHUB;` e depois `@06_carga_inicial.sql`. Nesse caso `USR_EFETIVACAO` das admissões fica `ADMIN`.

**Prevenção:** scripts de carga e manutenção do módulo vão no SQLcl/SQL Developer. No SQL Workshop, só consultas.

## 4. APEX: configuração de páginas

### 4.1 "Access denied by Page security check"
**Sintoma:** `apex_error_code: ACCESS_DENIED_SIMPLE`, `component.type: APEX_APPLICATION_AUTHORIZATION`, `component.name: COLABORADOR`.

**Causas, da mais comum para a menos comum:**
1. **Resultado guardado na sessão.** Os esquemas estão com *Evaluation Point: Once per session*. Se o papel foi atribuído, ou o esquema foi criado ou alterado, depois do login, a sessão continua com o resultado antigo. → **Saia e entre de novo.** Um refresh da página não basta.
2. **O usuário não atende ao esquema.** O `COLABORADOR` exige o papel Admin RH **ou** um cadastro em `COLABORADOR` na empresa (`G_ID_EMPRESA`).
3. **O esquema foi criado com o tipo errado** (ex.: *Is In Role or Group* com o nome `COLABORADOR`, papel que não existe). O certo é *PL/SQL Function Returning Boolean*, com o código da etapa 1.2 do `Etapas-historico-carreira.md`.

**Diagnóstico:**
```sql
select role_name from apex_appl_acl_user_roles
 where application_id = 100 and user_name = 'LOGIN'
```
```sql
select id_colaborador, id_empresa from colaborador where upper(trim(login_apex)) = 'LOGIN'
```

### 4.2 Conta sem cadastro de colaborador: o módulo inteiro falha
Sem linha em `COLABORADOR`, o login não preenche `G_ID_EMPRESA`. Com isso, o package recusa tudo com `-20012`, e as queries filtradas por `:G_ID_EMPRESA` voltam vazias. Passar o ID do colaborador na URL **não resolve**.

**Para testar com acesso de RH:** cadastre um usuário pela **P14** com um cargo que dê Admin RH (empresa 1: cargo 202 "Gerente de Recursos Humanos" ou 204 "Analista de Recursos Humanos"). Depois registre a admissão no histórico, porque a P14 ainda não chama o módulo:
```sql
begin pkg_historico_carreira.registrar_admissao_automatica(<ID>, false); end;
```
Saia e entre com o usuário novo.

### 4.3 A correção no Builder "não pegou": processo duplicado
**Sintoma:** você alterou o código de um processo, mas o erro continua igual. No export aparecem dois processos com o mesmo nome (`colaborador-padrão` e `colaborador-padrão_1`).

**Causa:** em vez de editar o processo existente, foi criado um novo. O novo ficou sem *Point* (caiu em *Processing*, depois do submit) e nunca roda ao abrir a página. O antigo continua rodando em *Before Header*.

**Correção:** apague o processo novo e edite o código do original (*Rendering › Pre-Rendering › Before Header*).

**Prevenção:** depois de salvar, confira no export que existe **um** processo com aquele nome e que ele tem `point: beforeHeader`.

### 4.4 Dynamic Action de Refresh que não atualiza nada
**Sintoma:** a DA dispara, mas as regiões não recarregam.

**Causa:** em *Affected Elements*, a ação Refresh apontava para o **item** `P13_ID_COLABORADOR` (`selectionType: items`) em vez da **região**.

**Correção:** *Selection Type* = **Region**, e escolha a região. No export:
```
affectedElements {
    selectionType: region
    region: @historico_carreira
}
```
**Prevenção:** para o refresh funcionar, a região também precisa de *Page Items to Submit* com os itens que a fonte usa (ex.: `P13_ID_COLABORADOR`). Senão ela recarrega sem o valor e volta vazia.

### 4.5 Links e botões para páginas que ainda não existem
O guia monta a página 13 antes das páginas 18 e 19. O botão "Nova movimentação", o ícone de editar e o botão "Formações" dão erro até essas páginas existirem. Isso é esperado. Termine-os depois das etapas 3 e 4. Pelo mesmo motivo, as constantes `c_pagina_*` de `08_pkg_historico_carreira_ui.sql` só devem apontar para páginas que já existem com o item indicado (`c_pagina_organograma` = 3 com `P3_ID_FOCO` já funciona; `c_pagina_solicitacao` fica nula até a página 22).

**`ERR-1002 Unable to find item ID for item "P22_ID_COLABORADOR" in application "100"`:** aparece na página 13 quando o usuário abre o **próprio** histórico. O package monta o link "Solicitar correção" com `apex_page.get_url`, que precisa achar o item na página de destino para gerar o checksum. Enquanto a página 22 (§6 do guia) não existir, deixe `c_pagina_solicitacao := null` em `08_pkg_historico_carreira_ui.sql` e rode o arquivo de novo: o link some. Depois de criar a página 22 com o item `P22_ID_COLABORADOR`, volte para `22`. Vale para qualquer constante `c_item_*`: o item precisa existir na página indicada.

### 4.6 Sintaxe de valores em links
| Sintaxe | Significa |
|---|---|
| `#COLUNA#` | Valor da coluna **naquela linha** do relatório |
| `&ITEM.` | Valor de um item da página, igual para todas as linhas. O **ponto final é obrigatório** |
| `:ITEM` | Bind, só dentro de SQL e PL/SQL |

### 4.7 `ORA-20999: Wrong number of columns selected in the SQL query`
**Sintoma:** ao salvar um item no Builder (ex.: `P18_NM_CARGO_ANTERIOR`), aparece o erro com a query de uma coluna só (`select cg.nome from …`).

**Causa:** a query foi colada num atributo que espera **duas colunas** (valor exibido e valor de retorno): *List of Values › SQL Query*, ou um Display Only com *Based On: Display Value of List of Values*. Uma query de uma coluna só serve em *Default*, *Source* ou *Set Value*.

**Correção:** deixe *List of Values* vazio, coloque *Settings › Based On* = **Page Item Value** e cole a query em **Default › Type: SQL Query**. Se o lugar certo for mesmo uma LOV, devolva duas colunas: `select nome d, id_cargo r from …`.

**Prevenção:** antes de colar SQL, confira o nome do atributo. LOV = 2 colunas (`d`, `r`); Default/Source "SQL Query" = 1 coluna e 1 linha.

---

## 5. Checklist antes de entregar SQL/PL/SQL

- [ ] Nenhum `unistr()` em SQL sem `to_char` (2.1).
- [ ] Spec e body em arquivos separados, cada um terminando com `/`, e registrados nessa ordem no `instalar.sql` (2.2).
- [ ] Nenhuma função privada chamada dentro de `select`/`insert`/`update`/`delete`/`merge` (2.4).
- [ ] Nenhuma variável depois de `AT TIME ZONE`. Em SQL dinâmico, todo valor concatenado é validado (3.1).
- [ ] Todo `select … into` em processo ou função tem `exception when no_data_found` (3.2).
- [ ] Comandos SQL terminam com `;` e blocos PL/SQL com `/` sozinho na linha. Nunca `;` seguido de `/` num comando SQL simples, porque ele executa duas vezes.
- [ ] `set define off` no início do script, porque `&` em HTML e URLs vira variável de substituição.
- [ ] Depois de compilar: `user_errors` vazio para o objeto e nenhum objeto `INVALID` do módulo.
- [ ] Funções novas testadas isoladamente no SQL Commands antes de usar na página.
- [ ] No APEX: depois de mudar papéis ou authorization schemes, **sair e entrar de novo** antes de testar (4.1).

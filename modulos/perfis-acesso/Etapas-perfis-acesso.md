# Perfis de acesso · passo a passo no APEX

Este guia configura, à mão no App Builder do **APEX 26.1** e no SQL Workshop, o vínculo automático entre o cargo do colaborador e os papéis (roles) do APEX. Ao final, todo usuário criado na **página 14 (Cadastro de Usuários)** já sai com os papéis certos.

> Os nomes de menus e atributos seguem o Builder. Se algum rótulo estiver um pouco diferente na sua versão, o atributo equivalente fica na mesma seção do painel de propriedades.

## Como funciona

```
P14: RH escolhe Empresa → Departamento → Cargo e clica em "Salvar Usuario"
  ├─ seq. 10  Salvar Dados Colaborador   (insert em COLABORADOR)
  ├─ seq. 20  Criar usuário APEX         (APEX_UTIL.CREATE_USER)
  └─ seq. 30  Atribuir papéis do cargo   (PKG_PERFIS_ACESSO.ATRIBUIR_PAPEIS)  ← novo
                 ├─ todo usuário recebe   "Colaborador"
                 └─ os demais vêm da tabela CARGO_PAPEL (cargo × papel)
```

- O package **só adiciona** papéis. Ele nunca remove papéis que o usuário já tem (por exemplo, "Equipe do Corlix Hub" dado à mão).
- Os papéis ficam em cache na sessão: depois de qualquer mudança, o usuário precisa **sair e entrar de novo**.

## Checklist (faça nesta ordem)

| # | Etapa | Onde | Seção |
|---|---|---|---|
| 1 | Criar os papéis Colaborador, Gestor e Admin RH | Shared Components | §1 |
| 2 | Criar o esquema de autorização `ADMIN_RH` | Shared Components | §2 |
| 3 | Rodar os 3 scripts SQL | SQL Workshop | §3 |
| 4 | Ajustar a lista de Gestor da P14 | Page Designer · P14 | §4.1 |
| 5 | Criar o processo "Atribuir papéis do cargo" | Page Designer · P14 | §4.2 |
| 6 | Testar o cadastro | App em execução | §5 |
| 7 | Dar papéis aos usuários que já existiam | SQL Workshop ou Shared Components | §6 |
| 8 | Exportar a app e commitar | SQLcl / Git | §8 |

> **A ordem 1 → 3 importa.** Se o processo da P14 rodar antes de os papéis existirem na aplicação, o cadastro inteiro falha com o erro -20102.

---

## 1. Papéis (Shared Components > Application Access Control)

1. No App Builder, abra a aplicação **100 · CORLIXHUB**.
2. Clique em **Shared Components**. Na seção *Security*, clique em **Application Access Control**.
3. Na área **Roles**, clique em **Add Role** e crie os três papéis abaixo, um de cada vez. Clique em **Create Role** ao terminar cada um.

| Name | Static ID | Description |
|---|---|---|
| `Colaborador` | `colaborador` | Acesso básico. Dado a todo usuário cadastrado. |
| `Gestor` | `gestor` | Lidera equipe. Aparece na lista de gestores da P14. |
| `Admin RH` | `admin-rh` | Equipe de RH. Usado pela autorização ADMIN_RH. |

**Atenção ao Static ID:** digite exatamente como na tabela, em minúsculas e com hífen. O package e a tabela `CARGO_PAPEL` usam o Static ID, não o nome.

4. Confira que a lista de Roles ficou com **6 papéis**:

| Name | Static ID | Já existia? |
|---|---|---|
| Diretoria | `diretoria` | sim |
| Equipe do Corlix Hub | `equipe-do-corlix-hub` | sim |
| Publicador de Conteúdo | `publicador-de-conteúdo` (com acento) | sim |
| Colaborador | `colaborador` | **novo** |
| Gestor | `gestor` | **novo** |
| Admin RH | `admin-rh` | **novo** |

Se o Static ID de um papel antigo estiver diferente disso, me avise antes de rodar o SQL: o script `02` usa esses valores.

---

## 2. Esquema de autorização `ADMIN_RH` (Shared Components > Authorization Schemes)

1. Em **Shared Components**, seção *Security*, clique em **Authorization Schemes** e depois em **Create**.
2. Escolha **From Scratch** e clique em **Next**.
3. Preencha:
   - **Name:** `ADMIN_RH`. Use exatamente esse nome, em maiúsculas e com underline: o módulo de Histórico de Carreira consulta a autorização por esse nome.
   - **Scheme Type:** `Is In Role or Group`
   - **Type:** `Application Role`
   - **Name(s):** `Admin RH`
   - **Identify error message displayed when scheme violated:** `Acesso restrito ao RH.`
   - **Validate authorization scheme:** `Once per session`
4. Clique em **Create Authorization Scheme**.

Ainda não é preciso aplicar essa autorização em nenhuma página. Ela será usada pelas páginas do Histórico de Carreira.

---

## 3. Banco de dados (SQL Workshop)

Os scripts estão em `modulos/perfis-acesso/`. O SQL Workshop não entende o `@@` do `instalar.sql`, então rode **um arquivo por vez**, nesta ordem.

### 3.1 Rodar os scripts

Para cada arquivo:

1. **SQL Workshop > SQL Scripts > Upload**.
2. Escolha o arquivo e clique em **Upload**.
3. Na lista, clique no ícone **Run** do script e depois em **Run Now**.
4. Abra o resultado (**View Results**) e confira se não há erros.

| Ordem | Arquivo | O que faz | Resultado esperado |
|---|---|---|---|
| 1 | `01_ddl_cargo_papel.sql` | Cria a tabela `CARGO_PAPEL` | 0 erros (pode rodar de novo sem problema) |
| 2 | `02_seed_departamentos_cargos.sql` | Renomeia o departamento 20, corrige a numeração automática (departamento, cargo e colaborador), cria 30 cargos e vincula os papéis | Mensagem `Cargos criados: N \| vínculos cargo-papel criados: M` e a lista "só colaborador" |
| 3 | `03_pkg_perfis_acesso.sql` | Cria o package `PKG_PERFIS_ACESSO` | 0 erros |

Se preferir o SQLcl, os três rodam de uma vez:
```
cd modulos/perfis-acesso
sql <usuario>@<servico> @instalar.sql
```

> O script `02` aborta com `ORA-20100: Departamento X não encontrado na empresa 1` se algum dos departamentos 10, 20, 30, 40, 50 ou 60 não existir na empresa 1. Nesse caso nada é gravado. Confira a tabela `DEPARTAMENTO` antes de rodar de novo.

### 3.2 Conferir o resultado

Em **SQL Workshop > SQL Commands**, rode:

```sql
-- O package compilou?
select object_name, object_type, status
  from user_objects
 where object_name in ('PKG_PERFIS_ACESSO', 'CARGO_PAPEL');
-- Esperado: PACKAGE e PACKAGE BODY com status VALID, e a TABLE.

-- Departamento 20 renomeado?
select id_departamento, nome from departamento order by id_departamento;
-- Esperado: 20 = Diretoria de Recursos Humanos

-- Matriz cargo × papel
select d.nome as departamento,
       c.nome as cargo,
       listagg(p.cd_papel, ', ') within group (order by p.cd_papel) as papeis
  from cargo c
  join departamento d on d.id_departamento = c.id_departamento
  left join cargo_papel p on p.id_cargo = c.id_cargo
 where c.id_empresa = 1
 group by d.nome, c.nome
 order by d.nome, c.nome;
```

Cargos com `papeis` vazio recebem só "Colaborador". Se algum cargo antigo precisar de papel, veja a §7.

### 3.3 Matriz de papéis criada pelo script

| Departamento | Cargo | Papéis (além de Colaborador) |
|---|---|---|
| Presidência | Presidente (CEO) | gestor, diretoria, publicador |
| | Chefe de Gabinete | gestor |
| | Assistente Executivo(a) | — |
| Recursos Humanos | Diretor(a) de RH (CHRO) | gestor, diretoria, admin-rh, publicador |
| | Gerente de RH | gestor, admin-rh, publicador |
| | Coordenador(a) de Departamento Pessoal | gestor, admin-rh, publicador |
| | Analista de RH | admin-rh, publicador |
| | Analista de Departamento Pessoal | admin-rh, publicador |
| | Assistente de RH | — |
| Financeira e Administrativa | Diretor(a) Financeiro(a) (CFO) | gestor, diretoria, publicador |
| | Gerente Financeiro(a) | gestor |
| | Coordenador(a) Administrativo(a) | gestor |
| | Analista Financeiro(a) · Analista Contábil · Assistente Administrativo(a) | — |
| Comercial e Marketing | Diretor(a) Comercial (CCO) | gestor, diretoria, publicador |
| | Gerente Comercial · Gerente de Marketing | gestor |
| | Analista de Comunicação Interna | publicador |
| | Executivo(a) de Vendas · Analista de Marketing | — |
| Operações | Diretor(a) de Operações (COO) | gestor, diretoria, publicador |
| | Gerente de Operações · Supervisor(a) de Atendimento | gestor |
| | Analista de Operações · Assistente de Operações | — |
| Tecnologia e Informação | Diretor(a) de Tecnologia (CTO) | gestor, diretoria, publicador |
| | Gerente de TI · Tech Lead | gestor |
| | Desenvolvedor(a) · Analista de Suporte · Administrador(a) de Sistemas | — |

"publicador" = `publicador-de-conteúdo`. Cargos antigos chamados exatamente "Gestor" também recebem `gestor`.

> **Atenção: cargos que já existiam.** O script só reaproveita um cargo quando o nome é **idêntico** ao da matriz. Se os colaboradores estiverem em cargos com outros nomes (ex.: "Diretor Geral (CEO)" em vez de "Presidente (CEO)"), esses cargos ficam sem papel, e o script cria um cargo novo vazio. Depois de rodar o `02`, liste cargo × colaboradores × papéis e vincule os papéis aos cargos em uso (§7). Na empresa 1 isso já foi feito: veja [`Registro-implantacao.md`](./Registro-implantacao.md).

**Equipe do Corlix Hub** não está na matriz de propósito: ela dá acesso à administração do sistema (empresas, logs) e deve ser atribuída à mão, só para quem administra o Corlix Hub (§6.1).

---

## 4. Página 14 · Cadastro de Usuários (Page Designer)

Abra a aplicação 100, clique na **página 14** e entre no **Page Designer**.

### 4.1 Lista de Gestor (`P14_GESTOR`)

Hoje a lista só mostra quem tem um cargo chamado exatamente "Gestor" e mistura todas as empresas. Ela passa a mostrar os colaboradores **da empresa escolhida** cujo cargo tem o papel `gestor`.

1. Na árvore à esquerda (aba **Rendering**), clique no item **P14_GESTOR**.
2. No painel à direita, seção **List of Values**:
   - **Type:** `SQL Query` (já está assim)
   - **SQL Query:** apague o conteúdo e cole:
     ```sql
     SELECT c.NOME_COMPLETO d,
            c.ID_COLABORADOR r
     FROM COLABORADOR c
     WHERE c.ID_EMPRESA = :P14_EMPRESA
       AND EXISTS (
             SELECT 1
             FROM CARGO_PAPEL cp
             WHERE cp.ID_CARGO = c.ID_CARGO
               AND cp.CD_PAPEL = 'gestor'
           )
     ORDER BY c.NOME_COMPLETO;
     ```
3. Na seção **Cascading List of Values**:
   - **Parent Item(s):** `P14_EMPRESA`
   - **Items to Submit:** `P14_EMPRESA`
   - **Parent Required:** `On`
4. Salve (**Save**, no canto superior direito).

Com isso, ao trocar a empresa, a lista de gestores recarrega sozinha.

### 4.2 Processo "Atribuir papéis do cargo"

1. Clique na aba **Processing** (ícone de engrenagens, na coluna da esquerda).
2. Em **Processing**, já existem dois processos:
   - `Salvar Dados Colaborador` (seq. 10)
   - `Criar usuário APEX` (seq. 20)
3. Clique com o botão direito em **Processing** > **Create Process**.
4. No painel à direita, preencha:

   **Identification**
   - **Name:** `Atribuir papéis do cargo`
   - **Type:** `Execute Code`

   **Source**
   - **Location:** `Local Database`
   - **Language:** `PL/SQL`
   - **PL/SQL Code:**
     ```sql
     BEGIN
         PKG_PERFIS_ACESSO.ATRIBUIR_PAPEIS(
             p_login          => :P14_LOGIN,
             p_id_cargo       => :P14_CARGO,
             p_application_id => :APP_ID
         );
     END;
     ```

   **Execution**
   - **Sequence:** `30`. Precisa ser maior que a do `Criar usuário APEX` (20), porque o usuário tem que existir antes de receber papéis.
   - **Point:** `Processing`. Os outros dois estão em `After Submit`, que roda antes de `Processing`, então a ordem fica garantida.

   **Success Message**
   - deixe em branco (a mensagem "Colaborador cadastrado com sucesso!" já vem dos outros processos)

   **Error**
   - **Error Message:** `Não foi possível atribuir os papéis do cargo: #SQLERRM_TEXT#`. O `#SQLERRM_TEXT#` mostra o motivo (ex.: papel inexistente) sem o código ORA.

   **Server-side Condition**
   - **Type:** `Item is NOT NULL`
   - **Item:** `P14_LOGIN`

5. Confira a ordem final na aba Processing:
   ```
   10  Salvar Dados Colaborador
   20  Criar usuário APEX
   30  Atribuir papéis do cargo
   ```
6. Salve.

Os três processos rodam na mesma transação. Se a atribuição de papéis falhar, o cadastro do colaborador também é desfeito, então não fica colaborador sem papel.

### 4.3 (Recomendado) Login obrigatório

O `Criar usuário APEX` sempre precisa de login, mas o campo `P14_LOGIN` está como opcional. Para o erro aparecer no campo, e não como erro genérico:

1. Clique em **P14_LOGIN**.
2. **Validation > Value Required:** `On`.
3. **Appearance > Template:** `Required - Floating`.
4. Salve.

---

## 5. Testar

Faça os testes com um usuário que tenha acesso à P14 (papel Diretoria).

### 5.1 Cadastro de alguém do RH

1. Rode a aplicação e abra **Cadastro de Usuários**.
2. Preencha:
   - Login: `teste.rh`
   - E-mail: um e-mail ainda não usado (a coluna é única)
   - Senha e confirmação
   - Nome completo
   - Empresa: a empresa 1
   - Departamento: `Diretoria de Recursos Humanos`
   - Cargo: `Gerente de RH`
   - Gestor: a lista deve mostrar só colaboradores da empresa 1 com cargo de liderança
3. Clique em **Salvar Usuario** e confirme.
4. No Builder, vá em **Shared Components > Application Access Control** e procure `TESTE.RH` em **User Role Assignments**.
   - **Esperado:** Admin RH, Colaborador, Gestor, Publicador de Conteúdo.
5. Saia da aplicação e entre como `teste.rh`. O menu **Emitir Comunicado** deve aparecer (vem do papel Publicador de Conteúdo).

### 5.2 Cadastro de um cargo sem papel extra

Repita com Departamento `Diretoria de Operações` e Cargo `Analista de Operações`.
- **Esperado:** só **Colaborador**. Os menus de comunicado, empresas e cadastro de usuários não aparecem.

### 5.3 Pelo SQL

```sql
select user_name, role_static_id, role_name
  from apex_appl_acl_user_roles
 where application_id = 100
   and user_name in ('TESTE.RH')
 order by user_name, role_static_id;
```

Depois dos testes, apague os usuários de teste em **Administration > Manage Users and Groups** e os colaboradores correspondentes na tabela `COLABORADOR`.

---

## 6. Usuários que já existiam

O processo só age em cadastros novos. Quem já tinha conta precisa receber os papéis uma vez.

### 6.1 Um usuário por vez (Builder)

1. **Shared Components > Application Access Control**.
2. Em **User Role Assignments**, clique em **Add User Role Assignment**.
3. **User Name:** o login (ex.: `MARIA.SILVA`). Marque os papéis conforme o cargo dela (tabela da §3.3) e sempre **Colaborador**.
4. **Create Assignment**.

É assim também que se dá o papel **Equipe do Corlix Hub** para quem administra o sistema.

### 6.2 Todos de uma vez (SQLcl ou SQL Developer)

Dá a cada colaborador com login os papéis do cargo atual dele. Pode rodar mais de uma vez sem duplicar nada.

> **Não use o SQL Commands do APEX aqui.** O `apex_acl.add_user_role` precisa de uma sessão da aplicação 100. Sem ela, o resultado é `ORA-01403: no data found` em `WWV_FLOW_ACL_API`. E o SQL Commands bloqueia o `apex_session.create_session`, com `ORA-20987: Access to session state is disabled`. Para poucos usuários, use a §6.1.

1. Conecte no **SQLcl** ou no **SQL Developer** como `WKSP_CORLIXHUB` e execute:
   ```sql
   declare
     l_erro varchar2(4000);
   begin
     apex_session.create_session(p_app_id => 100, p_page_id => 1, p_username => '<seu usuário APEX>');
     begin
       for c in (
         select col.login_apex, col.id_cargo
           from colaborador col
          where col.login_apex is not null
            and exists (
                  select 1
                    from apex_workspace_apex_users u
                   where u.user_name = upper(trim(col.login_apex))
                )
       ) loop
         pkg_perfis_acesso.atribuir_papeis(c.login_apex, c.id_cargo, 100);
       end loop;
       commit;
     exception
       when others then
         l_erro := sqlerrm || chr(10) || dbms_utility.format_error_backtrace;
     end;
     apex_session.delete_session;
     if l_erro is not null then
       raise_application_error(-20000, l_erro);
     end if;
   end;
   /
   ```
2. Confira com a consulta da §5.3, sem o filtro de `user_name`.

Só entram colaboradores cujo `LOGIN_APEX` (formato `NomeSobrenome`) corresponde a uma conta APEX existente. Contas sem registro em `COLABORADOR`, como as da equipe do Corlix Hub, não são afetadas e recebem papéis pela §6.1.

---

## 7. Manutenção do dia a dia

| Quero… | Como |
|---|---|
| Dar um papel a um cargo | `insert into cargo_papel (id_cargo, cd_papel) values (<id do cargo>, 'gestor'); commit;` |
| Tirar um papel de um cargo | `delete from cargo_papel where id_cargo = <id> and cd_papel = 'gestor'; commit;` (não tira de quem já foi cadastrado; ajuste esses usuários à mão, §6.1) |
| Criar um cargo novo | Insira em `CARGO` (`id_empresa`, `id_departamento`, `nome`) e depois os papéis em `CARGO_PAPEL` |
| Criar um papel novo | Crie no Builder (§1) e use o **Static ID** dele em `CARGO_PAPEL` |
| Ver os papéis de um cargo | `select cd_papel from cargo_papel where id_cargo = <id>;` |
| Alguém mudou de cargo | Ajuste os papéis à mão (§6.1). O package não remove os papéis do cargo antigo. |

---

## 8. Exportar e versionar

O repositório já tem estas mudanças em APEXlang (`corlixhub/shared-components/acl-roles.apx`, `authorizations.apx` e `corlixhub/pages/p00014-cadastros-de-usuarios.apx`). Depois de fazer tudo no Builder:

1. Exporte a aplicação em APEXlang, como já é feito hoje, por cima da pasta `corlixhub/`.
2. Rode `git diff corlixhub/`. Se os nomes e Static IDs foram digitados como neste guia, a diferença deve ser pequena (identificadores internos e ordem de atributos).
3. Exporte também o `database/f100.sql`, para ele refletir os papéis novos.
4. Commit sugerido: `feat(perfis-acesso): atribuir papéis do APEX pelo cargo no cadastro de usuários`.

---

## 9. Problemas comuns

| Sintoma | Causa | Solução |
|---|---|---|
| `ORA-20102: O papel "x" não existe na aplicação 100` ao salvar na P14 | O papel não foi criado (§1) ou o Static ID foi digitado diferente | Crie o papel ou corrija o Static ID. Para conferir os IDs: `select role_static_id from apex_appl_acl_roles where application_id = 100;` |
| `ORA-20101: Informe o login do usuário…` | `PKG_PERFIS_ACESSO` chamado sem login | Na P14 não acontece por causa da condição `P14_LOGIN is not null`. Faça o login obrigatório (§4.3). |
| `ORA-04063` / `PLS-00201: PKG_PERFIS_ACESSO must be declared` | O script `03` não rodou ou deu erro | Rode o `03` de novo e confira `user_errors where name = 'PKG_PERFIS_ACESSO'` |
| Lista de Gestor vazia | Empresa não selecionada, ou nenhum colaborador da empresa tem cargo com papel `gestor` | Selecione a empresa; confira os vínculos com a consulta da §3.2 |
| O usuário recebeu o papel, mas o menu não aparece | Autorização avaliada uma vez por sessão | Sair e entrar de novo |
| `ORA-00001` ao inserir departamento, cargo ou colaborador novo (ex.: ao salvar na P14) | A numeração automática não foi ajustada | Rode o `02` de novo (os `alter table … start with limit value` estão no início dele) ou só o `alter table` da tabela afetada |
| Erro em `APEX_UTIL.CREATE_USER` | Login já existe no workspace ou senha fora da política | Use outro login ou ajuste a senha. O processo de papéis nem chega a rodar. |
| `ORA-01403` em `WWV_FLOW_ACL_API` ou `ORA-20987: Access to session state is disabled` | `apex_acl` chamado no SQL Commands, sem sessão da aplicação | Use o Builder (§6.1) ou rode no SQLcl/SQL Developer com `apex_session.create_session` (§6.2) |

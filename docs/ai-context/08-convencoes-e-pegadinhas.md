# 08 · Convenções, regras de trabalho e pegadinhas conhecidas

> Consolida as regras de trabalho e os problemas encontrados nos demais documentos (02–07). Detalhes e números de linha estão nos documentos de origem.
> Estado: 06/10/2026, branch `DEV`, com mudanças não commitadas.

## 1. Regras para uma IA trabalhando neste repositório

1. **Edite a app em `corlixhub/*.apx` (APEXlang).** Não edite `database/f100.sql` à mão: é um export gerado (12 MB) que serve só para consulta via `grep`.
2. **Sempre em pt-BR**: textos da UI, comentários, nomes de objetos (`colaborador`, `departamento`, `id_empresa`…), mensagens de commit.
3. **Nomes de objetos de banco** em `snake_case` minúsculo nos scripts. Prefixos: `pkg_` (packages), `vw_` (views), `trg_<tabela>_aud|log` (triggers), `fn_` (funções), `prc_` (procedures), `id_<entidade>` (PKs/FKs), `dt_` (datas), `fl_` (flags `S/N`), `ds_`/`nm_` quando aparecem.
4. **Módulos novos** seguem o padrão de `modulos/<nome>/`: scripts SQL numerados + `instalar.sql`, package `pkg_<nome>` com a lógica, `pkg_<nome>_ui` (ou procedure `render_*`) que devolve HTML para uma região *Dynamic Content*, `<nome>.css` e `<nome>.js`, e um `Etapas-<nome>.md` com o passo a passo no Builder. Veja o template em [`06-modulos.md`](./06-modulos.md).
5. **CSS**: tokens `--cx-*` em `corlix-tema.css`; ajustes e componentes em `custom.css`. **Atualize sempre o `.min.css` junto**, porque não existe script de minificação e os pares são mantidos à mão. Novos arquivos precisam ser registrados em `shared-components/static-files.apx` e, se forem globais, em `application.apx > css.fileUrls`. Prefixo de classes novas: `cx-` (tema), `org-`/`hc-`/`ch-`/`log-` (por módulo). Não há dark mode. A política visual é **sem sombras**. Veja [`04-tema-e-estilos.md`](./04-tema-e-estilos.md).
6. **Links entre páginas**: as páginas usam `argumentsMustHaveChecksum`, então gere URLs com `apex_page.get_url(...)` ou com o link builder. URLs `f?p=` montadas manualmente com parâmetros quebram.
7. **Multiempresa**: toda consulta nova a dados de negócio deve filtrar por `id_empresa` da empresa do usuário. Hoje quase nenhuma filtra (ver §3).
8. **Segurança**: quando criar ou alterar páginas administrativas, defina `authorizationScheme` **na página**, e não apenas na entrada do menu.
9. **Commits**: Conventional Commits (`feat(escopo): …`). Faça PR para `DEV`. Nunca versione `apex/`, `oracle_oradata/`, `ords_config/`, `.env`.
10. **Não invente**: o README e o código divergem em vários pontos (ver [`01`](./01-arquitetura-e-ambiente.md) §6). Confie no código e pergunte ao time sobre o que não estiver confirmado (ambiente atual, DDL das tabelas base, `log_pkg`).

## 2. Lacunas estruturais (objetos que faltam no repositório)

| Lacuna | Impacto |
|---|---|
| Dados do banco (empresas, cargos, colaboradores) | Só `DEPARTAMENTO` tem export (`database/dados/departamento.xlsx`). `database/corlix-hub.sql` é só o DDL (snapshot com blocos duplicados, não roda de ponta a ponta) e `f100.sql` é só a app. Para contagens e listas, consulte o banco (ver `05` §3.2). |
| Schema real com furos | `CARGO.ID_DEPARTAMENTO` sem FK; 8 FKs para `COLABORADOR` desabilitadas; códigos -20010..-20012 repetidos entre `PKG_EQUIPE_CANAL` e `PKG_HISTORICO_CARREIRA`; `07_testes.sql` falha no INSERT de `EMPRESA` (ver `05` §3–4A). |
| Função `ch_get_canal_direto` (Chat) | Usada na p4, sem fonte. |
| `docker-compose.yml` e `.env.example` | Deletados no working tree. `scripts/setup.*` dependem deles. O CI ignora a validação do compose quando o arquivo não existe. |
| Supporting objects | Estão vazios: o export da app não instala nada do schema. |
| Itens e authorizations exigidos pelos módulos (`G_ID_EMPRESA`, `ID_COLABORADOR`, authorizations PL/SQL `GESTOR` e `COLABORADOR`, processo `DOWNLOAD_FOTO`, páginas 18–23) | Os módulos de organograma e de histórico de carreira ainda não estão integrados ao app. |

## 3. Pegadinhas por área

### Segurança / multi-tenant
- **Nenhuma página tem authorization própria**: as 3 authorizations (`administration-rights`, `publicador-de-conteudo`, `somente-diretoria`) só escondem entradas do menu. Pela URL, qualquer usuário logado abre p7 (logs), p14 (cria usuários APEX via `apex_util.create_user`), p15/p16 (empresas) e p17 (emitir comunicado).
- As queries de comunicados, aniversariantes, chat, organograma, LOVs e equipes **não filtram por `id_empresa`**.
- Os app processes (4, `BEFORE_HEADER`, sem condição) rodam em todas as páginas, inclusive no login. Eles ligam o usuário ao colaborador por `COLABORADOR.login_apex = :APP_USER`; algumas comparações usam `UPPER` e outras não.

### Páginas
- **Placeholders** (só breadcrumb): p2 Meu perfil, p3 Organograma, p5 Notificações, p6 Configurações, p11 Comunicados, p12 Colaboradores, p13 Histórico de carreira. A p8 `NOTIFICAÇÕES` está vazia e duplica a p5.
- **p4 Chat**:
  - A região de mensagens tem a condição de servidor `P4_CANAL_ID is not null`, então ela não existe no DOM ao carregar e o refresh da DA não funciona.
  - Em `contatos` aparece `templateOptions: "[object Object]"`, um valor corrompido (linha ~330).
  - A coluna `CAB_DEPT` exige `administration-rights`.
  - O envio de mensagens ainda não foi implementado.
- **p17 Comunicado** (modal wizard):
  - O default é `plsqlExpression: SYSDATE;`, com um `;` a mais.
  - Não há processo *Close Dialog*.
  - A lista do wizard aponta para p18/p19, que não existem.
  - Todos os itens estão com `sequence: 10`.
- **p16 Cadastro de empresa**:
  - Os campos de endereço preenchidos pelo ViaCEP ficam desabilitados, e item desabilitado não é submetido.
  - Os `maxLength` de CEP, telefone e número são curtos demais para valores com máscara.
  - O logo usa `appTempFiles`.
- **p1 Home**:
  - Os links rápidos Holerite/Ponto/Suporte TI levam às páginas 5/6/7.
  - Os botões Chat/E-mail do gestor têm `href="#"`.
  - Em `columnCssClasses` há um `.` sobrando.
  - A coluna `CLASSE_DEPTO` não é usada.
- **p0 Global**: a busca global do cabeçalho não tem comportamento. Os links usam o caminho fixo `r/corlixhub/...`.

### Arquivos e tema
- As fotos são montadas como `#APP_FILES#fotos/<foto_url>` (app process e Home), mas a pasta real é `static-files/Fotos Colaboradores/` (`nome_sobrenome.jpg`, ~291 fotos fictícias). O fallback é `default-user.jpeg`.
- `custom.css` tem regras globais (`.a-CardView-*` com sombra e raio 14px, `.ui-dialog-titlebar`) que contrariam a política "sem sombra" do tema.
- `organograma.css` e `historico-carreira.css` ainda não estão em `static-files/`.
- Static IDs e aliases com acento (`publicador-de-conteúdo`, `histórico-de-carreira`, `NOTIFICAÇÕES`) são frágeis em URLs e scripts.

### Módulos
- O guia do organograma usa a página 10 (`P10_ID_FOCO`), mas a página real é a **3**.
- `c_pagina_perfil = 20` do organograma conflita com o Dashboard RH (página 20) planejado pelo histórico de carreira.
- `vw_org_colaborador` não filtra por empresa, e o drawer de detalhes não verifica permissão.
- `G_ID_EMPRESA` só é preenchido depois de um novo login. Sem esse item, toda chamada a `pkg_historico_carreira` dentro de uma sessão APEX falha com `-20012`.
- A spec de `pkg_historico_carreira` diz que a p14 chama `registrar_admissao_automatica`, mas a p14 não faz essa chamada.
- `COMUNICADO.TITULO` aceita até 200 caracteres no formulário (p17), mas o package corta em 100.
- O README do módulo de carreira fala em "nove códigos padrão" de movimentação, mas o seed cria 11.
- Perfis de acesso: os papéis vêm de `CARGO_PAPEL`, mas os colaboradores da empresa 1 estão em cargos antigos (101–604) vinculados à mão. Os cargos 605–633 do seed estão vazios. Antes de mexer em cargos, leia `modulos/perfis-acesso/Registro-implantacao.md`.
- `apex_acl` (atribuir papéis) não funciona no SQL Commands do APEX: sem sessão da app dá `ORA-01403`, e `apex_session.create_session` é bloqueado (`ORA-20987`). Use o Builder, a P14 ou o SQLcl/SQL Developer.
- SQL Commands: um comando por vez (sem `;` final, sem `commit;` junto), mostra só 10 linhas por padrão (campo **Rows**) e não mistura `unistr()` (NVARCHAR2) com VARCHAR2 em `union` sem `to_char`.
- As contas SARAHSILVA, EDUARDOMARINS e ALAIRTONROCHA são da equipe e não têm colaborador: "SEM VINCULO" na Home é esperado para elas.

### SQL e PL/SQL
Os erros já vistos (ORA-12704, PLS-00201/00304, PLS-00231, ORA-02000, ORA-01403, Access Denied etc.), com causa, correção e prevenção, estão em [09 · Erros e soluções](./09-erros-e-solucoes.md). Consulte o checklist da §5 desse documento antes de entregar SQL ou PL/SQL.

Regras gerais para scripts PL/SQL:
- Todo bloco `create or replace package|package body|procedure|function|trigger|type` e todo bloco anônimo `begin … end;` termina com `/` sozinho na linha seguinte. Sem a `/`, o SQLcl não executa o bloco e o próximo comando é anexado a ele.
- Comandos SQL simples (`create view`, `comment`, `insert`) terminam com `;`, sem `/`. Um `;` seguido de `/` executa o comando duas vezes.
- Spec e body ficam em arquivos separados (`.pks` e `.pkb`), cada um com sua `/`, e são instalados nessa ordem.
- Depois de compilar, confira com `show errors package body <nome>` (SQLcl) ou com `select * from user_errors where name = '<NOME>'`. O APEX mostra só a primeira linha do erro.
- `set define off` no início do script: sem ele, `&` em strings (HTML, URLs) vira variável de substituição.
- Ao ler `Error at line N`, conte as linhas **a partir do início do comando** (`create or replace …`), não do arquivo.

### Configuração
- O idioma primário da app é `en`, com máscaras de data `DS`. Para pt-BR, formate explicitamente com `to_char(..., 'dd/mm/yyyy')`. A LOV `BOOLEAN` mostra "Yes/No".
- `deployments/default.json` está com `debugging: true`.
- O último commit (`feature: …`) não segue o padrão do hook `commit-msg`.

## 4. Checklist rápido antes de entregar uma mudança
- [ ] Editei o `.apx` correto (e o `.min.css` junto com o `.css`, quando aplicável)?
- [ ] Os novos estáticos estão registrados em `static-files.apx`?
- [ ] As queries filtram por empresa? A página tem authorization?
- [ ] Os links foram gerados com checksum (`apex_page.get_url`)?
- [ ] Os textos estão em pt-BR e as datas formatadas explicitamente?
- [ ] O SQL novo está num script numerado e idempotente (`create table if not exists`, `create or replace`) e foi adicionado ao `instalar.sql` do módulo?
- [ ] O SQL/PL/SQL novo passa no checklist da §5 do [09 · Erros e soluções](./09-erros-e-solucoes.md)?
- [ ] A documentação em `docs/ai-context/` foi atualizada se a mudança altera páginas, schema, tema ou módulos?

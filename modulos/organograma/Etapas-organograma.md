Vou adaptar o módulo ao novo design: navegação por níveis, com a pessoa em foco, os subordinados diretos e o caminho na hierarquia. Uma mudança importante: esse design não precisa mais da OrgChart JS. Ele fica 100% nativo no APEX, usando uma região Dynamic Content renderizada por PL/SQL. Assim some a dependência externa e a questão da licença.

Os três arquivos estão prontos. No exemplo uso a página **10**. Se o número for outro, troque `P10_` nos nomes dos itens.

## O que remover da versão anterior

- As URLs da OrgChart JS nos JavaScript File URLs da página
- A região `painel-detalhes`, a Dynamic Action de Page Load e os processos `GET_ORGANOGRAMA` e `GET_DETALHES_SETOR`
- A função `fn_organograma_json`, que não é mais usada
- Pode manter o `DOWNLOAD_FOTO`, que continua servindo as fotos em BLOB
- A tabela `departamento_metrica` e a coluna `id_lider` saíram deste design. Pode mantê-las para uso futuro.

## Montagem no APEX

1. **Banco:** rode o `organograma.sql`. Ele cria a view `vw_org_colaborador` (só contas ativas) e o package `pkg_organograma`.
2. **Itens da página:**
   - `P10_ID_FOCO`: Hidden, com *Value Protected = No*, porque o JS altera o valor.
   - `P10_BUSCA`: Popup LOV com placeholder "Buscar pessoa no organograma" e label oculto. Coloque na região de título, alinhado à direita. Use esta query:
     ```sql
     select nome_completo || ' — ' || cargo d, id_colaborador r
       from vw_org_colaborador
      order by nome_completo
     ```
3. **Região de título:** use o template de título do Redwood, com "Organograma" e a descrição "Estrutura da Corlix a partir das relações de gestão."
4. **Região principal:**
   - Tipo: **Dynamic Content**
   - Static ID: `organograma`
   - Template: *Blank with Attributes*
   - Page Items to Submit: `P10_ID_FOCO`
   - Source:
     ```sql
     return pkg_organograma.render(
              to_number(:P10_ID_FOCO default null on conversion error),
              'Corlix');
     ```
5. **CSS:** suba o `organograma.css` como Static Application File e referencie com `#APP_FILES#organograma.css`. Também pode colar o conteúdo no CSS Inline da página.
6. **JS:** o `organograma.js` está dividido em três blocos comentados. Cada um vai num lugar: *Function and Global Variable Declaration*, *Execute when Page Loads* e uma DA de Change no `P10_BUSCA`.
7. **Ajustes no package:** as constantes `c_pagina_perfil` e `c_pagina_chat` (20 e 30) e os itens de destino são placeholders. Aponte para as páginas reais de perfil e do chat do módulo de Comunicação Interna.

## Como funciona

- **Pessoa inicial:** sem foco definido, abre no topo da hierarquia. Dá para abrir direto numa pessoa pela URL com `P10_ID_FOCO:<id>`.
- **Navegação:** "Ver equipe", o nome no card e os links do caminho trocam o foco e atualizam só a região, sem recarregar a página.
- **Contagens:** o resumo mostra os subordinados diretos e o total de pessoas abaixo na estrutura.
- **Avatar:** usa a foto se houver (`FOTO_URL` ou BLOB). Sem foto, mostra as iniciais, como no design.
- **Prévia da equipe:** mostra até 3 avatares e nomes. Acima disso aparece "+N" e "e mais N".
- **Botão Conversar:** não aparece quando a pessoa em foco é o próprio usuário logado.

## Limitações conhecidas

- **Mais de 2 subordinados:** os cards quebram em linhas de 2, e os conectores ligam só a primeira linha.
- **Gestor inativo:** se um gestor ficar inativo, quem se reporta a ele some da navegação até ser realocado. Vale tratar isso no cadastro de colaboradores.
- **Fotos em BLOB:** o `DOWNLOAD_FOTO` precisa de um Application Item `ID_COLABORADOR`.

---

Vou adicionar o drawer de detalhes da pessoa e ajustar o organograma às mudanças do novo design. Agora, clicar no card abre os detalhes, e "Ver equipe" continua descendo um nível.

Os três arquivos foram atualizados e substituem a versão anterior. O drawer de detalhes já está pronto.

## O que mudou no organograma

- **Clique no card:** abre os detalhes da pessoa. O card inteiro é clicável, e "Ver equipe" continua descendo um nível.
- **Ver perfil:** o botão do card em foco agora abre o drawer. O link para a página de perfil passou para o rodapé do drawer, em "Ver perfil completo".
- **Texto de ajuda:** atualizado para o novo texto do design.
- **Nome da empresa:** virou a constante `c_nome_empresa` no package. A chamada da região fica só `pkg_organograma.render(...)`.

## O drawer

O drawer usa o elemento `<dialog>` nativo, criado pelo próprio JS. Por isso você ganha sem código extra o fundo escurecido, o fechamento com Esc ou clique fora e o foco preso dentro dele. Não precisa criar região nova para ele.

O conteúdo segue o design:

- **Cabeçalho:** avatar, nome, cargo e departamento, e o botão de fechar.
- **Contato:** e-mail corporativo, clicável como `mailto`, e um botão de copiar que mostra um ✓ por 2 segundos.
- **Na estrutura:**
  - "Reporta-se a" mostra o gestor, ou "Topo da hierarquia".
  - "Equipe direta" lista até 8 pessoas; acima disso aparece "e mais N".
  - Clicar no gestor ou em alguém da equipe troca o conteúdo do drawer sem fechá-lo.
  - "Ver equipe no organograma" fecha o drawer e navega para aquele nível.
- **Sobre:**
  - Departamento e empresa.
  - "Na Corlix desde", calculado a partir de `DATA_ADMISSAO`, por exemplo "fevereiro de 2026 · 7 meses".
  - Aniversário com dia e mês apenas, sem o ano.
- **Rodapé:** "Conversar" (oculto quando a pessoa é o próprio usuário) e "Ver perfil completo".

## Passos no APEX além dos anteriores

1. **Banco:** rode de novo o `organograma.sql`. A view ganhou `email`, `data_admissao` e `data_de_nascimento`.
2. **Processo do drawer:** crie um processo na página 10 com o tipo *Execute Code*, o ponto de execução *Ajax Callback* e o nome **`ORG_DETALHES`**:
   ```sql
   apex_util.prn(
     p_clob   => pkg_organograma.render_detalhes(
                   to_number(apex_application.g_x01 default null on conversion error)),
     p_escape => false);
   ```
3. **Região do organograma:** simplifique o Source para:
   ```sql
   return pkg_organograma.render(
            to_number(:P10_ID_FOCO default null on conversion error));
   ```
4. **CSS e JS:** substitua pelo conteúdo novo. A divisão do JS nos três blocos é a mesma de antes.

A nota de privacidade do design afirma que só os dados visíveis a todos aparecem. Hoje o drawer mostra e-mail, data de admissão e aniversário para qualquer usuário logado. Se algum cliente não quiser expor o aniversário, o mais simples é uma flag de visibilidade no cadastro do colaborador; o drawer passa a respeitá-la com um ajuste pequeno.
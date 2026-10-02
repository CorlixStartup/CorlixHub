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
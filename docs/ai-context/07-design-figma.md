# 07 · Design (Figma) — telas-alvo do redesign CorlixHub

> Fonte: PNGs em `figma/` (28 arquivos, 27 telas distintas) e `modulos/organograma/` (2 PNGs de redesign).
> Objetivo deste documento: permitir que uma IA implemente cada tela no Oracle APEX 26.1 (Universal Theme, estilo Redwood Light) **sem ver a imagem**.
> Os dados exibidos nas telas (Sarah Silva, Rafael Nunes, Ana Beatriz Souza, Fernanda Lima etc.) são dados de exemplo/mock.
> O CSS/tokens são detalhados em outro documento; aqui há só um resumo do Design System.

---

## 1. Tabela-resumo

| # | Arquivo (figma/) | Tela | Página APEX correspondente | Prioridade aparente |
|---|---|---|---|---|
| 1 | `Design System · Redwood Light (CorlixHub).png` | Componentes, estados e estrutura da aplicação | Global (p00000 + tema / `corlix-tema.css`) | **Alta** (base de tudo) |
| 2 | `Início.png` | Início (home) | p00001-home | **Alta** |
| 3 | `Novo comunicado (diálogo).png` | Diálogo "Novo comunicado" | p00017-comunicado (modal; hoje é *wizard-modal*) | **Alta** |
| 4 | `Comunicados.png` | Lista de comunicados com filtros | p00011-comunicados-oficiais | **Alta** |
| 5 | `Colaboradores · visão de administração.png` | Lista de colaboradores (admin) | p00012-colaboradores | **Alta** |
| 6 | `Novo colaborador.png` | Formulário de criação | p00014-cadastros-de-usuarios | **Alta** |
| 7 | `Editar colaborador.png` | Formulário de edição | p00014-cadastros-de-usuarios (modo edição) | **Alta** |
| 8 | `Empresas.png` | Lista de empresas | p00015-empresas-cadastradas (+ p00016 modal) | Média |
| 9 | `Organograma.png` | Organograma por níveis | p00003-organograma | **Alta** |
| 10 | `modulos/organograma/Organograma — redesign (navegação por níveis).png` | Organograma por níveis (variante com texto de ajuda) | p00003-organograma | **Alta** |
| 11 | `modulos/organograma/Organograma · detalhes da pessoa (Drawer) — redesign.png` | Drawer de detalhes da pessoa | p00003 + nova página modal (drawer) — não implementada | **Alta** |
| 12 | `Meu perfil (com trajetória).png` | Meu perfil · aba Trajetória | p00002-meu-perfil | **Alta** |
| 13 | `Meu perfil · aba Dados pessoais.png` | Meu perfil · aba Dados pessoais | p00002-meu-perfil | **Alta** |
| 14 | `Meu perfil · foto de perfil (Drawer).png` | Drawer "Foto de perfil" | não implementada (nova modal drawer) | Média |
| 15 | `Histórico de carreira — nova página.png` | Histórico de carreira (linha do tempo) | p00013-histórico-de-carreira (+ `modulos/historico-carreira/`) | **Alta** |
| 16 | `Configurações (equipe de produto).png` | Configurações | p00006-configuracoes | Média |
| 17 | `Monitor de logs.png` | Monitor de logs | p00007-monitor-logs | Média |
| 18 | `Monitor de logs · detalhe em Drawer.png` | Drawer "Detalhe do registro #N" | não implementada (nova modal drawer) | Média |
| 19 | `Busca (resultados).png` | Resultados da busca global | não implementada (p00000 tem só "Barra de Busca") | Média |
| 20 | `Minha equipe (gestores).png` | Minha equipe (visão do gestor) | não implementada (≠ p00026 Central de equipes, que é admin) | Média |
| 21 | `Minhas aprovações (Unified Task List).png` | Minhas aprovações | não implementada | Baixa/Média (depende de PDI) |
| 22 | `PDI · aprovação pela gestão (detalhe da tarefa).png` | Detalhe da tarefa de aprovação de PDI | não implementada | Baixa/Média |
| 23 | `PDI · aprovação pela gestão (detalhe da tarefa)(1).png` | **Duplicata exata** do item 22 (mesmo MD5 `db9ba902…`) | — | — (pode ser apagado) |
| 24 | `Plano de desenvolvimento (PDI).png` | Plano de desenvolvimento | não implementada | Baixa/Média |
| 25 | `PDI · novo objetivo (Drawer).png` | Drawer "Novo objetivo" | não implementada | Baixa/Média |
| 26 | `Avaliações · avaliação de pares.png` | Avaliação 360 (fluxo de pares) | não implementada | Média |
| 27 | `Resultados 360.png` | Resultados 360 | não implementada | Média |
| 28 | `Feedbacks.png` | Feedbacks · aba Recebidos | não implementada | Baixa |
| 29 | `Feedbacks · aba Enviados.png` | Feedbacks · aba Enviados | não implementada | Baixa |
| 30 | `Feedbacks · dar feedback (Drawer).png` | Drawer "Dar feedback" | não implementada | Baixa |

Páginas APEX existentes **sem tela no Figma**: p00004-chat, p00005/p00008-notificações, p00026-central-de-equipes, p00027-nova-equipe, p09999-login. Devem apenas herdar o tema/estrutura do Design System.

Prioridade: "Alta" = página já existe e o redesign é visual/estrutural; "Média" = página nova simples ou admin; "Baixa/Média" = depende de módulo inteiro sem backend (seção 5). Na tela de Configurações os toggles "Plano de desenvolvimento (PDI)", "Feedbacks", "Exportação em PDF", "Notificações" e "Links rápidos" aparecem **Inativos** e "Busca na intranet" e "Avaliações 360" **Ativos** — isso sugere a ordem pretendida de entrega.

---

## 2. Estrutura comum (todas as telas)

### 2.1 Cabeçalho (Navigation Bar)
- Esquerda: botão hambúrguer (colapsa o menu lateral) + logotipo texto **"CorlixHub"** (negrito, preto).
- Centro-esquerda: campo de busca global com ícone de lupa e placeholder **"Buscar na intranet..."** (fundo cinza claro, borda sutil; foco = borda azul petróleo). Ao enviar → página "Busca (resultados)".
- Direita: ícone sino (notificações), divisor vertical, avatar circular com iniciais (ex.: "SS", fundo azul-claro, texto azul petróleo), nome do usuário ("Sarah Silva") e chevron ▾ que abre o **menu do usuário**.
- Menu do usuário (aberto): cabeçalho com nome (negrito) e linha "sarahsilva · sem empresa vinculada" (login · situação do vínculo); itens **Meu perfil**, **Preferências** (ícone engrenagem); separador; **Sair**.
- APEX: Navigation Bar List com entrada de usuário (`&APP_USER.`) e sublista; busca = item de página global (p00000) com submit para a página de busca (ou Search Region / `apex.navigation.redirect`).

### 2.2 Menu lateral (Navigation Menu, side, expandido)
Ordem exata (completa, para perfil administrador + gestor):
1. **Início** (ícone casa)
2. **Comunicados** (megafone)
3. **Chat** (balões)
4. **Pessoas** (ícone pessoas, grupo expansível)
   - Colaboradores
   - Organograma
   - Minha equipe *(só gestores)*
   - Minhas aprovações *(só gestores; badge numérico azul petróleo, ex.: "2")*
5. **Minha carreira** (maleta, grupo)
   - Meu perfil
   - Histórico de carreira *(aparece na tela de Histórico)*
   - Avaliações
   - Resultados 360
   - Plano de desenvolvimento
   - Feedbacks
6. **Administração** (escudo, grupo — só com Authorization Scheme de admin)
   - Empresas
   - Central de equipes
   - Monitor de logs
   - Configurações

Item ativo: fundo cinza (#ecebe8 aprox.), barra indicadora vertical azul petróleo à esquerda e texto em negrito. Hover: fundo cinza mais claro. Subitens sem ícone, indentados.
Decisões registradas no Design System: "Emitir comunicado" deixa de ser item de menu (vira botão "Novo comunicado"); "Sair" sai do rodapé do menu e vai para o menu do usuário; o rótulo "SEM VÍNCULO" sai do cabeçalho (estado aparece no menu do usuário e no card Meu gestor); ícones distintos para Comunicados (megafone) × Chat (balões) e Organograma (hierarquia) × Histórico (relógio); a engrenagem vira "Preferências" no menu do usuário.

### 2.3 Cabeçalho de página
Faixa branca abaixo do header com: breadcrumb opcional (link azul petróleo › item atual cinza), **título H1 grande** (negrito, ~32px), subtítulo cinza de uma linha e, à direita, a ação primária (botão escuro "+ Novo …") ou secundárias (botão cinza "Exportar", "Atualizar"). Corpo da página em fundo cinza-quente (#f1efed aprox.) com cards brancos, borda 1px e raio ~8px.
- APEX: região "Title Bar"/Hero no Breadcrumb Bar position, ou Static Content com template "Blank with Attributes" + classes; botões na posição `NEXT`/`EDIT` do breadcrumb.

### 2.4 Padrões recorrentes
- **Avatar de iniciais**: círculo azul-claro, iniciais azul petróleo em negrito. Usado em listas, cards e drawers.
- **Badge de status** (pílula com bolinha + texto): verde = Ativa/Concluída/Aprovado; cinza = Inativa/Não iniciado; vermelho = Erro/Atrasada; laranja/âmbar = Aviso/Aguardando aprovação; azul = Informação/Em andamento/Novo/Atual.
- **Etiqueta neutra** (retângulo cinza com borda): departamento ("Para: Operações"), categoria ("Institucional"), competência ("Trabalho em equipe"), tipo ("PDI", "Promoção").
- **Linha de visibilidade**: ícone cadeado + texto cinza pequeno ("Só você", "Visível só para você e sua linha de gestão").
- **Alertas** inline: info (azul-claro, ícone ⓘ), aviso (âmbar), sucesso (verde), erro (vermelho) — título em negrito + frase com próxima ação.
- **Drawer**: painel à direita (~35% da largura), título no topo + ×, corpo rolável, rodapé fixo cinza-claro com "Cancelar" (secundário) + ação primária escura. Fundo da página escurecido.
- **Rodapé de formulário fixo**: texto à esquerda ("Todos os campos são obrigatórios.") e botões à direita.
- **Paginação**: texto "1 – 8 de 8" alinhado à direita abaixo da tabela.

---

## 3. Design System (resumo)

Arquivo: `Design System · Redwood Light (CorlixHub).png` — título "CorlixHub — componentes e estados (base Redwood Light)". "Os tokens aproximam o Oracle Redwood Light; no APEX, use os componentes nativos, Template Options e Theme Roller correspondentes (a fonte real do tema é a Oracle Sans)."

- **Paleta**: neutros quentes (fundo da página cinza-areia, cards brancos, bordas cinza claras); **primária = quase-preto** (#2b2826 aprox.) para botões de ação principal; **acento azul petróleo** (#0f6b8f / #00688c aprox.) para links, foco, item ativo, avatar e barra de progresso (a barra usa azul mais vivo #2a72d4 sobre trilho azul-claro); status: verde (sucesso), vermelho (erro), âmbar (aviso), azul (informação). Gráfico 360: azul (Autoavaliação), laranja (Gestor), verde (Pares).
- **Tipografia**: sans-serif geométrica (Oracle Sans no APEX); H1 ~32px bold; títulos de card ~18–20px semibold; corpo 14–16px; legendas/ajuda 12–13px cinza.
- **Botões**: Primária (escuro, "Salvar") = botão **Hot**; Secundária (cinza, "Cancelar") = botão padrão; Terciária ("Ver todos →", link azul) = Template Option *Style › Remove UI Decoration*; Somente ícone (sino); estados Hover (mais escuro), Foco (teclado: anel azul), Desabilitado (cinza claro), Carregando ("Salvando…" com spinner). Regra: "Uma única ação primária por contexto".
- **Campos**: rótulo interno flutuante (template **"Required - Floating"** nos obrigatórios, asterisco vermelho), estados Vazio, Preenchido, Foco (borda azul), Erro (borda vermelha + mensagem inline abaixo, ex.: "As senhas não coincidem."), Desabilitado (fundo cinza + Inline Help "Disponível após selecionar a empresa."). Switch "Ativa/Inativa" e Checkbox ("Administrador", "Publicador").
- **Status e etiquetas**: Badge de status sempre com texto (Ativa, Inativa, Erro, Aviso, Informação) — Template Component *Badge* ou classes `u-success-text / u-danger-text / u-warning-text / u-info-text`. Etiqueta de departamento é neutra (Operações, Diretoria, Vendas): cor não sugere status.
- **Feedback do sistema**: mensagens em pt-BR, específicas e com próxima ação. Exemplos: sucesso "Colaborador salvo com sucesso. O acesso da nova conta já está disponível."; aviso "Seu perfil ainda não está vinculado a uma empresa. Gestor e equipe aparecem assim que o vínculo for cadastrado."; erro "Não foi possível salvar o colaborador. Corrija os 2 campos destacados e tente novamente."; info "Departamento, cargo e gestor dependem da empresa. Selecione a empresa para carregar as opções." APEX: Success Message do processo, erros *Inline with Field*, regiões template **Alert** para avisos persistentes.
- **Navegação lateral**: estados Padrão, Hover, Ativo (fundo + indicador + negrito — "não depende só de cor"), Grupo + subitem.
- **Estados de região**: toda região com dados precisa de **carregando** ("Carregando comunicados…" + spinner), **vazio** (ícone + "Nenhum comunicado publicado" + "Os comunicados oficiais aparecerão aqui.") e **erro** (ícone vermelho + "Não foi possível carregar" + botão "Tentar novamente"). APEX: Lazy Loading, "When No Data Found" personalizado, botões condicionados à existência de dados. Exemplo "Meu gestor" preenchido: avatar NG, "Nome do gestor", "Cargo · Departamento", botões "Chat" e "E-mail".
- **Estrutura da aplicação**: ver seção 2.

---

## 4. Telas

### 4.1 Início — `Início.png` → p00001-home
**Layout**: header + menu lateral (Início ativo). Corpo em 2 colunas (≈ 2/3 + 1/3) sob um hero de largura total.
- **Hero (card branco largura total)**: esquerda — "Olá, Sarah" (H1, primeiro nome do usuário) e data por extenso "Sexta-feira, 25 de setembro de 2026"; abaixo, 3 botões-atalho (card com ícone em quadrado azul-claro + texto + chevron ›): **Holerite digital**, **Ponto eletrônico**, **Suporte TI** (são os "Links rápidos" configuráveis). Direita — imagem decorativa (padrão orgânico em laranja/azul/creme) ocupando ~1/3, colada à borda.
- **Card "Comunicados"** (coluna esquerda): título + subtítulo "Publicações oficiais da empresa"; à direita link "Ver todos →" e botão primário "**+ Novo comunicado**" (só para perfil Publicador). Lista: o 1º item é destaque com imagem 16:9 à esquerda e, à direita, etiqueta "Para: Operações" + data "28 de julho", título grande "Teste formulário", resumo. Itens seguintes sem imagem: etiqueta "Para: Diretoria" + "15 de julho", título negrito "Segundo comunicado", resumo; "Para: Vendas" + "7 de janeiro", "Primeiro comunicado". Separadores horizontais entre itens.
- **Card "Meu gestor"** (coluna direita): estado vazio mostrado — ícone pessoa-com-x em círculo cinza, "**Nenhum gestor vinculado**", "Seu perfil ainda não está vinculado a uma empresa. Procure o RH ou a administração do CorlixHub para concluir o cadastro." Estado preenchido (do Design System): avatar, nome, "Cargo · Departamento", botões "Chat" e "E-mail".
- **Card "Aniversariantes de setembro"** (ícone bolo): lista avatar "HG" + "Henrique Oliveira Garcia" + "23 de setembro"; rodapé "Ver todos →".
**APEX**: hero = Static Content/Hero + Cards ou Lista com template "Media List"/botões; comunicados = **Content Row** ou Cards (layout horizontal, 1º com mídia); Meu gestor = Static Content com PL/SQL Dynamic Content ou Content Row, mensagem de vazio custom; Aniversariantes = **Content Row**/Avatar List (já existe "Todos os Aniversariantes do Mês" na p00001). Botão "Novo comunicado" abre p00017 (modal) com Authorization Scheme de publicador.

### 4.2 Novo comunicado (diálogo) — `Novo comunicado (diálogo).png` → p00017-comunicado
**Layout**: **Modal Dialog** centralizado (~900px) sobre a Início escurecida. Título "Novo comunicado" + ×.
- Texto: "Campos marcados com * são obrigatórios."
- **Público *** — controle segmentado (3 opções): **Todos** | **Uma empresa** | **Um departamento** (selecionado mostra ✓ e fundo escuro). APEX: item **Radio Group** com template option "Pill Button" / Display as buttons.
- Linha de 2 campos: **Departamento destinatário *** (Select List; ajuda "Só esse departamento verá o comunicado.") — visível condicionalmente conforme Público (para "Uma empresa" seria "Empresa destinatária"); **Categoria *** (Select List; ajuda "Tipo do comunicado (ex.: Eventos).").
- **Título *** (Text Field; ajuda "Frase curta e objetiva. Evite escrever tudo em maiúsculas.").
- **Comunicado *** (Textarea / Rich Text, várias linhas).
- **Imagem (opcional)** — dropzone com ícone de imagem: "Arraste uma imagem ou clique para selecionar" / "PNG ou JPG · você poderá recortar em 16:9 após selecionar". APEX: **Image Upload** com Cropping (aspect ratio 16:9), tamanho máx. pela Application Setting de imagem (5 MB).
- Checkbox **Fixar no topo** — "Aparece primeiro na lista de comunicados."
- Rodapé: "Cancelar" (secundário) + "**Publicar comunicado**" (Hot).
Mudança vs. atual: substituir o *wizard-modal-dialog* por um modal simples de uma etapa.

### 4.3 Comunicados — `Comunicados.png` → p00011-comunicados-oficiais
**Layout**: cabeçalho "Comunicados" / "Comunicados oficiais para toda a empresa e para o seu departamento." + botão "**+ Novo comunicado**". Corpo: coluna de filtros à esquerda (~1/4) + lista à direita.
- **Filtros (Faceted Search)**: busca "Título ou texto"; facetas checkbox com contagem: **Categoria** (Institucional 3, Eventos 2, Novos colaboradores 1); **Leitura** (Não lidos 2, Lidos 4); **Público** (Todos 5, Operações 1).
- **Barra da lista**: "6 comunicados" (contagem), link "**Marcar todos como lidos** ✓✓", "Ordenar por" + select "Mais recentes".
- **Itens** (card único com separadores): miniatura opcional à esquerda (~240×135); linha de metadados: ícone alfinete "Fixado", badge azul "• Novo" (não lido), etiqueta categoria ("Institucional"), "Para: Todos · 22 de setembro"; título em link azul petróleo ("Planejamento estratégico do 4º trimestre"); resumo de uma linha; opcionalmente anexo com clipe "Manual de boas práticas remotas (PDF)". Exemplos: "Workshop: cultura de transparência e feedback 360" (Novo, Eventos), "Boas-vindas aos novos talentos do time de Tecnologia" (Novos colaboradores, sem imagem), "Happy hour de encerramento do mês" (Eventos, Para: Operações), "Novos benefícios: parceria com plataformas de saúde mental", "Atualização do manual de boas práticas remotas".
- Paginação "1 – 6 de 6".
**APEX**: **Faceted Search** + **Cards** (ou Content Row) com mídia condicional; ordenação via Sort Order do Cards; "Marcar todos como lidos" = botão estilo link + processo AJAX. Usuário exibido: Ana Beatriz Souza (publicadora).

### 4.4 Colaboradores (admin) — `Colaboradores · visão de administração.png` → p00012-colaboradores
**Layout**: cabeçalho "Colaboradores" / "Encontre pessoas e gerencie contas, vínculos e perfis de acesso." + botão "**+ Novo colaborador**". Corpo: filtros à esquerda + tabela à direita.
- **Facetas**: busca "Nome, login ou e-mail"; **Situação** (Ativa 7, Inativa 1); **Empresa** (Corlix 7, Sem vínculo 1); **Departamento** (Operações 3, Vendas 3, Diretoria 1); **Perfil de acesso** (Administrador 1, Publicador de conteúdo 1, Colaborador 6).
- Barra: "8 colaboradores" + "Ordenar por" select "Nome".
- **Tabela** colunas: **Pessoa ↑** (avatar + nome em link azul + e-mail abaixo), **Login**, **Vínculo** ("Corlix · Operações" + cargo abaixo em cinza; caso sem vínculo: ícone ⚠ "**Sem vínculo**" em âmbar + "Cadastro incompleto"), **Perfil** (etiqueta neutra "Publicador de conteúdo"/"Administrador" ou texto "Colaborador"), **Situação** (badge Ativa verde / Inativa cinza). Linhas: Ana Beatriz Souza, Bruno Carvalho, Camila Rocha, Diego Martins (Inativa), Fernanda Lima (Administrador, CEO), Lucas Almeida, Rafael Nunes, Tiago Ferreira (Sem vínculo).
- Paginação "1 – 8 de 8". Clique no nome → Editar colaborador.
**APEX**: **Faceted Search** + **Classic Report** (template Standard, colunas HTML Expression para avatar/badges) ou Interactive Report.

### 4.5 Novo colaborador — `Novo colaborador.png` → p00014-cadastros-de-usuarios
**Layout**: breadcrumb "Colaboradores › Novo colaborador"; H1 "Novo colaborador"; subtítulo "Preencha os dados pessoais, o vínculo profissional e o acesso ao CorlixHub." Corpo em 3 cards, cada um com coluna de descrição à esquerda (~1/3) e campos à direita (grade 2 colunas). Rodapé fixo.
- **Card "Dados pessoais"** — descrição: "Identificação da pessoa em todo o CorlixHub. Primeiro nome e sobrenome são sugeridos a partir do nome completo e podem ser ajustados." Campos: **Nome completo *** (largura total); **Primeiro nome *** | **Sobrenome ***; **Data de nascimento *** (Date Picker; ajuda "Usada na lista de aniversariantes.").
- **Card "Vínculo profissional"** — descrição: "Empresa, área e liderança da pessoa. Departamento, cargo e gestor são carregados depois que a empresa é selecionada. Quem está no topo da hierarquia não tem gestor." Campos: **Empresa *** (Select List) | **Data de admissão *** (Date Picker); **Departamento *** | **Cargo *** (Select List em cascata, desabilitados até ter empresa; ajuda "Disponível após selecionar a empresa."); **Gestor *** (Popup LOV com lupa; desabilitado; ajuda "Busque pelo nome após selecionar a empresa.") | checkbox **Topo da hierarquia** "Não se reporta a ninguém (ex.: CEO)." (marcar torna Gestor não obrigatório/oculto).
- **Card "Acesso ao sistema"** — "Credenciais usadas para entrar no CorlixHub." Campos: **E-mail corporativo *** | **Login corporativo ***; **Senha *** | **Confirmar senha *** (Password com olho mostrar/ocultar; ajuda "Mínimo de 12 caracteres. A troca será exigida no primeiro acesso."); grupo **Perfis de acesso**: checkbox "Publicador de conteúdo — Pode publicar comunicados.", checkbox "Administrador — Acessa o grupo Administração."; ajuda "Todas as contas têm acesso de colaborador."; **Situação da conta**: Switch "Ativa" (ligado), ajuda "Novas contas nascem ativas. Contas inativas não conseguem entrar no sistema."
- Rodapé: "Todos os campos são obrigatórios." | "Cancelar" + "**Salvar colaborador**".
**APEX**: Form region dividida em 3 regiões com template "Standard"/"Blank" + coluna lateral (Region Display Selector não; usar layout de 2 colunas: Static Content de descrição col-span 4 + itens col-span 8); Cascading LOV (Parent Item = Empresa); itens floating label; validação de senha igual.

### 4.6 Editar colaborador — `Editar colaborador.png` → p00014 (modo edição)
Mesma estrutura do 4.5, com diferenças:
- Breadcrumb "Colaboradores › Ana Beatriz Souza"; H1 = nome + badge "• Ativa"; subtítulo "anasouza · ana.souza@corlix.com.br".
- Dados pessoais preenchidos (Nome completo "Ana Beatriz Souza", Primeiro nome "Ana", Sobrenome "Souza", Data de nascimento "14/03/1990"). Descrição curta: "Identificação da pessoa em todo o CorlixHub."
- Vínculo: Empresa "Corlix", Data de admissão "02/02/2026", Departamento "Operações", Cargo "Gerente de operações", Gestor "Fernanda Lima". Descrição: "Empresa, área e liderança. Alterar a empresa limpa departamento, cargo e gestor. Quem está no topo da hierarquia não tem gestor."
- Acesso: descrição "Credenciais, perfis e situação da conta."; E-mail editável; **Login corporativo** somente leitura (fundo cinza + cadeado; ajuda "O login não pode ser alterado."). Sem campos de senha — em vez disso, sub-card cinza "**Senha** — A senha atual não é exibida. Ao redefinir, a pessoa cria uma nova senha no próximo acesso." com botão secundário "🔑 **Redefinir senha**". Perfis de acesso (Publicador marcado). Situação da conta: switch "Ativa"; ajuda "Ao inativar, a pessoa perde o acesso imediatamente. O histórico é preservado."
- Rodapé: "Todos os campos são obrigatórios." | "Cancelar" + "**Salvar alterações**".
**APEX**: mesmo form com condições Server-side por `P14_ID is null`; Login com "Read Only" condicional; botão Redefinir senha = processo dedicado.

### 4.7 Empresas — `Empresas.png` → p00015-empresas-cadastradas (+ p00016 modal)
- Cabeçalho "Empresas" / "Consulte e mantenha as empresas cadastradas no CorlixHub." + botão "**+ Nova empresa**" (abre p00016 modal).
- Card com **Interactive Report** padrão: barra de pesquisa (lupa ▾, "Pesquisar", botão "Ir", menu "Ações ▾"); coluna de ícone lápis (link de edição); colunas **Nome fantasia ↑** (link azul), **Razão social**, **CNPJ**, **Cidade/UF**, **E-mail corporativo**, **Telefone**, **Status** (badge "Ativa"). Linha exemplo: Corlix · Empresa Piloto Corlix · 00.000.000/0001-00 · São Paulo – SP · financeiro@corlix.com.br · (11) 98765-1234 · Ativa.
- Rodapé do IR: "Endereço completo, CEP e data de abertura: Ações › Colunas" (colunas ocultas por padrão) | "1 – 1 de 1".

### 4.8 Organograma (navegação por níveis) — `Organograma.png` e `modulos/organograma/Organograma — redesign (navegação por níveis).png` → p00003-organograma
As duas imagens são praticamente iguais; difere apenas o texto de ajuda inferior (a versão em `modulos/` é a mais recente e menciona o drawer).
- Cabeçalho "Organograma" / "Estrutura da Corlix a partir das relações de gestão." À direita, campo de busca "Buscar pessoa no organograma" (Popup LOV/Search).
- **Breadcrumb de níveis** com ícone de hierarquia: "**Corlix** › Fernanda Lima" (níveis anteriores são links para voltar).
- **Card da pessoa focada** (centralizado, borda azul petróleo 2px): avatar "FL", nome "Fernanda Lima", "CEO · Diretoria", etiqueta "Topo da hierarquia" à direita; linha "2 subordinados diretos · 5 pessoas na estrutura"; botões secundários lado a lado "👤 **Ver perfil**" e "💬 **Conversar**".
- Conector em árvore (linha vertical + horizontal) até a fileira de **cards dos subordinados diretos** (2 lado a lado): parte superior avatar + nome em link azul + "Cargo · Departamento" (ex.: Ana Beatriz Souza — Gerente de operações · Operações; Camila Rocha — Gerente comercial · Vendas); rodapé do card separado por linha: mini-avatares sobrepostos (BC RN), "**Equipe · 2 pessoas**" / "Bruno Carvalho e Rafael Nunes", link "**Ver equipe →**" (desce um nível: a pessoa vira o card focado).
- Ajuda (centro, cinza): "Clique em um card para ver os detalhes da pessoa ou em "Ver equipe" para descer um nível. Use o caminho acima para voltar. Contas inativas não aparecem." (versão `figma/`: "Selecione "Ver equipe" para descer um nível ou use o caminho acima para voltar. Contas inativas não aparecem.")
- Estados: quem não tem equipe não mostra rodapé "Ver equipe".
**APEX**: item oculto `P3_FOCO` (id da pessoa); região Static Content/PL/SQL Dynamic Content ou **Cards** (1 para foco, 1 para filhos) com SQL `connect by`; breadcrumb dinâmico gerado por `sys_connect_by_path`; "Ver equipe" = link para a própria página com `P3_FOCO`. Já existe CSS/JS/SQL em `modulos/organograma/` (organograma.css/js/sql) e passo a passo em `Etapas-organograma.md`.

### 4.9 Organograma · detalhes da pessoa (Drawer) — `modulos/organograma/Organograma · detalhes da pessoa (Drawer) — redesign.png` → não implementada
**Drawer** à direita aberto ao clicar num card do organograma.
- Topo: avatar grande "AS", nome "Ana Beatriz Souza", "Gerente de operações · Operações", botão ×.
- Seção **Contato**: ícone envelope, rótulo "E-mail corporativo", valor "ana.souza@corlix.com.br", botão ícone copiar à direita.
- Seção **Na estrutura**: subtítulo "Reporta-se a" → card-linha clicável (avatar FL, "Fernanda Lima" em link, "CEO · Diretoria", chevron ›); subtítulo "Equipe direta · 2 pessoas" → lista de cards-linha (Bruno Carvalho — Analista de operações; Rafael Nunes — Analista de operações), cada um com chevron; link "**Ver equipe no organograma →**".
- Seção **Sobre** (grade 2×2): Departamento "Operações" | Empresa "Corlix"; Na Corlix desde "fevereiro de 2026 · 7 meses" | Aniversário "14 de março" (só dia/mês).
- Nota com cadeado: "Você vê só os dados visíveis para todos os colegas. Os demais ficam com a pessoa, a linha de gestão e a administração."
- Rodapé: "💬 Conversar" (secundário) + "**Ver perfil completo**" (primário).
**APEX**: nova página **Modal Dialog** com template **Drawer** (Template Option posição direita, tamanho médio); listas = Content Row; clicar num item da estrutura recarrega o drawer com outra pessoa.

### 4.10 Meu perfil · Trajetória — `Meu perfil (com trajetória).png` → p00002-meu-perfil
- **Cabeçalho de perfil**: avatar grande "RN" com botão-câmera sobreposto (abre drawer de foto); nome "Rafael Nunes" (H1); "Analista de operações · Operações"; linha de metadados com ícones: 📅 "Na Corlix desde junho de 2022 · 4 anos e 3 meses" e ✉ "rafael.nunes@corlix.com.br". À direita botão secundário "📷 **Alterar foto**".
- Coluna principal: card com **abas** "**Trajetória**" | "Dados pessoais". Aba Trajetória = timeline vertical: ● "**Analista de operações**" + badge "• Atual" + etiqueta "Promoção" / "Operações · março de 2024 – atual · 2 anos e 6 meses" / "Acompanhamento de indicadores e das rotinas de atendimento da área."; ○ "**Assistente de operações**" / "Operações · junho de 2022 – fevereiro de 2024 · 1 ano e 8 meses"; ○ "**Entrada na Corlix**" / "13 de junho de 2022" / "Início como assistente de operações."
- Coluna direita: card **Gestor direto** (avatar AS, "Ana Beatriz Souza" link, "Gerente de operações", botões "💬 Conversar" e "🖧 Organograma"); card **Colegas de equipe** (BC "Bruno Carvalho" — "Analista de operações"; rodapé "Pessoas com o mesmo gestor direto.").
**APEX**: **Region Display Selector** ou **Tabs region** (Tabs Container) para as abas; timeline = template de lista "Timeline" ou Content Row customizado; cards laterais = Content Row.

### 4.11 Meu perfil · Dados pessoais — `Meu perfil · aba Dados pessoais.png` → p00002-meu-perfil
Mesma página, aba "**Dados pessoais**" ativa. Conteúdo somente leitura em grade 2 colunas (rótulo pequeno cinza + valor):
Nome completo "Rafael Nunes" | E-mail corporativo "rafael.nunes@corlix.com.br"; Data de nascimento 🔒 "14/08/1995" | Login 🔒 "rafaelnunes"; Empresa "Empresa Piloto Corlix" | Departamento "Operações"; Cargo "Analista de operações" | Gestor direto "Ana Beatriz Souza"; Data de admissão "13/06/2022".
Nota com cadeado: "Visível só para você, sua linha de gestão e a administração. Colegas veem apenas dia e mês do aniversário."
Alerta info: "**Esses dados são mantidos pela administração.** Encontrou algo errado? Fale com o RH. A foto pode ser alterada por você, pelo avatar."
**APEX**: itens Display Only com template "Floating"/"Stacked" ou região Static Content; Alert region (info).

### 4.12 Meu perfil · Foto de perfil (Drawer) — `Meu perfil · foto de perfil (Drawer).png` → não implementada
**Drawer** "Foto de perfil" + ×. Corpo centralizado: avatar grande (prévia, iniciais "RN"); texto "JPG ou PNG, até 5 MB. Depois de escolher, você ajusta o recorte quadrado. A foto aparece no cabeçalho, em Colaboradores, no Organograma e em Aniversariantes."; botão secundário "📷 **Escolher foto**"; alerta info "**Nome, cargo, departamento e e-mail são mantidos pela administração.** Encontrou algo errado? Fale com o RH." Rodapé: "Cancelar" + "**Salvar foto**".
**APEX**: Modal Dialog (Drawer) com **Image Upload** (Cropping, aspect ratio 1:1, tamanho máx. via Application Setting); grava BLOB na tabela de colaboradores.

### 4.13 Histórico de carreira — `Histórico de carreira — nova página.png` → p00013-histórico-de-carreira
**Cabeçalho**: "Histórico de carreira" / "Cargos, promoções e mudanças de gestão registrados pelo RH desde a sua entrada na Corlix." + botão secundário "⬇ **Exportar PDF**". Layout 2 colunas.
- **Card de KPIs + faixa de cargos** (coluna principal): 3 KPIs lado a lado separados por divisórias — "Tempo de casa" **4 anos e 3 meses** / "Desde 13 de junho de 2022"; "No cargo atual" **2 anos e 6 meses** / "Analista de operações"; "Promoções" **1** / "Em março de 2024". Abaixo, "**Cargos ao longo do tempo**": barra horizontal proporcional (Gantt simples) — segmento cinza "Assistente de operações / jun/2022 – fev/2024 · 1 ano e 8 meses" e segmento azul petróleo "Analista de operações · atual / mar/2024 – hoje · 2 anos e 6 meses"; eixo com marcas "jun/2022, 2023, 2024, 2025, 2026, hoje".
- **Card linha do tempo**: abas "**Tudo · 8**" | "Movimentações · 5" | "Desenvolvimento · 2" + select "Ano: Todos". Agrupado por ano (cabeçalho "2026" com linha e "3 registros" à direita). Cada evento: data à esquerda ("24 set"), ícone em círculo na linha vertical, título negrito + etiqueta de tipo, descrição, metadados e link de ação. Eventos:
  - 24 set 2026 — "Plano de desenvolvimento aprovado" [PDI] — "3 objetivos criados a partir dos Resultados 360, com prazo até 31/12/2026." — "Aprovado por Ana Beatriz Souza" — link "Ver plano →".
  - 22 set — "Resultados 360 · 3º tri 2026" [Avaliação] — "Nota geral 4,4 de 5, 0,2 acima do ciclo anterior." — 🔒 "Visível só para você e sua linha de gestão" — "Ver resultados →".
  - 13 jun — "4 anos de Corlix" [Tempo de casa].
  - 2025 · 1 abr — "Reajuste por mérito" [Remuneração] — "Os valores ficam no holerite digital. Registros de remuneração não geram comunicado à equipe." — 🔒 "Visível só para você e o RH" — "Ver holerite →".
  - 2024 · 1 mar — (ícone destacado azul) "Promoção a Analista de operações" [Promoção] [• Cargo atual] — "Reconhecimento pela condução das rotinas de atendimento e pelos indicadores da área." — caixa **Antes → Depois** ("Assistente de operações / Operações · 1 ano e 8 meses no cargo" → "Analista de operações / Operações · vigente desde 01/03/2024") — "Registrado por Juliana Prado (RH) em 26/02/2024" · "Aprovado por Ana Beatriz Souza" — faixa azul-clara com megafone "Equipe de Operações avisada automaticamente em 01/03/2024." + "Ver comunicado →".
  - 2023 · 1 ago — "Mudança de gestão direta" [Gestão] — "Ana Beatriz Souza assumiu a coordenação de Operações e a sua gestão direta." — mini-cards MT "Marcelo Tavares / Gestão anterior" → AS "Ana Beatriz Souza / Gestão atual" — "Registrado por Juliana Prado (RH) em 25/07/2023".
  - 2022 · 11 set — "Período de experiência concluído" [Contrato] — "Contrato CLT efetivado após 90 dias."; 13 jun — "Entrada na Corlix" [Admissão] — "Início como Assistente de operações, na área de Operações, com gestão de Marcelo Tavares." — faixa "Boas-vindas enviadas automaticamente à equipe de Operações." + "Ver comunicado →".
- **Coluna direita**: card "**Posição atual**" (pares rótulo/valor: Cargo "Analista de operações", Área "Operações", Gestão direta "Ana Beatriz Souza", No cargo desde "01/03/2024", Contrato "CLT · efetivado"; link "Ver no organograma →"). Card "**Sobre este histórico**": itens com ícone — "Registrado pelo RH" (Cada mudança entra com data de vigência e quem aprovou.), "Equipe avisada" (Promoções e mudanças de área geram um comunicado automático.), "Remuneração é confidencial" (Reajustes aparecem só para você e o RH, sem comunicado.); separador; "**Algo incorreto?** Peça uma revisão ao RH. A correção também fica registrada no histórico." + botão secundário largo "**Solicitar correção**".
**APEX**: KPIs = Static Content / Badge List; faixa de cargos = HTML via PL/SQL Dynamic Content (ou Chart Gantt); abas + filtro = Tabs/Region Display Selector + Select List com refresh; timeline = Classic Report com template customizado ou template de lista "Timeline"; agrupamento por ano via Control Break. Ver também `modulos/historico-carreira/`.

### 4.14 Configurações — `Configurações (equipe de produto).png` → p00006-configuracoes
Cabeçalho "Configurações" / "Cadastros de apoio, acesso e parâmetros do CorlixHub. Acesso restrito à equipe de produto." Seções com título + subtítulo e grade de cards-link (ícone em quadrado azul-claro, título, descrição, chevron ›):
- **Cadastros de apoio** — "Listas usadas nos formulários e nas páginas da aplicação.": Departamentos ("Áreas de cada empresa do grupo."), Cargos ("Usados no cadastro de colaboradores."), Categorias de comunicado ("Institucional, Eventos, Novos colaboradores..."), Links rápidos ("Atalhos exibidos na página inicial.").
- **Avaliações 360** — "O que é avaliado em cada cargo e quando cada ciclo acontece.": Competências por cargo ("Por cargo. Sem lista própria, vale a do departamento."), Ciclos de avaliação ("Períodos, etapas e prazos de cada ciclo.").
- **Acesso e uso** — "Quem pode fazer o quê e como a aplicação está sendo usada.": Perfis de acesso ("Administradores, publicadores de conteúdo e equipe de produto."), Uso da aplicação ("Páginas mais acessadas, pessoas ativas e erros por página.").
- **Recursos da aplicação** — "Libere ou desligue recursos em produção, sem nova publicação (Configuration Options)." Lista com switch + rótulo de estado: Busca na intranet (Ativo) "Campo de busca no cabeçalho e página de resultados."; Links rápidos (Inativo) "Atalhos na página inicial. Aguardando a página de redirecionamento."; Notificações (Inativo) "Sino do cabeçalho com novos comunicados e aniversários."; Avaliações 360 (Ativo) "Avaliações, resultados e visão de equipe para gestores."; Exportação em PDF (Inativo) "Botões "Exportar PDF". Aguardando o servidor de impressão."; Plano de desenvolvimento (PDI) (Inativo) "Botão "Criar PDI" em Resultados 360. Aguardando o módulo."; Feedbacks (Inativo) "Registros de feedback entre os ciclos de avaliação."
- **Parâmetros** — "Valores usados pela aplicação (Application Settings)." Form em grade 3 colunas: Empresa padrão para novos colaboradores (Select, "Empresa Piloto Corlix"; ajuda "Pré-selecionada no cadastro de colaboradores."); Retenção do log da aplicação (dias) "30" ("Registros mais antigos são apagados pela rotina diária."); Tamanho máximo de imagem (MB) "5" ("Vale para comunicados, logotipos e fotos de perfil."); Grupo mínimo para percentil (pessoas) "10" ("Abaixo disso, o percentil não é exibido."); Respostas mínimas de pares "3" ("Protege o anonimato de quem avaliou."). Botão "**Salvar parâmetros**".
**APEX**: cards-link = **Cards** ou List com template "Media List"/"Cards"; switches = itens Switch que chamam `apex_app_setting`/**Build Options** (Configuration Options); parâmetros = **Application Settings** (`apex_app_setting.set_value`).

### 4.15 Monitor de logs — `Monitor de logs.png` → p00007-monitor-logs
Cabeçalho "Monitor de logs" / "Erros e eventos registrados pela aplicação. Acesso restrito à equipe de produto." À direita "Atualizado às 10:45" + botão "⟳ **Atualizar**".
- **Abas**: "**Log da aplicação**" | "Erros de página (APEX)" | "Debug (APEX)".
- Linha info: ⓘ "Erros capturados automaticamente e mensagens gravadas pela log_pkg." + etiquetas "Automático" e "Histórico de 30 dias".
- **3 KPIs clicáveis** (cards com chevron, filtram o relatório): "⊘ Erros nas últimas 24 h" **1**; "⚠ Avisos nas últimas 24 h" **1**; "ⓘ Informações nas últimas 24 h" **2**.
- **Interactive Report**: barra (Pesquisar, Ir, "Relatório: Últimas 24 h ▾" = saved reports, "Ações ▾"); coluna de ícone "abrir detalhe" (drawer); colunas **Data e hora ↓** (data + hora em 2 linhas), **Nível** (badge Aviso/Erro/Informação), **Página** ("1 · Início", "4 · Chat", "4500 · SQL Workshop"), **Usuário**, **Origem** ("Sessão", "Ação dinâmica · Executar código PL/SQL", "SQL Commands", "teste"), **Mensagem**. Rodapé: "Sessão, componente técnico e rastreamento de debug: abra o detalhe da linha." | "1 – 4 de 4".
**APEX**: Tabs (Tabs Container) com 3 sub-regiões IR (log próprio; `apex_workspace_activity_log`/erros; `apex_debug_messages`); KPIs = Cards com link que seta filtro.

### 4.16 Monitor de logs · detalhe (Drawer) — `Monitor de logs · detalhe em Drawer.png` → não implementada
**Drawer**: cabeçalho com badge "• Erro" + "**Detalhe do registro #3**" + data "24/09/2026 às 22:58:19" + ×.
- Grade 2 colunas: Página "4 · Chat" | Usuário "sarahsilva"; Aplicação "100 · CorlixHub" | Sessão "212844637268307"; Origem "Ação dinâmica · Executar código PL/SQL" | Componente técnico (monoespaçado) "APEX_APPLICATION_PAGE_DA_ACTS: NATIVE_EXECUTE_PLSQL_CODE".
- "**Mensagem completa**" + link "Copiar ⧉"; bloco monoespaçado cinza: "Ajax call returned server error ORA-01403: no data found for Execute Server-Side Code."
- "**Mensagem exibida ao usuário**": alerta âmbar "⚠ **A pessoa viu a mensagem técnica.** Trate o no_data_found no código ou traduza o erro na Error Handling Function."
- "**Rastreamento (debug)**": "O Debug não estava ativo nesta sessão. Ative o Debug e reproduza o problema para ver o passo a passo aqui."
- "**Ocorrências**": "1 nesta sessão · também registrado em Erros de página (APEX)."
- Rodapé: botão secundário "☰ **Ver em Erros de página**".
**APEX**: Modal Dialog Drawer recebendo o ID do log; itens Display Only; botão Copiar = DA `navigator.clipboard`.

### 4.17 Busca (resultados) — `Busca (resultados).png` → não implementada
Campo de busca do header preenchido ("vendas", foco azul). Cabeçalho: "Resultados para "vendas"" / "3 resultados em Pessoas e Comunicados".
- Coluna principal: card "**Pessoas** (2)" — linhas com avatar, nome em link azul ("Camila Rocha"), "Gerente comercial · Vendas", botão secundário "💬 **Conversar**" à direita; card "**Comunicados** (1)" — etiqueta "Para: Vendas" + "7 de janeiro", título em link "Primeiro comunicado", resumo.
- Coluna direita: card "**O que a busca encontra**": 👥 "Pessoas ativas, por nome, cargo ou departamento"; 📣 "Comunicados que você pode ver, por título ou texto"; ▦ "Páginas do menu às quais você tem acesso"; nota "Contas inativas e conteúdos sem permissão não aparecem nos resultados."
- Contagem por grupo em badge cinza ao lado do título.
**APEX**: nova página com **Search Region** (Search Configurations: SQL de pessoas, SQL de comunicados, lista do menu) ou 2 Content Rows filtrados por `:P0_BUSCA`; controlada pela Build Option "Busca na intranet".

### 4.18 Minha equipe (gestores) — `Minha equipe (gestores).png` → não implementada
Usuária: Fernanda Lima. Cabeçalho "Minha equipe" / "Pessoas que se reportam a você e o andamento do ciclo de avaliação." + botão secundário "⬇ **Exportar**".
- **3 KPIs**: "👥 Pessoas na equipe" **5** / "2 diretas · 3 indiretas"; "📋 Avaliações do 3º tri 2026" **3 de 5** + barra de progresso / "concluídas · prazo 30/09/2026"; "⊘ Avaliações atrasadas" **1** / "Lucas Almeida · prazo era 20/09".
- Filtros: segmentado "Diretas · 2" | "✓ **Toda a estrutura · 5**"; busca "Buscar pessoa".
- **Tabela**: **Pessoa ↑** (avatar + nome link + e-mail), **Cargo e departamento**, **Reporta-se a** ("Você" ou nome), **Última movimentação** ("Admissão · fev. 2026", "Promoção · jul. 2025"), **Avaliação do ciclo** (badge Concluída verde / Em andamento azul / Atrasada vermelho), **Ações** (ícone chat + menu "⋯"). Paginação "1 – 5 de 5".
**APEX**: Cards/Badge List para KPIs; Radio Group pill para escopo; Classic Report/IR com `connect by` a partir do gestor logado; menu ⋯ = Actions Menu (template component).

### 4.19 Minhas aprovações (Unified Task List) — `Minhas aprovações (Unified Task List).png` → não implementada
Usuária: Ana Beatriz Souza (gestora). Cabeçalho "Minhas aprovações" / "Pedidos que dependem da sua decisão." Menu lateral mostra badge "2".
- Abas "**Pendentes · 2**" | "Concluídas · 1" + select "Tipo: Todos".
- **Cards de tarefa**: etiqueta de tipo com ícone ("◎ PDI" / "📅 Prazo") + título ("Aprovar plano de desenvolvimento" / "Alterar prazo de objetivo") + horário à direita ("Hoje, 08:30"); solicitante (avatar + nome + "Analista de operações · Operações"); resumo ("2 objetivos · 5 ações · prazo final 31/12/2026") ou caixa de detalhe cinza ("**Usar dados para priorizar o atendimento** / Prazo: 15/12/2026 → **31/01/2027** / Motivo: a turma do curso de SQL foi remarcada para novembro."); rodapé "🕒 Responder até 02/10/2026" e ações: "📄 **Revisar plano**" (abre detalhe) ou "Recusar" (secundário) + "✓ **Aprovar**" (primário).
- Coluna direita: card "**Resumo**" (Pendentes 2; Mais antiga "Hoje, 08:30"; Concluídas em setembro 1); card "**Como funciona**": "Você decide os PDIs de quem se reporta diretamente a você: planos novos, objetivos novos e mudanças de prazo. A linha de gestão acima acompanha, mas não decide." / "Recusar ou pedir ajustes exige um comentário para a pessoa."
**APEX**: componente nativo **Unified Task List** (Approvals Component / Human Tasks, report context "My Tasks") com Task Definitions "Aprovar PDI" e "Alterar prazo"; alternativa: Cards sobre tabela própria de solicitações.

### 4.20 PDI · aprovação pela gestão (detalhe da tarefa) — `PDI · aprovação pela gestão (detalhe da tarefa).png` (e duplicata `(1)`) → não implementada
Breadcrumb "Minhas aprovações › Rafael Nunes"; H1 "PDI de Rafael Nunes" + badge âmbar "• Aguardando aprovação"; subtítulo "Enviado em 23/09/2026 · criado a partir dos Resultados 360 · 3º tri 2026".
- Faixa de KPIs: Objetivos **3** | Ações **7** | Prazo do plano **31/12/2026**.
- **Cards de objetivo** (um por objetivo): etiqueta de competência ("Conhecimento técnico") + "Prazo: 15/12/2026"; título ("Usar dados para priorizar o atendimento"); "Resultado esperado: Painel semanal de filas usado na reunião de segunda-feira."; lista de ações com marcador e "Prazo dd/mm" à direita ("Inscrever-se no curso de SQL para análise de dados — Prazo 30/09", "Concluir o curso — 31/10", "Montar o painel semanal de indicadores da área — 30/11"). Outros: Resiliência — "Manter o foco quando as prioridades mudam" (Combinar com a gestão um ritual semanal de repriorização — 15/10; Registrar as mudanças de prioridade e o impacto — 30/11); Liderança e influência — "Conduzir as reuniões de acompanhamento da área" (Conduzir 2 reuniões com apoio da gestão — 31/10; Conduzir 2 reuniões de forma autônoma — 15/12).
- Coluna direita: card destacado (borda azul) "**Sua decisão**" — "Aprove o plano ou peça ajustes. Rafael vê o seu comentário."; textarea "Comentário para Rafael" (ajuda "Obrigatório ao solicitar ajustes."); botão largo "✓ **Aprovar plano**" (primário) e "✎ **Solicitar ajustes**" (secundário). Card "**Contexto: Resultados 360**": Nota geral do ciclo **4,4**; "Oportunidades": Conhecimento técnico 3,9 · Resiliência 4,1 · Liderança e influência 4,2; link "Ver resultados 360 de Rafael →". Nota 🔒 "Visível para Rafael e a linha de gestão."
**APEX**: **Task Details page** (gerada pelo Approvals Component) customizada, ou página normal com Content Row/Classic Report de objetivos+ações (Control Break) e processo de aprovação com validação de comentário condicional.
**Duplicata**: `PDI · aprovação pela gestão (detalhe da tarefa)(1).png` é byte a byte idêntica (MD5 `db9ba902c1982177ddaa22f5ffc999fb`).

### 4.21 Plano de desenvolvimento (PDI) — `Plano de desenvolvimento (PDI).png` → não implementada
Usuário: Rafael Nunes. H1 "Plano de desenvolvimento" + badge "• Aprovado"; subtítulo "Criado a partir dos Resultados 360 · 3º tri 2026 · aprovado por Ana Beatriz Souza em 24/09/2026"; botão "**+ Novo objetivo**".
- **3 KPIs**: "Ações concluídas" **1 de 7** + barra / "14% do plano"; "Objetivos" **3** / "1 em andamento · 2 não iniciados"; "Prazo do plano" **31/12/2026** / "faltam 97 dias".
- **Cards de objetivo** (accordion; o primeiro expandido): etiqueta competência + badge status ("• Em andamento" azul / "• Não iniciado" cinza) + "Prazo: 15/12/2026" + menu "⋯". Alerta âmbar (pendência): "🕒 Você pediu para mudar o prazo para 31/01/2027. Aguardando aprovação de Ana Beatriz Souza." Título; "Resultado esperado: …"; barra de progresso + "1 de 3 ações". Lista de ações: ✓ verde "Inscrever-se no curso de SQL para análise de dados / Concluída em 24/09"; ○ "Concluir o curso / Prazo 31/10" + link "**Concluir**"; ○ "Montar o painel semanal de indicadores da área / Prazo 30/11" + "Concluir". Link "**Adicionar ação +**". Cards recolhidos mostram título + "0 de 2 ações" + chevron ▾.
- Coluna direita: card "**Acompanhamento**" (avatar AS, "Ana Beatriz Souza / Gestão direta", 📅 "Próxima conversa: 15/10/2026", botão largo "💬 Conversar", 🔒 "Visível para você e sua linha de gestão."); card "**Origem: Resultados 360**" ("Oportunidades do 3º tri 2026 que viraram objetivos:" Conhecimento técnico 3,9 · Resiliência 4,1 · Liderança e influência 4,2; "Ver resultados 360 →").
**APEX**: Cards/Badge para KPIs; objetivos = região **Collapsible** por objetivo (ou Classic Report com template custom); ações = Content Row com ação "Concluir" (DA AJAX); menu ⋯ = Actions Menu ("Alterar prazo" etc.).

### 4.22 PDI · Novo objetivo (Drawer) — `PDI · novo objetivo (Drawer).png` → não implementada
**Drawer** "Novo objetivo" sobre o PDI. "Campos marcados com * são obrigatórios."
- **Competência a desenvolver *** (Select; ajuda "As oportunidades do seu 360 aparecem primeiro na lista.").
- **Objetivo *** (Text; ajuda "O que você quer alcançar, em uma frase.").
- **Resultado esperado** (Textarea; ajuda "Como você e a gestão vão saber que deu certo?").
- **Prazo do objetivo *** (Date Picker, metade da largura).
- **Ações *** — "Passos concretos, cada um com prazo. Pelo menos uma ação." Linhas repetíveis: [Ação 1 *] [Prazo 📅] [🗑]; [Ação 2] [Prazo] [🗑]; link "**Adicionar ação +**".
- Alerta info: "**Novos objetivos passam pela aprovação de Ana Beatriz Souza.** O restante do plano continua valendo enquanto isso."
- Rodapé: "Cancelar" + "**Enviar para aprovação**".
**APEX**: Modal Drawer; ações = **Interactive Grid** editável simples (colunas Ação, Prazo) ou itens dinâmicos via APEX_COLLECTION; ao salvar dispara tarefa de aprovação (Human Task).

### 4.23 Avaliações · avaliação de pares — `Avaliações · avaliação de pares.png` → não implementada
Usuário: Rafael Nunes avaliando um par. Breadcrumb "Avaliações › Bruno Carvalho"; H1 "Avaliação de Bruno Carvalho"; subtítulo "Avaliação de pares · Ciclo 3º tri 2026 · prazo 30/09/2026 (em 5 dias)".
- **Stepper** horizontal (4 etapas): ✓ "Autoavaliação / Concluída" — ● "Avaliação de pares / Em andamento" — ○ "Avaliação do gestor / Após os pares" — ○ "Resultado / Libera em 07/10".
- Card do avaliado: avatar BC, "Você está avaliando", "**Bruno Carvalho**", "Analista de operações · Operações · colega de equipe"; à direita "1 de 6 competências" + barra de progresso.
- **Card da competência** (borda azul): "Competência 2 de 6"; ○ "**Liderança e influência**"; descrição "Inspira confiança, motiva as pessoas e ajuda a resolver conflitos de forma construtiva."; "**Nível observado ***" — 5 botões grandes de escala: **1** Insuficiente · **2** Em desenvolvimento · **3** Esperado · **4** Supera · **5** Exemplar; textarea "Exemplos observados (opcional)" com ajuda "Situações recentes e concretas tornam o feedback útil para a pessoa."
- Coluna direita: card "**Competências**" — "Definidas para o cargo Analista de operações"; lista: ✓ Comunicação assertiva [Nota 4]; ● Liderança e influência [• Atual] (linha destacada azul-claro); ○ Conhecimento técnico / Proatividade / Resiliência / Trabalho em equipe — "Pendente". Card "**Minhas avaliações**" [1 pendente]: RN Autoavaliação • Concluída; BC "Bruno Carvalho · par" • Em andamento (destacado). Card dica 💡 "**Seja específico** — Descreva fatos e resultados que você observou. Feedback com exemplos ajuda no desenvolvimento."
- **Rodapé fixo**: "☁ Rascunho salvo às 10:42" (autosave) | "O envio é liberado na última competência." + "← Anterior" (secundário) + "**Próxima competência**" (primário; na última vira "Enviar avaliação").
**APEX**: Wizard Progress (template de lista "Wizard Progress") para o stepper; Radio Group com template "Pill Button"/large para a escala 1–5; navegação por item `P_COMPETENCIA_IDX`; autosave via DA AJAX; lista de competências = Content Row/Media List.

### 4.24 Resultados 360 — `Resultados 360.png` → não implementada
Usuário: Rafael Nunes. H1 "Resultados 360"; subtítulo "Ciclo 3º tri 2026 · Analista de operações · concluído em 22/09/2026". Ações à direita: select "Ciclo: 3º tri 2026", "📄 **Exportar PDF**" (secundário), "◎ **Criar PDI**" (primário; controlado pela Build Option PDI).
- Card "**Nota geral do ciclo**": **4,4** de 5 (número enorme), barra de progresso, "↑ +0,2 em relação ao 2º tri 2026" (verde).
- Card "**Percentil no cargo**": **85** de 100 + barra; "Nota maior que a de 17 das outras 20 pessoas com o cargo Analista de operações neste ciclo."; 🔒 "Visível só para você e para a sua linha de gestão." (oculto se grupo < parâmetro "Grupo mínimo para percentil").
- Card "**Comparativo por competência**" (largo): legenda Autoavaliação (azul) · Gestor (laranja) · Pares (verde) + link "Ver em tabela"; "Competências definidas para o cargo Analista de operações."; para cada competência 3 barras horizontais finas empilhadas e a média à direita: Comunicação assertiva 4,8; Liderança e influência 4,2; Conhecimento técnico 3,9; Proatividade 4,5; Resiliência 4,1; Trabalho em equipe 4,7. Nota: "Escala de 1 a 5. Pares: média de 3 respostas anônimas (aparece só com 3 ou mais respostas). A nota da competência é a média das três fontes."
- Card "**Evolução da nota geral**" + "Ver tabela": gráfico de colunas (3º tri 25, 4º tri 25, 1º tri 26, 2º tri 26 em cinza; 3º tri 26 em azul com rótulo 4,4).
- Card "**Pontos fortes**" (ícone ✓ verde): Comunicação assertiva — "Explica prioridades com clareza para o time e para outras áreas."; Trabalho em equipe — "Está sempre disponível para ajudar colegas nos picos de demanda."; Proatividade — "Antecipa problemas nos indicadores antes que afetem o atendimento."
- Card "**Oportunidades de desenvolvimento**" (ícone 💡): Conhecimento técnico — "Aprofundar o uso das ferramentas de análise de dados."; Resiliência — "Manter o foco quando as prioridades mudam no meio da semana."; Liderança e influência — "Assumir a condução das reuniões de acompanhamento."
**APEX**: KPIs = Static Content/Badge; comparativo = **Chart** (JET) Bar horizontal com 3 séries (ou HTML de barras); evolução = Chart Bar vertical; "Ver em tabela" alterna para Classic Report; pontos fortes/oportunidades = Content Row/Media List.

### 4.25 Feedbacks · Recebidos — `Feedbacks.png` → não implementada
Usuário: Rafael Nunes. Cabeçalho "Feedbacks" / "Registros entre os ciclos de avaliação, ligados às competências." + botão "⊞ **Dar feedback**" (abre drawer).
- Abas "**Recebidos · 3**" | "Enviados · 2" + select "Competência: Todas".
- **Cards de feedback**: avatar + nome do autor + relação ("Gestão direta", "Colega de equipe", "Vendas"); data à direita ("19/09/2026"); etiquetas: tipo com ícone ("🎖 Reconhecimento" ou "💡 Sugestão") + competência ("Comunicação assertiva"); texto do feedback; rodapé: 🔒 visibilidade ("Visível para você e sua linha de gestão" / "Só você") e link "**Agradecer ♡**".
  Exemplos: Ana Beatriz Souza — Reconhecimento/Comunicação assertiva — "A apresentação dos indicadores na reunião de segunda foi clara e ajudou o time a decidir rápido o que priorizar."; Bruno Carvalho — Sugestão/Conhecimento técnico — "Vale automatizar a planilha de filas. Posso mostrar como fiz no relatório mensal."; Camila Rocha — Reconhecimento/Trabalho em equipe — "Agradeço por cobrir os chamados de vendas no pico do fim do mês. Fez diferença para o time."
- Coluna direita: card "**No 3º tri 2026**" (Recebidos 3; Enviados 2; — Reconhecimentos 2; Sugestões 1; — "Por competência": Comunicação assertiva 1; Conhecimento técnico 1; Trabalho em equipe 1). Card "**Como dar um bom feedback**": **Situação** — Quando e onde aconteceu.; **Comportamento** — O que a pessoa fez, sem julgamentos.; **Impacto** — O efeito no time ou no resultado.
**APEX**: Tabs (Region Display Selector) com 2 regiões **Cards**/Content Row; "Agradecer" = DA AJAX; resumo = Classic Report key/value.

### 4.26 Feedbacks · Enviados — `Feedbacks · aba Enviados.png` → não implementada
Mesma página, aba "**Enviados · 2**". Cards com "Para Bruno Carvalho / Colega de equipe" e data "Hoje, 10:15"; etiquetas "🎖 Reconhecimento" "Trabalho em equipe"; texto "Na virada do mês, você reorganizou a fila de chamados sem que ninguém pedisse. O time zerou o atraso em dois dias."; rodapé "🔒 Só a pessoa" e, enquanto dentro de 24 h, "Pode ser excluído até 26/09 às 10:15" + link vermelho "**Excluir 🗑**". Segundo card: "Para Lucas Almeida / Vendas" "02/09/2026", "💡 Sugestão" "Comunicação assertiva", "Nas passagens de turno, vale registrar os chamados pendentes no canal da equipe para ninguém perder o contexto.", "🔒 A pessoa e a linha de gestão dela", à direita "♡ Lucas agradeceu" (estado de agradecimento recebido).

### 4.27 Feedbacks · Dar feedback (Drawer) — `Feedbacks · dar feedback (Drawer).png` → não implementada
**Drawer** "Dar feedback" + ×. "Campos marcados com * são obrigatórios."
- **Para quem *** (Popup LOV com lupa; valor "Bruno Carvalho"; ajuda "Busque pelo nome de qualquer colaborador.").
- **Tipo *** — segmentado "🎖 **Reconhecimento**" (selecionado, escuro) | "💡 Sugestão".
- **Competência** (Select; "Trabalho em equipe"; ajuda "Opcional. Liga o feedback às competências do 360.").
- **Feedback *** (Textarea; ajuda "Situação, comportamento e impacto. 114 de 1.000 caracteres." — contador, máx. 1000).
- **Quem pode ver *** — Radio: ◉ "Só a pessoa" / ○ "A pessoa e a linha de gestão dela".
- Alerta info: "**Feedbacks não são anônimos nem editáveis.** A pessoa vê quem enviou. Depois do envio, você pode excluir em até 24 horas."
- Rodapé: "Cancelar" + "**Enviar feedback**".

---

## 5. Funcionalidades presentes no design mas sem backend ainda

| Funcionalidade | Telas | Entidades de dados necessárias (sugestão) |
|---|---|---|
| **Busca global** | Busca (resultados), header | Nenhuma tabela nova obrigatória: consulta sobre colaboradores (ativos), comunicados (com regra de visibilidade por público) e menu/páginas autorizadas. Opcional: Search Configuration do APEX, índice Oracle Text. Build Option "Busca na intranet". |
| **Links rápidos** | Início (Holerite digital, Ponto eletrônico, Suporte TI), Configurações | `LINK_RAPIDO` (id, empresa_id, titulo, icone, url, ordem, ativo). |
| **Notificações (sino)** | Header, Configurações | `NOTIFICACAO` (id, colaborador_id, tipo, titulo, link, lida_em, criado_em) — páginas p00005/p00008 já existem, falta modelo/integração. |
| **Comunicados: categorias, leitura, fixar, anexo, público** | Comunicados, Novo comunicado | `CATEGORIA_COMUNICADO` (id, nome); colunas em `COMUNICADO`: categoria_id, publico_tipo (TODOS/EMPRESA/DEPARTAMENTO), empresa_id, departamento_id, fixado, imagem BLOB/mime, anexo; `COMUNICADO_LEITURA` (comunicado_id, colaborador_id, lido_em); `COMUNICADO_ANEXO` (id, comunicado_id, nome, blob, mime). |
| **Foto de perfil** | Meu perfil (drawer) | Colunas `FOTO` BLOB, `FOTO_MIME`, `FOTO_ATUALIZADA_EM` em colaborador. |
| **Cargos / Departamentos como cadastros de apoio** | Novo/Editar colaborador, Configurações | `DEPARTAMENTO` (id, empresa_id, nome), `CARGO` (id, empresa_id/departamento_id, nome); colaborador com gestor_id (auto-relacionamento), topo_hierarquia, data_admissao, data_nascimento, perfis (publicador, administrador), situação. |
| **Histórico de carreira** | Histórico de carreira, Meu perfil (Trajetória) | `MOVIMENTACAO_CARREIRA` (id, colaborador_id, tipo [ADMISSAO, PROMOCAO, MUDANCA_GESTAO, CONTRATO, REMUNERACAO, TEMPO_CASA, PDI, AVALIACAO], data_vigencia, titulo, descricao, cargo_anterior_id, cargo_novo_id, gestor_anterior_id, gestor_novo_id, departamento_*, visibilidade [COLEGAS/GESTAO/RH], registrado_por, registrado_em, aprovado_por, comunicado_id); `SOLICITACAO_CORRECAO` (id, colaborador_id, movimentacao_id, texto, status). Ver `modulos/historico-carreira/`. |
| **Avaliações 360** | Avaliações (pares), Resultados 360, Minha equipe, Configurações | `COMPETENCIA` (id, nome, descricao); `COMPETENCIA_CARGO` (cargo_id ou departamento_id, competencia_id, ordem); `CICLO_AVALIACAO` (id, nome "3º tri 2026", inicio, fim, prazo_auto, prazo_pares, prazo_gestor, libera_resultado_em, status); `AVALIACAO` (id, ciclo_id, avaliado_id, avaliador_id, tipo [AUTO/PAR/GESTOR], status [PENDENTE/EM_ANDAMENTO/CONCLUIDA/ATRASADA], rascunho_salvo_em, enviada_em); `AVALIACAO_RESPOSTA` (avaliacao_id, competencia_id, nota 1–5, exemplos); `RESULTADO_360` (ciclo_id, colaborador_id, nota_geral, percentil, pontos fortes/oportunidades — pode ser view materializada) + parâmetros (grupo mínimo percentil, respostas mínimas de pares). |
| **PDI — Plano de desenvolvimento** | Plano de desenvolvimento, Novo objetivo, PDI aprovação, Resultados 360 ("Criar PDI") | `PDI` (id, colaborador_id, ciclo_origem_id, prazo, status [RASCUNHO/AGUARDANDO/APROVADO/AJUSTES], enviado_em, aprovado_por, aprovado_em, proxima_conversa); `PDI_OBJETIVO` (id, pdi_id, competencia_id, titulo, resultado_esperado, prazo, status [NAO_INICIADO/EM_ANDAMENTO/CONCLUIDO], aprovado); `PDI_ACAO` (id, objetivo_id, descricao, prazo, concluida_em); `PDI_SOLICITACAO_PRAZO` (objetivo_id, prazo_atual, prazo_novo, motivo, status). |
| **Minhas aprovações** | Minhas aprovações, PDI aprovação | Preferencialmente **APEX Human Tasks** (Task Definitions "Aprovar PDI", "Novo objetivo", "Alterar prazo"; tabelas internas `APEX_TASKS`), ou tabela própria `SOLICITACAO_APROVACAO` (id, tipo, solicitante_id, aprovador_id, referencia_id, payload, prazo_resposta, status, comentario, decidido_em). |
| **Feedbacks** | Feedbacks (Recebidos/Enviados/Drawer) | `FEEDBACK` (id, autor_id, destinatario_id, tipo [RECONHECIMENTO/SUGESTAO], competencia_id nullable, texto ≤1000, visibilidade [PESSOA/PESSOA_E_GESTAO], criado_em, excluido_em, agradecido_em). Regra: excluir só até 24 h. |
| **Minha equipe** | Minha equipe | Reaproveita colaborador.gestor_id (hierarquia `connect by`), `MOVIMENTACAO_CARREIRA` (última movimentação) e `AVALIACAO` (status do ciclo). |
| **Monitor de logs — detalhe** | Drawer de log | Tabela de log da `log_pkg` precisa de: sessão, aplicação, componente técnico, mensagem completa, mensagem exibida ao usuário, flag "viu mensagem técnica"; cruzamento com `APEX_WORKSPACE_ACTIVITY_LOG` / `APEX_DEBUG_MESSAGES`. |
| **Configurações: Recursos e Parâmetros** | Configurações | **Build Options** (Configuration Options) para Busca, Links rápidos, Notificações, Avaliações 360, Exportação PDF, PDI, Feedbacks; **Application Settings** para empresa padrão, retenção de log (dias), tamanho máx. de imagem (MB), grupo mínimo de percentil, respostas mínimas de pares. |
| **Exportação em PDF** | Histórico de carreira, Resultados 360, Minha equipe ("Exportar") | Servidor de impressão (ORDS/BI Publisher/APEX Office Print) — sem tabela; depende de infraestrutura. |
| **Comunicado automático** | Histórico (promoção/admissão "Equipe avisada") | Trigger/processo que cria `COMUNICADO` vinculado a `MOVIMENTACAO_CARREIRA.comunicado_id`. |
| **Uso da aplicação** | Configurações (card) | Views sobre `APEX_WORKSPACE_ACTIVITY_LOG` (páginas mais acessadas, pessoas ativas, erros por página). |

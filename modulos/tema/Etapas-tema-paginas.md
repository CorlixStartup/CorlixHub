# Tema Corlix · passo a passo por página

O tema vale para o app inteiro assim que o CSS é carregado: não existe um "ligar o tema" por página. O trabalho em cada página é tirar o que **foge** do design system: estilos colados no HTML, cores fixas e modelos de botão ou rótulo diferentes do padrão.

Faça a etapa 0 uma vez. Depois siga página por página. Ao fim de cada página, recarregue com **Ctrl+Shift+R** (Cmd+Shift+R no Mac) para não ver CSS antigo em cache.

---

## 0. Conferência inicial (uma vez)

1. **Ordem do CSS:** *Shared Components > User Interface Attributes > CSS > File URLs*, exatamente nesta ordem:
   ```
   #APP_FILES#corlix-tema#MIN#.css
   #APP_FILES#custom#MIN#.css
   ```
   Se o `custom` vier antes, ele não enxerga os tokens `--cx-*` (as variáveis de cor do tema).
2. **Estilo do tema:** *Shared Components > Themes > Universal Theme > Styles*. **Redwood Light** deve estar como *Current*.
3. **Theme Roller:** abra o Theme Roller (barra de desenvolvedor > *Theme Roller*) e confirme que não há estilo personalizado salvo por cima do Redwood Light. Se houver, volte ao Redwood Light original.
4. **Teste rápido:** abra qualquer página e confira:
   - fundo `#F1EFED` e cabeçalho branco;
   - item atual do menu lateral com barra azul;
   - links azuis.

   Se nada mudou, o problema está no passo 1, e não nas páginas.

---

## 1. Regras que valem para todas as páginas

Use como checklist em cada página:

| Elemento | Como deve ficar |
|---|---|
| **Botões** | Uma única ação principal por tela com **Hot = Yes** (escuro). As demais ficam no template *Text*, sem Hot. Links do tipo "Ver todos →" usam *Template Options > Style: Remove UI Decoration*. Excluir usa *Template Options > Type: Danger*, sem Hot. |
| **Campos** | Obrigatórios com label template **Required - Floating** e os demais com **Optional - Floating**. Orientação vai no *Inline Help Text*, não no label. |
| **Regiões** | Template **Standard** com título em frase normal ("Meu gestor", não "MEU GESTOR"). Nada de `<span style=...>` no título ou no Header Text. |
| **Estilos no HTML** | Remova `style="..."` com cor, fonte, tamanho ou fundo. Se precisar de cor, use os tokens (`var(--cx-primaria)`, `var(--cx-texto-2)`...) no CSS ou as classes `cx-badge` / `cx-etiqueta`. |
| **Mensagens** | Sucesso na *Success Message* do processo; erro inline no campo (*Display Location: Inline with Field*). |
| **Título da página** | Mantenha a região de título que a página já tem (template *Title Bar*). Se o protótipo mostra uma descrição embaixo do título (Organograma, Histórico...), veja o passo 1.1. |

### 1.1 Título com descrição

No protótipo, várias páginas têm título grande e uma linha de descrição, por exemplo "Organograma" e "Estrutura da Corlix a partir das relações de gestão.". No APEX:

1. Apague a região de breadcrumb (*Title Bar*) da página.
2. Crie uma região **Static Content** no slot **Breadcrumb Bar**:
   - Title: o nome da página
   - Template: **Hero**. Em *Template Options*, esconda o ícone (*Icon: Hide* / *Display Icon: No*).
   - Source (HTML): a descrição, por exemplo `Estrutura da Corlix a partir das relações de gestão.`
3. Botões da página, como "Exportar PDF" ou "Novo", vão no slot **Next** dessa região, alinhados à direita.

---

## 2. Página a página

### Página 0 · Global Page (cabeçalho)

Nada obrigatório: a busca, os ícones e o usuário já estão estilizados pelo `custom.css` (classes `corlix-header__*`).

**Opcional:** a prancha do design system leva a engrenagem para "Preferências" no menu do usuário. Isso é mudança de navegação, não de tema (ver seção 3).

---

### Página 1 · Home

Esta é a página com mais ajustes, porque tem muitos estilos colados no HTML.

**1. Região `card_aniversariantes`:** substitua o HTML por:
```html
<div class="cx-cabecalho-card">
  <h3>Aniversariantes</h3>
  <span class="figma-badge-mes cx-badge cx-badge--info"></span>
</div>
```
A classe `figma-badge-mes` continua: é por ela que o JavaScript da página preenche o mês. O badge passa a ser o "Informação" do design system, e o título deixa de ficar em caixa alta.

**2. Região `card_meu_gestor`:**
- *Header Text*: `<h3>Meu gestor</h3>`
- *Footer Text* (botões secundários do design system, com ícone):
  ```html
  <div class="cx-acoes-card">
    <a class="t-Button t-Button--icon t-Button--iconLeft" href="#">
      <span class="t-Icon t-Icon--left fa fa-comment-o" aria-hidden="true"></span>
      <span class="t-Button-label">Chat</span>
    </a>
    <a class="t-Button t-Button--icon t-Button--iconLeft" href="#">
      <span class="t-Icon t-Icon--left fa fa-envelope-o" aria-hidden="true"></span>
      <span class="t-Button-label">E-mail</span>
    </a>
  </div>
  ```
  Os `href="#"` são os mesmos de hoje. Quando o chat e o e-mail tiverem destino, troque por eles.
- *Title > HTML Expression*:
  ```html
  <div class="cx-pessoa">
    <img src="&FOTO_GESTOR." alt="" class="cx-pessoa__foto"
         onerror="this.onerror=null; this.src='#APP_FILES#default-user.jpeg';">
    <div>
      <strong class="cx-pessoa__nome">&NOME_GESTOR.</strong>
      <span class="cx-pessoa__detalhe">&NOME_CARGO.</span>
    </div>
  </div>
  ```
  O `onerror` também passa a usar a imagem padrão do app. Hoje ele aponta para `https://dicebear.com`, que não é uma imagem.

**3. Região `lista_de_comunicados`:** a prancha pede que a etiqueta de departamento seja neutra, porque cor não pode sugerir status. Em *Title > HTML Expression*, troque:
```html
<span class="cmt-badge &CLASSE_DEPTO.">&DEPARTAMENTO.</span>
```
por:
```html
<span class="cx-etiqueta">&DEPARTAMENTO.</span>
```
A coluna `CLASSE_DEPTO` da query pode ser removida depois.

**4. Região `card_boas_vindas`:** no HTML, remova o `style="text-decoration:none;"` do link da empresa. A cor do link já vem do tema.

**5. Botão `B_VER_TODOS`** (terciário do design system):
- Label: `Ver todos`
- Button Template: **Text with Icon** · Icon: `fa-arrow-right` · Template Options: *Icon Position: Right*, *Style: Remove UI Decoration*
- *Advanced > Custom Attributes*: **apague todo o `style="..."`**. Ele força o azul antigo `#3B66F5`, sublinhado e 19px.
- *Advanced > CSS Classes*: deixe só `figma-footer-link`.

**6. Botão `emitir-comunicado`:** pela prancha, ele vira "Novo comunicado".
- Label: `Novo comunicado`
- Button Template: **Text with Icon** · Icon: `fa-plus` · sem Hot. Na Home ele é uma ação secundária.
- Mantenha a Authorization Scheme *Publicador de Conteúdo*, se já houver.

**7. Região `card_links_rapidos`:** nos `<svg>` dos ícones, troque `stroke="#4f46e5"` e `fill="#4f46e5"` por `stroke="currentColor"` e `fill="currentColor"`. A cor passa a ser a primária do tema.

**8. CSS de apoio:** acrescente as classes novas ao fim do `custom.css`, gere de novo o `custom.min.css` e suba os dois:
```css
/* Home: cabeçalho de card, ações e pessoa (design system) */
.cx-cabecalho-card { display: flex; justify-content: space-between; align-items: center; gap: 12px; padding: 16px 16px 12px; }
.cx-cabecalho-card h3 { margin: 0; }
.cx-acoes-card { display: flex; gap: 8px; }
.cx-acoes-card .t-Button { flex: 1; justify-content: center; }
.cx-pessoa { display: flex; align-items: center; gap: 16px; }
.cx-pessoa > div { display: flex; flex-direction: column; gap: 2px; }
.cx-pessoa__foto { width: 52px; height: 52px; border-radius: 50%; object-fit: cover; flex-shrink: 0; }
.cx-pessoa__nome { font-size: 14px; color: var(--cx-texto); }
.cx-pessoa__detalhe { font-size: 12px; color: var(--cx-texto-3); }
.links-rapidos-card .icon { color: var(--cx-primaria); }
```

**9. Cores antigas que ainda estão no `custom.css`,** nos blocos da Home. Troque por tokens:

| Hoje | Trocar por |
|---|---|
| `#3B66F5`, `#2563EB`, `#056ac8`, `#4f46e5` | `var(--cx-primaria)` |
| `#eef2ff` (hover dos links rápidos) | `var(--cx-tag)` |
| `#111827`, `#151515`, `#404040`, `#000` | `var(--cx-texto)` |
| `#6B7280`, `#6b7280`, `#4b5563` | `var(--cx-texto-2)` |
| `#E5E7EB`, `#F3F4F6`, `#f3f4f6` | `var(--cx-borda)` |
| classes `.dept-0` a `.dept-5` e `.cmt-badge` | podem ser apagadas depois do item 3 |

---

### Página 2 · Meu perfil · Página 5 · Notificações · Página 6 · Configurações · Página 8 · Notificações · Página 11 · Comunicados oficiais · Página 12 · Colaboradores

Essas páginas só têm a barra de título por enquanto: **nada a ajustar**. Confira o visual e, se o protótipo dessa tela tiver descrição, aplique o passo 1.1. Quando o conteúdo for montado, siga as regras da seção 1 e a tela correspondente em `figma/`.

---

### Página 3 · Organograma

1. Siga o `modulos/organograma/Etapas-organograma.md`. O `organograma.css` já lê os tokens do tema.
2. Aplique o passo 1.1: título "Organograma", descrição "Estrutura da Corlix a partir das relações de gestão." e o campo de busca no slot *Next*.

---

### Página 4 · Chat

O CSS da página tem uma paleta própria, em azul e cinza diferentes do tema. Em *Page > CSS > Inline*, troque só as linhas das cores dentro do `:root { ... }` do início:
```css
--ch-blue:        var(--cx-primaria);
--ch-blue-soft:   var(--cx-primaria-suave);
--ch-bubble-in:   var(--cx-tag);
--ch-border:      var(--cx-borda);
--ch-border-soft: var(--cx-borda);
--ch-surface:     var(--cx-superficie-2);
--ch-text:        var(--cx-texto);
--ch-text-dim:    var(--cx-texto-2);
--ch-text-faint:  var(--cx-texto-3);
--ch-avatar-bg:   var(--cx-primaria-suave);
--ch-avatar-fg:   var(--cx-primaria);
--ch-radius:      var(--cx-raio-card);
```
Deixe como estão as cores de status (`--ch-online`, `--ch-ausente`, `--ch-offline`) e as medidas (`--ch-topbar-h`, `--ch-list-w`, `--ch-avatar-size`). As bolhas das suas mensagens passam a usar o azul `#00688C`.

---

### Página 7 · Monitor de logs

Nada obrigatório: Interactive Reports e abas já seguem o tema, e a aba ativa fica com o sublinhado azul. Confira o visual.

---

### Página 13 · Histórico de carreira

Siga o `modulos/historico-carreira/Etapas-historico-carreira.md`, item 2. O `historico-carreira.css` já lê os tokens do tema.

---

### Página 14 · Cadastro de usuários

1. **Cabeçalho:** a região `cadastrar-colaborador-header` tem um `<h1>` e um `<span>` com estilo fixo. Apague essa região e aplique o passo 1.1:
   - Title: `Cadastro de usuários`
   - Descrição: `Preencha as informações para registrar um novo colaborador no sistema.`
2. **Campos obrigatórios:** estes itens têm *Value Required = Yes*, mas usam o template de opcional. Troque o *Label > Template* para **Required - Floating**:
   - `P14_NOME_COMPLETO`
   - `P14_EMAIL`
   - `P14_EMPRESA`
   - `P14_DEPARTAMENTO`
   - `P14_CARGO`
   
   Se login e senha também forem obrigatórios (há validação para a senha), marque *Value Required = Yes* e use o mesmo template em `P14_LOGIN`, `P14_SENHA` e `P14_CONFIRMAR_SENHA`.
3. **Botões:** já estão certos. "Cancelar" é *Text*, e "Salvar" é *Text* com Hot.

---

### Página 15 · Empresas cadastradas

Nada obrigatório: o Interactive Report e o botão "Criar" (Hot) já seguem o padrão.

---

### Página 16 · Cadastro de empresas (modal)

1. **Títulos das regiões:** nas regiões `Configurações`, `Contato e Endereço` e `Informações Principais`, apague o *Header Text* (`<span style="font-size:20px;...">`). Deixe só o *Title* da região, e confira em *Template Options* que o cabeçalho está visível. O título passa a ter o tamanho e a cor do tema.
2. **Botão `delete`:** *Template Options > Type: Danger*, sem Hot.
3. **Botões `create` e `save`:** continuam Hot. Eles nunca aparecem juntos, então a tela tem uma ação principal por vez.

---

### Página 17 · Emitir comunicado (modal)

Já segue o padrão: campos com rótulo flutuante e "Próximo" Hot com ícone à direita.

**Opcional:** renomeie o título da página para "Novo comunicado", para ficar igual ao botão da Home e ao protótipo `figma/Novo comunicado (diálogo).png`.

---

### Página 26 · Central de equipes

Nada obrigatório: botão "Criar" Hot e regiões *Standard*. Confira o visual.

---

### Página 27 · Nova equipe (modal)

Botão `delete`: *Template Options > Type: Danger*, sem Hot. O resto já segue o padrão.

---

### Página 9999 · Login

Nada obrigatório: o tema muda o fundo, a cor do botão "Entrar" (Hot, escuro) e o foco dos campos. Confira o visual.

---

## 3. Componentes compartilhados (não são de página)

Decisões da prancha "Estrutura da aplicação" que ficam nos Shared Components:

1. **Navigation Menu** (*Shared Components > Lists > Navigation Menu*): ícones distintos para conceitos distintos.

   | Entrada | Ícone |
   |---|---|
   | Início | `fa-home` |
   | Comunicados | `fa-bullhorn` |
   | Chat | `fa-comments-o` |
   | Pessoas | `fa-users` |
   | Organograma | `fa-sitemap` |
   | Minha carreira | `fa-briefcase` |
   | Histórico de carreira | `fa-history` |
   | Administração | `fa-shield` |

   O grupo Administração recebe a Authorization Scheme na própria entrada da lista.
2. **"Emitir comunicado":** deixa de ser uma entrada filha de Início. Ela foi substituída pelo botão "Novo comunicado" (Página 1, item 6).
3. **"Sair":** sai do rodapé do menu lateral e vai para o menu do usuário. Quando fizer isso, apague do `custom.css` o bloco `#t_TreeNav>ul[role="group"]>li:last-child`, que hoje transforma o último item do menu em botão de rodapé.

---

## 4. Checklist final

- [ ] Nenhuma página com `style="..."` de cor ou fonte no HTML (busque por `style=` no export).
- [ ] Uma única ação Hot por tela; Excluir sempre com *Type: Danger*.
- [ ] Todo campo obrigatório com **Required - Floating**.
- [ ] Etiquetas de departamento neutras (`cx-etiqueta`); badges de status sempre com texto.
- [ ] Títulos de região em frase normal, sem caixa alta.
- [ ] Teste com o teclado (Tab): todo elemento focado mostra o contorno azul de 2px.

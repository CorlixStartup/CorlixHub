# Tema Corlix

Tema visual do Corlix Hub, baseado nos protótipos do Figma exportados em `figma/`. A referência principal é a prancha **"Design System · Redwood Light (CorlixHub)"**. O tema fica em `corlixhub/shared-components/static-files/corlix-tema.css`.

## Como foi construído

A própria prancha define a regra: *"os tokens aproximam o Oracle Redwood Light; no APEX, use os componentes nativos, Template Options e Theme Roller correspondentes (a fonte real do tema é a Oracle Sans)"*.

Por isso o tema não é um tema novo nem um template novo. É uma camada de variáveis CSS por cima do **Redwood Light**, o estilo que o app já usa no Universal Theme 26.1. O que muda em relação ao Redwood:

| | Redwood Light | Corlix |
|---|---|---|
| Cor primária | verde Oracle `#5F7D4F` | azul-petróleo `#00688C` (`sky-120` da própria paleta Redwood) |
| Fundo das páginas | `#F5F4F2` | `#F1EFED` |
| Cabeçalho | cinza claro | branco com borda fina |
| Menu lateral | seleção só por fundo | fundo `#EDEBE8` + barra de 3px + negrito |
| Título da página | faixa de textura de 6px | linha de 1px |
| Regiões | sombra | borda de 1px, sem sombra |
| Botão secundário | cinza neutro | cinza quente `#EAE7E3` |
| Foco do teclado | tracejado de 1px | contorno sólido de 2px na primária |

A **fonte** continua a Oracle Sans do Redwood. O Figma usa Figtree só porque a Oracle Sans não está disponível lá. Cantos de botões e campos, rótulo flutuante, switch, checkbox e alertas também ficam como no Redwood, porque a prancha já os desenha assim.

Os nomes das variáveis (`--ut-*`, `--a-*`, `--rw-palette-*`) foram extraídos do CSS do Universal Theme 26.1.5 servido pela própria instância. Se uma atualização do APEX renomear alguma, o tema perde só aquele ajuste, sem quebrar a página.

## Componentes: o que usar no APEX

Tabela montada a partir da prancha do design system:

| Na prancha | No APEX |
|---|---|
| Botão primário (escuro) | Botão com **Hot = Yes**. Uma única ação primária por contexto. |
| Botão secundário (cinza) | Botão padrão (*Text*) |
| Botão terciário ("Ver todos →") | Template Option *Style > Remove UI Decoration*. O tema pinta o texto de azul. |
| Somente ícone | Template *Icon*, que fica neutro |
| Campo de formulário | Label template **Optional - Floating** / **Required - Floating**, Inline Help Text para orientação e erro *Inline with Field* |
| Badge de status ("Ativa", "Erro"...) | Template Component Badge, ou a classe `cx-badge cx-badge--sucesso|neutro|erro|aviso|info` em HTML próprio. Sempre com texto, nunca só cor. |
| Etiqueta de departamento | Classe `cx-etiqueta`: neutra, sem cor de status |
| Feedback ("Colaborador salvo com sucesso") | Success Message do processo. Avisos persistentes vão numa região com template **Alert**. |
| Estados de região (carregando, vazio, erro) | Lazy Loading na região, mensagem *When No Data Found* personalizada e botões condicionados aos dados |
| Navegação lateral | Navigation Menu nativo. O grupo Administração usa Authorization Scheme na entrada da lista. |

## Tokens

Os tokens `--cx-*` são a fonte da verdade. Os CSS dos módulos (`organograma.css`, `historico-carreira.css`) e o `custom.css` leem esses tokens. Para mudar uma cor no app inteiro, mude aqui.

| Token | Valor | Uso |
|---|---|---|
| `--cx-primaria` | `#00688C` | links, foco, abas, item atual do menu, botão terciário |
| `--cx-primaria-suave` | `#E4F1F7` | avatares de iniciais, badge "Informação" |
| `--cx-primaria-texto` | `#1D5F84` | texto sobre fundo suave (avisos, pílulas) |
| `--cx-fundo` | `#F1EFED` | fundo das páginas |
| `--cx-superficie` / `-2` | `#FFFFFF` / `#FBF9F8` | cards, regiões, rodapés de drawer |
| `--cx-tag` | `#F5F4F2` | etiquetas, campo de busca |
| `--cx-borda` | `#E4E1DD` | bordas e divisórias |
| `--cx-selecionado` | `#EDEBE8` | item selecionado do menu |
| `--cx-texto` / `-2` / `-3` | `#161513` / `#57534F` / `#6B6661` | título, texto secundário, metadado |
| `--cx-btn` / `-hover` | `#EAE7E3` / `#DEDAD5` | botão secundário |
| `--cx-escuro` | `#312D2A` | botão primário (Hot) |
| `--cx-raio-card` | 8px | regiões e cards |

## Como aplicar

1. **Arquivos estáticos:** em *Shared Components > Static Application Files*, suba:
   - `corlix-tema.css` (novo)
   - `custom.css` e `custom.min.css` (atualizados)
   - `organograma.css` e `historico-carreira.css`, se já estiverem no app
2. **Ordem de carga:** em *Shared Components > User Interface Attributes > CSS > File URLs*, deixe nesta ordem:
   ```
   #APP_FILES#corlix-tema#MIN#.css
   #APP_FILES#custom#MIN#.css
   ```
   O `application.apx` do repositório já está assim. Se você importar o app pelo APEXlang, esse passo vem junto.
3. **Estilo do tema:** mantenha o **Redwood Light** como estilo atual. Não altere variáveis no Theme Roller: elas competiriam com este arquivo. Ajustes de cor ficam nos tokens `--cx-*`.

## O que mudou no `custom.css`

O `custom.css` passou a usar os tokens do tema:
- **Fundo das páginas:** saiu o `#dddddd`; agora vem do tema.
- **Fontes fixas:** saíram "Segoe UI" e "Sora" dos cards da Home (o `.min` foi gerado de novo).
- **Busca e ícones do cabeçalho:** ajustados para o protótipo (busca de 360px, ícones sem fundo).
- **Cards da Home:** borda fina no lugar da sombra.

## O que conferir depois de aplicar

- [ ] Fundo das páginas `#F1EFED` e cabeçalho branco com borda fina.
- [ ] Menu lateral: item da página atual com fundo `#EDEBE8`, texto em negrito e barra azul de 3px à esquerda.
- [ ] Título da página com uma linha fina embaixo, sem a faixa colorida do Redwood.
- [ ] Regiões com borda fina, cantos de 8px e sem sombra.
- [ ] Links, botões terciários e foco do teclado (Tab) em `#00688C`. Botões Hot escuros.
- [ ] Home: textos na fonte do tema (antes os cards forçavam "Segoe UI").

O seletor do item atual no menu lateral é o ponto mais sensível. Se a barra azul não aparecer, inspecione o item no DevTools e ajuste a regra `.t-TreeNav ... .is-current` no `corlix-tema.css` para a classe que a sua versão usa.

## Decisões da prancha que não são de tema

A seção "Estrutura da aplicação" da prancha traz mudanças de navegação. Elas pedem alterações em listas, templates e páginas, não em CSS, e ficaram fora deste arquivo:

- **"Emitir comunicado":** deixa de ser filho de Início e vira o botão "Novo comunicado" na região Comunicados.
- **"Sair":** sai do rodapé do menu lateral e vai para o menu do usuário, junto com "Meu perfil" e "Preferências". Hoje o `custom.css` ainda estiliza o último item do menu como botão de rodapé; isso sai junto.
- **"SEM VÍNCULO":** sai do cabeçalho e aparece no menu do usuário e no card Meu gestor, com explicação.
- **Ícones:** distintos para conceitos distintos: Comunicados com megafone e Chat com balões; Organograma com hierarquia e Histórico com relógio.
- **Engrenagem:** vira "Preferências" no menu do usuário.
- **Menu lateral:** ganha "Minha equipe" e "Minhas aprovações" (com contador) em Pessoas.

## Fora do escopo

- **Modo escuro:** a prancha só tem a versão clara.
- **As telas de `figma/`:** o tema cobre os componentes da prancha. Cada tela ainda precisa ser montada ou ajustada página a página, como foi feito com o organograma e o histórico de carreira.

#!/usr/bin/env python3
"""Gera docs/ai-context/index.html a partir dos .md desta pasta.

Uso (na raiz do repo):  python3 docs/ai-context/gerar-html.py
Rode de novo sempre que algum .md desta pasta mudar. Só usa a stdlib; o HTML
renderiza o Markdown no navegador com marked + mermaid (CDN jsdelivr).
"""
import json
import pathlib

PASTA = pathlib.Path(__file__).resolve().parent
ARQUIVOS = ["README.md"] + sorted(p.name for p in PASTA.glob("[0-9][0-9]-*.md"))

docs = []
for nome in ARQUIVOS:
    texto = (PASTA / nome).read_text(encoding="utf-8")
    titulo = next((l.lstrip("# ").strip() for l in texto.splitlines() if l.startswith("# ")), nome)
    docs.append({"arquivo": nome, "titulo": titulo, "md": texto})

dados = json.dumps(docs, ensure_ascii=False).replace("</", "<\\/")

HTML = """<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Corlix Hub · Contexto para IAs</title>
<style>
:root{--bg:#fbf9f8;--fg:#161513;--muted:#6f6964;--line:#e4e1dd;--side:#f1efed;--accent:#227e9e;--code:#f1efed}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#1b1a19;--fg:#ecebe9;--muted:#a8a29d;--line:#3a3836;--side:#232220;--accent:#5fb3d1;--code:#2a2826}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.6 system-ui,-apple-system,"Segoe UI",sans-serif}
.layout{display:grid;grid-template-columns:280px 1fr;min-height:100vh}
nav{background:var(--side);border-right:1px solid var(--line);padding:20px 14px;position:sticky;top:0;height:100vh;overflow:auto}
nav h1{font-size:15px;margin:0 0 4px}nav p{color:var(--muted);font-size:12px;margin:0 0 14px}
nav input{width:100%;padding:7px 9px;border:1px solid var(--line);border-radius:6px;background:var(--bg);color:var(--fg);margin-bottom:12px}
nav a{display:block;padding:6px 9px;border-radius:6px;color:var(--fg);text-decoration:none;font-size:13.5px}
nav a.on{background:var(--bg);box-shadow:inset 3px 0 0 var(--accent);font-weight:600}
nav a.sub{padding-left:22px;color:var(--muted);font-size:12.5px}
main{padding:28px 40px 80px;max-width:1100px;min-width:0}
main h1{font-size:26px;border-bottom:1px solid var(--line);padding-bottom:8px}
main h2{margin-top:2em;font-size:20px}main h3{font-size:16px}
a{color:var(--accent)}
table{border-collapse:collapse;display:block;overflow-x:auto;font-size:13.5px;margin:12px 0}
th,td{border:1px solid var(--line);padding:6px 9px;text-align:left;vertical-align:top}
th{background:var(--side)}
code{background:var(--code);padding:1px 5px;border-radius:4px;font-size:.9em}
pre{background:var(--code);padding:12px 14px;border-radius:6px;overflow-x:auto}pre code{padding:0}
blockquote{margin:0;padding:4px 14px;border-left:3px solid var(--accent);color:var(--muted)}
mark{background:#f6d77a;color:#161513}
@media (max-width:800px){.layout{grid-template-columns:1fr}nav{position:static;height:auto}main{padding:20px 16px}}
</style>
</head>
<body>
<div class="layout">
<nav>
  <h1>Corlix Hub</h1><p>Contexto para IAs · gerado de docs/ai-context/*.md</p>
  <input id="q" type="search" placeholder="Buscar nos documentos…">
  <div id="menu"></div>
</nav>
<main id="conteudo"></main>
</div>
<script src="https://cdn.jsdelivr.net/npm/marked@12/marked.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
<script>
const DOCS = __DADOS__;
const menu = document.getElementById('menu'), main = document.getElementById('conteudo'), q = document.getElementById('q');
const slug = s => s.toLowerCase().normalize('NFD').replace(/[\\u0300-\\u036f]/g,'').replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'');
try { mermaid.initialize({startOnLoad:false, theme: matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default'}); } catch(e) {}

function render(i, ancora){
  const d = DOCS[i];
  let md = d.md.replace(/\\]\\(\\.\\/([0-9]{2}-[^)#]+\\.md|README\\.md)(#[^)]*)?\\)/g, (m, f, h) => '](#' + f + (h || '') + ')');
  main.innerHTML = marked.parse(md);
  main.querySelectorAll('h2,h3').forEach(h => h.id = slug(h.textContent));
  main.querySelectorAll('pre code.language-mermaid').forEach(c => { const div = document.createElement('div'); div.className='mermaid'; div.textContent=c.textContent; c.parentElement.replaceWith(div); });
  try { mermaid.run({querySelector:'.mermaid'}); } catch(e) {}
  if (q.value.trim()) destacar(q.value.trim());
  montarMenu(i);
  if (ancora) { const el = document.getElementById(ancora); if (el) el.scrollIntoView(); } else scrollTo(0,0);
}
function montarMenu(atual){
  const termo = q.value.trim().toLowerCase();
  menu.innerHTML = '';
  DOCS.forEach((d, i) => {
    if (termo && !d.md.toLowerCase().includes(termo)) return;
    const a = document.createElement('a'); a.href = '#' + d.arquivo; a.textContent = d.titulo; if (i === atual) a.className = 'on'; menu.appendChild(a);
    if (i === atual) d.md.split('\\n').filter(l => l.startsWith('## ')).forEach(l => {
      const t = l.slice(3).replace(/`/g,''); const s = document.createElement('a'); s.className='sub'; s.href = '#' + d.arquivo + '#' + slug(t); s.textContent = t; menu.appendChild(s);
    });
  });
}
function destacar(termo){
  const w = document.createTreeWalker(main, NodeFilter.SHOW_TEXT); const nos = []; let n;
  while ((n = w.nextNode())) if (n.nodeValue.toLowerCase().includes(termo.toLowerCase())) nos.push(n);
  nos.forEach(n => { const re = new RegExp('(' + termo.replace(/[.*+?^${}()|[\\]\\\\]/g,'\\\\$&') + ')','gi'); const span = document.createElement('span'); span.innerHTML = n.nodeValue.replace(/[&<>]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;'}[c])).replace(re,'<mark>$1</mark>'); n.replaceWith(span); });
}
function rota(){
  const [arq, ancora] = decodeURIComponent(location.hash.slice(1)).split('#');
  const i = Math.max(0, DOCS.findIndex(d => d.arquivo === arq));
  render(i, ancora);
}
q.addEventListener('input', rota);
addEventListener('hashchange', rota);
rota();
</script>
</body>
</html>
"""

(PASTA / "index.html").write_text(HTML.replace("__DADOS__", dados), encoding="utf-8")
print(f"index.html gerado com {len(docs)} documentos.")

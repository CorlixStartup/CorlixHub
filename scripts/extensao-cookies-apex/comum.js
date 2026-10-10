// Código compartilhado entre o service worker (background.js) e o popup.
// Guia: docs/ai-context/09-erro-400-cookies.md, §9.

const PADRAO_HOST = /(^|\.)oraclecloudapps\.com$/;
// Buffer do nginx por linha de cabeçalho no padrão (large_client_header_buffers 4 8k).
// O valor usado pela Oracle não é público: ajuste se o 400 aparecer antes ou depois disso.
const LIMITE = 8192;
const ALERTA = 0.6;
const CRITICO = 0.85;
const CONFIG_PADRAO = { autoLimpar: true, apagarSempre: '', nuncaApagar: '' };
const MAX_EVENTOS = 30;

function hostValido(host) {
    return PADRAO_HOST.test(host.replace(/^\./, ''));
}

async function lerConfig() {
    const { config } = await chrome.storage.local.get('config');
    return { ...CONFIG_PADRAO, ...config };
}

// Uma expressão regular por linha; linhas vazias são ignoradas. Regex inválida = sem regra.
function regex(texto) {
    const linhas = (texto || '').split('\n').map(l => l.trim()).filter(Boolean);
    if (!linhas.length) return null;
    try { return new RegExp(linhas.join('|')); } catch { return null; }
}

// Os mesmos cookies que o Chrome envia para a URL (respeita domínio e path).
async function medir(url) {
    const cookies = await chrome.cookies.getAll({ url });
    const bytes = 'Cookie: '.length
        + cookies.reduce((t, c) => t + c.name.length + 1 + c.value.length, 0)
        + Math.max(cookies.length - 1, 0) * 2;
    return { cookies, bytes };
}

function removerCookie(c) {
    const host = c.domain.replace(/^\./, '');
    return chrome.cookies.remove({ url: `https://${host}${c.path}`, name: c.name, storeId: c.storeId });
}

// Apaga todos os cookies do host, menos os que casam com "nunca apagar".
async function limparHost(host, config) {
    const nunca = regex(config.nuncaApagar);
    const cookies = await chrome.cookies.getAll({ domain: host });
    const alvo = cookies.filter(c => !(nunca && nunca.test(c.name)));
    await Promise.all(alvo.map(removerCookie));
    return alvo.length;
}

// Nunca guarda o valor do cookie: ele contém a sessão.
function resumo(cookies) {
    const porNome = {};
    cookies.forEach(c => { porNome[c.name] = (porNome[c.name] || 0) + 1; });
    return cookies
        .map(c => ({ nome: c.name, path: c.path, bytes: c.name.length + 1 + c.value.length,
                     httpOnly: c.httpOnly, sessao: c.session, repetido: porNome[c.name] > 1 }))
        .sort((a, b) => b.bytes - a.bytes);
}

async function registrar(lista, evento) {
    const dados = await chrome.storage.local.get(lista);
    const eventos = [evento, ...(dados[lista] || [])].slice(0, MAX_EVENTOS);
    await chrome.storage.local.set({ [lista]: eventos });
}

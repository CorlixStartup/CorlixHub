// Service worker: limpa no erro 400, aplica as regras de limpeza preventiva,
// mantém o badge com o tamanho do cabeçalho e registra cookies descartados.
importScripts('comum.js');

const FILTRO = { urls: ['https://*.oraclecloudapps.com/*'] };
const ultimaLimpeza = new Map(); // tabId -> horário; evita loop de recarga

// 1) Erro 400 numa navegação: só age se o cabeçalho estiver grande, para não
//    confundir com um 400 que não tem a ver com cookies.
chrome.webRequest.onCompleted.addListener(async (d) => {
    if (d.statusCode !== 400 || d.tabId < 0) return;
    const { cookies, bytes } = await medir(d.url);
    if (bytes < LIMITE * 0.5) return;

    const host = new URL(d.url).hostname;
    const config = await lerConfig();
    const evento = { quando: new Date().toISOString(), host, bytes, total: cookies.length,
                     cookies: resumo(cookies), acao: 'só registrou (limpeza automática desligada)' };

    if (config.autoLimpar) {
        if (Date.now() - (ultimaLimpeza.get(d.tabId) || 0) < 15000) {
            evento.acao = 'não limpou: já tinha limpado há menos de 15 s (evita loop)';
        } else {
            ultimaLimpeza.set(d.tabId, Date.now());
            evento.removidos = await limparHost(host, config);
            evento.acao = `limpou ${evento.removidos} cookies e recarregou`;
            chrome.tabs.reload(d.tabId);
        }
    }
    await registrar('eventos400', evento);
}, { ...FILTRO, types: ['main_frame'] });

// 2) Cookies descartados pelo próprio Chrome. "evicted" = limite de cookies
//    estourado, que é a pista de logout com o workspace esquecido (09 §8).
chrome.cookies.onChanged.addListener(({ removed, cookie, cause }) => {
    if (!hostValido(cookie.domain)) return;
    if (removed && (cause === 'evicted' || cause === 'expired')) {
        registrar('descartados', { quando: new Date().toISOString(), nome: cookie.name,
                                   path: cookie.path, causa: cause });
    }
    clearTimeout(globalThis.agendado);
    globalThis.agendado = setTimeout(verificarAbas, 1000);
});

chrome.tabs.onActivated.addListener(verificarAbas);
chrome.tabs.onUpdated.addListener((id, info) => { if (info.status === 'complete') verificarAbas(); });

// 3) Limpeza preventiva: passou do alerta, apaga os cookies de "apagar sempre".
async function verificarAbas() {
    const config = await lerConfig();
    const sempre = regex(config.apagarSempre);
    const nunca = regex(config.nuncaApagar);
    const abas = await chrome.tabs.query({ url: FILTRO.urls });

    for (const aba of abas) {
        let { cookies, bytes } = await medir(aba.url);
        if (sempre && bytes >= LIMITE * ALERTA) {
            const alvo = cookies.filter(c => sempre.test(c.name) && !(nunca && nunca.test(c.name)));
            if (alvo.length) {
                await Promise.all(alvo.map(removerCookie));
                ({ bytes } = await medir(aba.url));
            }
        }
        const fracao = bytes / LIMITE;
        chrome.action.setBadgeText({ tabId: aba.id, text: (bytes / 1024).toFixed(1) });
        chrome.action.setBadgeBackgroundColor({
            tabId: aba.id,
            color: fracao >= CRITICO ? '#c74634' : fracao >= ALERTA ? '#ac630c' : '#508223'
        });
    }
}

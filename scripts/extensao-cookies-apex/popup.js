// Popup: medidor da aba atual, limpeza manual, relatório e configuração.
const $ = id => document.getElementById(id);
let atual = null; // { host, url, cookies, bytes }

async function carregar() {
    const [aba] = await chrome.tabs.query({ active: true, currentWindow: true });
    const host = aba && aba.url ? new URL(aba.url).hostname : '';
    if (!hostValido(host)) {
        $('host').textContent = 'Abra uma aba do Autonomous (*.oraclecloudapps.com).';
        $('medidor').hidden = true;
    } else {
        const { cookies, bytes } = await medir(aba.url);
        atual = { host, url: aba.url, cookies, bytes };
        $('host').textContent = host;
        desenharMedidor(bytes, cookies.length);
        desenharCookies(resumo(cookies));
    }

    const config = await lerConfig();
    $('autoLimpar').checked = config.autoLimpar;
    $('apagarSempre').value = config.apagarSempre;
    $('nuncaApagar').value = config.nuncaApagar;

    const { eventos400 = [], descartados = [] } = await chrome.storage.local.get(['eventos400', 'descartados']);
    lista($('eventos400'), eventos400.map(e =>
        `${dataHora(e.quando)} · ${(e.bytes / 1024).toFixed(1)} KB em ${e.total} cookies · ${e.acao}`));
    lista($('descartados'), descartados.map(e =>
        `${dataHora(e.quando)} · ${e.nome} (${e.path}) · ${e.causa === 'evicted' ? 'descartado por limite' : 'expirou'}`));
}

function desenharMedidor(bytes, total) {
    const fracao = bytes / LIMITE;
    $('preenchido').style.width = Math.min(fracao, 1) * 100 + '%';
    $('preenchido').style.background = fracao >= CRITICO ? 'var(--critico)' : fracao >= ALERTA ? 'var(--alerta)' : 'var(--ok)';
    $('resumo').textContent = `${(bytes / 1024).toFixed(1)} KB de ~${LIMITE / 1024} KB · ${total} cookies`;
}

function desenharCookies(itens) {
    $('cookies').replaceChildren(...itens.map(c => {
        const tr = document.createElement('tr');
        if (c.repetido) { tr.className = 'repetido'; tr.title = 'Mesmo nome em mais de um path: todas as cópias vão no cabeçalho'; }
        [c.nome, c.path, c.bytes].forEach(v => { const td = document.createElement('td'); td.textContent = v; tr.append(td); });
        return tr;
    }));
}

function lista(ul, linhas) {
    ul.replaceChildren(...(linhas.length ? linhas : ['Nada registrado.']).map(t => {
        const li = document.createElement('li'); li.textContent = t; return li;
    }));
}

const dataHora = iso => new Date(iso).toLocaleString('pt-BR');

$('limpar').onclick = async () => {
    const removidos = await limparHost(atual.host, await lerConfig());
    $('aviso').textContent = `${removidos} cookies removidos. Recarregue a página e faça login de novo.`;
    carregar();
};

// Tabela em Markdown para colar na §6 do guia. Não inclui valores.
$('copiar').onclick = async () => {
    const linhas = resumo(atual.cookies).map(c =>
        `| ${c.nome} | ${c.path} | ${c.bytes} | ${c.httpOnly ? 'sim' : 'não'} | ${c.repetido ? 'sim' : ''} |`);
    const texto = [`Host: ${atual.host} · ${atual.bytes} bytes · ${atual.cookies.length} cookies · ${dataHora(new Date().toISOString())}`,
        '', '| Nome | Path | Bytes | HttpOnly | Repetido |', '|---|---|---|---|---|', ...linhas].join('\n');
    await navigator.clipboard.writeText(texto);
    $('aviso').textContent = 'Relatório copiado (sem os valores dos cookies).';
};

$('salvar').onclick = async () => {
    const config = { autoLimpar: $('autoLimpar').checked,
                     apagarSempre: $('apagarSempre').value, nuncaApagar: $('nuncaApagar').value };
    const invalida = ['apagarSempre', 'nuncaApagar'].find(k => config[k].trim() && !regex(config[k]));
    if (invalida) { $('aviso').textContent = 'Regex inválida: corrija antes de salvar.'; return; }
    await chrome.storage.local.set({ config });
    $('aviso').textContent = 'Configuração salva.';
};

carregar();

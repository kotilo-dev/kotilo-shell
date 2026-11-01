// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

const symbolPattern = /^[A-Za-z0-9.^=_-]{1,24}$/;

function symbolSource(text) {
    const fund = /^tefas:([A-Za-z0-9]{2,6})$/i.exec(text);
    if (fund) return { kind: "tefas", symbol: fund[1].toUpperCase() };
    return symbolPattern.test(text) ? { kind: "yahoo", symbol: text.toUpperCase() } : null;
}

// "GC=F*USDTRY=X/31.1035" -> [{ op, value } or { op, source }], or null. Only multiplying and
// dividing by numbers and symbols: this is parsed, never evaluated as code.
function terms(formula) {
    const list = [];
    const parts = String(formula).split(/([*/])/).map(p => p.trim());
    for (let i = 0; i < parts.length; i += 2) {
        const op = i === 0 ? "*" : parts[i - 1];
        const number = Number(parts[i]);
        if (parts[i].length && isFinite(number)) {
            if (number === 0 && op === "/") return null;
            list.push({ op: op, value: number });
            continue;
        }
        const source = symbolSource(parts[i]);
        if (!source) return null;
        list.push({ op: op, source: source });
    }
    return list.some(t => t.source) ? list : null;
}

// A list entry -> what to show. An entry is a string such as "AAPL" or "tefas:AFT", or an object:
// { symbol, label } or { formula, label, currency }. Anything else is null and never reaches a URL.
function source(entry) {
    if (typeof entry === "string") {
        const item = symbolSource(entry.trim());
        return item ? Object.assign({}, item, { label: item.symbol, key: item.kind + ":" + item.symbol, needs: [item] }) : null;
    }
    if (!entry || typeof entry !== "object") return null;
    if (typeof entry.formula === "string") {
        const list = terms(entry.formula);
        if (!list) return null;
        const needs = list.filter(t => t.source).map(t => t.source);
        return Object.assign({}, needs[0], { label: String(entry.label || entry.formula), key: "formula:" + entry.formula, terms: list, needs: needs, currency: String(entry.currency || "") });
    }
    if (typeof entry.symbol !== "string") return null;
    const item = source(entry.symbol);
    return item ? Object.assign(item, { label: String(entry.label || item.label) }) : null;
}

// The quote of a formula from its parts' quotes, or null until all are in. A missing part fails the
// whole line: a partial product would be a wrong price.
function compute(item, quotes) {
    let price = 1, constant = 1, change = 1, length = Infinity, known = true;
    const series = [];
    for (const term of item.terms) {
        if (term.source === undefined) {
            const factor = term.op === "*" ? term.value : 1 / term.value;
            price *= factor;
            constant *= factor;
            continue;
        }
        const quote = quotes[term.source.kind + ":" + term.source.symbol];
        if (!quote) return null;
        if (quote.error) return { error: true };
        price = term.op === "*" ? price * quote.price : price / quote.price;
        if (quote.change === null) known = false;
        else change *= term.op === "*" ? 1 + quote.change / 100 : 1 / (1 + quote.change / 100);
        length = Math.min(length, quote.history.length);
        series.push({ op: term.op, history: quote.history });
    }
    const history = [];
    for (let i = 1; i <= length; i++) {
        let value = constant;
        for (const s of series) value = s.op === "*" ? value * s.history[s.history.length - i] : value / s.history[s.history.length - i];
        history.unshift(value);
    }
    return { name: "", price: price, currency: item.currency, change: known ? (change - 1) * 100 : null, history: history };
}

function dataUrl(item) {
    return item.kind === "tefas" ? "https://www.tefas.gov.tr/tr/fon-detayli-analiz/" + item.symbol
        : "https://query1.finance.yahoo.com/v8/finance/chart/" + encodeURIComponent(item.symbol) + "?range=1mo&interval=1d";
}

function pageUrl(item) {
    return item.kind === "tefas" ? "https://www.tefas.gov.tr/tr/fon-detayli-analiz/" + item.symbol
        : "https://finance.yahoo.com/quote/" + encodeURIComponent(item.symbol);
}

// A chart reply -> { name, price, change, currency, history }, or null. The day's change compares
// the last two closes: chartPreviousClose is the close before the whole range, not yesterday's.
function parseChart(text) {
    const reply = JSON.parse(text);
    const result = reply && reply.chart && reply.chart.result && reply.chart.result[0];
    if (!result || !result.meta || typeof result.meta.regularMarketPrice !== "number") return null;
    const meta = result.meta;
    const quote = result.indicators && result.indicators.quote && result.indicators.quote[0];
    const closes = (quote && quote.close ? quote.close : []).filter(c => typeof c === "number");
    const before = closes.length >= 2 ? closes[closes.length - 2] : null;
    return { name: String(meta.shortName || meta.longName || ""), price: meta.regularMarketPrice, currency: String(meta.currency || ""),
             change: before ? (meta.regularMarketPrice - before) / before * 100 : null, history: closes };
}

// "1.234,56" -> 1234.56, or NaN.
function turkishNumber(text) {
    return /^-?[\d.]*,?\d+$/.test(text) ? Number(text.replace(/\./g, "").replace(",", ".")) : NaN;
}

// A TEFAS fund page -> the same shape, or null. The page is not an API, so a change in its layout
// must read as failure: a wrong price is worse than none.
function parseTefas(html) {
    const text = String(html).replace(/<script[\s\S]*?<\/script>/gi, " ").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ");
    const price = /Son Fiyat \(TL\) (-?[\d.,]+)/.exec(text);
    const change = /Günlük Getiri \(%\) %? ?(-?[\d.,]+)/.exec(text);
    if (!price) return null;
    const value = turkishNumber(price[1]);
    if (!isFinite(value) || value <= 0) return null;
    const percent = change ? turkishNumber(change[1]) : NaN;
    return { name: "", price: value, currency: "TRY", change: isFinite(percent) ? percent : null, history: [] };
}

function price(value, currency) {
    const digits = value >= 10 ? 2 : 4;              // currency pairs need the last places
    const fixed = value.toFixed(digits).replace(/\B(?=(\d{3})+(?!\d))(?=[\d,]*\.)/g, ",");
    return currency ? fixed + " " + currency : fixed;
}

function percent(value) {
    return value === null ? "" : (value > 0 ? "+" : "") + value.toFixed(2) + "%";
}

// Closes as percentages of their own range, so the shape of a month shows at any price.
function shape(history) {
    if (history.length < 2) return [];
    const low = Math.min.apply(null, history), high = Math.max.apply(null, history);
    return history.map(v => high > low ? 8 + (v - low) / (high - low) * 92 : 50);
}

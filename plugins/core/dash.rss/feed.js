// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

const named = { amp: "&", lt: "<", gt: ">", quot: "\"", apos: "'", nbsp: " " };

function decode(text) {
    return text.replace(/&(#x[0-9a-f]+|#[0-9]+|[a-z]+);/gi, (all, code) => {
        if (code[0] !== "#") return named[code.toLowerCase()] !== undefined ? named[code.toLowerCase()] : all;
        const n = code[1].toLowerCase() === "x" ? parseInt(code.slice(2), 16) : parseInt(code.slice(1), 10);
        return n > 0 && n <= 0x10ffff ? String.fromCodePoint(n) : "";
    });
}

// Inner text of an element: CDATA kept, entities decoded, then tags removed.
function clean(text) {
    const unwrapped = text.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, (all, inner) => inner.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"));
    const once = decode(unwrapped.replace(/<[^>]*>/g, " "));
    return decode(once.replace(/<[^>]*>/g, " ")).replace(/\s+/g, " ").trim();
}

function element(block, names) {
    for (const name of names) {
        const m = new RegExp("<" + name + "(?:\\s[^>]*)?>([\\s\\S]*?)</" + name + ">", "i").exec(block);
        if (m) return clean(m[1]);
    }
    return "";
}

function link(block) {
    const tags = block.match(/<link\b[^>]*>/gi) || [];
    for (const tag of tags) {
        const href = /href\s*=\s*["']([^"']+)["']/i.exec(tag);
        if (href && !/rel\s*=\s*["'](?!alternate)/i.test(tag)) return decode(href[1]).trim();
    }
    return element(block, ["link"]);
}

function web(url) {
    return /^https?:\/\//i.test(url) ? url : "";
}

// RSS or Atom text -> { title, items: [{ title, link, date, summary }] }. Dates are ms, or 0.
function parse(text) {
    const xml = String(text);
    const blocks = xml.match(/<(item|entry)\b[\s\S]*?<\/\1>/gi) || [];
    const head = xml.slice(0, Math.max(0, xml.search(/<(item|entry)\b/i)));
    return {
        title: element(head.length ? head : xml, ["title"]),
        items: blocks.map(block => {
            const when = Date.parse(element(block, ["pubDate", "published", "updated", "dc:date"]));
            return { title: element(block, ["title"]), link: web(link(block)), date: isFinite(when) ? when : 0,
                     summary: element(block, ["description", "summary", "content:encoded", "content"]).slice(0, 400) };
        }).filter(i => i.title.length > 0)
    };
}

// Every feed's items as one list, newest first.
function merge(feeds, limit) {
    const all = [];
    for (const f of feeds) for (const i of f.items) all.push(Object.assign({ source: f.title }, i));
    return all.sort((a, b) => b.date - a.date).slice(0, limit);
}

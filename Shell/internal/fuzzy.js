// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

// rank(query, title, keywords) -> number. -1 means no match. The title a person sees outranks
// hidden keywords, so a loose keyword match cannot beat a real word in the title.
function rank(query, title, keywords) {
    const inTitle = score(query, title);
    if (inTitle >= 0) return 1000 + inTitle;
    return keywords ? score(query, keywords) : -1;
}

// score(query, text) -> number. -1 means no match; otherwise higher is better.
// Every query character must appear in order. Matches earn more at the start of the text,
// at the start of a word and right after the previous match; gaps cost a little.
function score(query, text) {
    const q = String(query).toLowerCase().replace(/\s+/g, "");
    const t = String(text).toLowerCase();
    if (!q.length) return 0;
    if (q.length > t.length) return -1;

    const isBoundary = i => i === 0 || " -_./:".indexOf(t[i - 1]) >= 0;
    // prev[j]: best score with the previous query char matched at text index j.
    let prev = null;
    for (let i = 0; i < q.length; i++) {
        const cur = new Array(t.length).fill(-1);
        for (let j = i; j < t.length; j++) {
            if (t[j] !== q[i]) continue;
            let bonus = 1 + (j === 0 ? 8 : isBoundary(j) ? 6 : 0);
            if (prev === null) { cur[j] = bonus - Math.min(j, 3) * 0.1; continue; }
            for (let k = 0; k < j; k++) {
                if (prev[k] < 0) continue;
                const s = prev[k] + bonus + (k === j - 1 ? 5 : -Math.min(j - k - 1, 5) * 0.2);
                if (s > cur[j]) cur[j] = s;
            }
        }
        prev = cur;
    }
    const best = Math.max.apply(null, prev);
    // Among equal matches, the shorter text is the closer one.
    return best < 0 ? -1 : best + q.length / t.length;
}

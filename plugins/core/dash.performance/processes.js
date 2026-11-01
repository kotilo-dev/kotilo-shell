// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

// Output of `top -b -n 2 -e k` -> [{ name, cpu, memKb }], from the last sample. The first sample
// holds averages since each process started, not current use.
function parseTop(text) {
    const lines = String(text).split("\n");
    let start = -1;
    lines.forEach((line, i) => { if (/^\s*PID\s+USER\b/.test(line)) start = i; });
    if (start < 0) return [];
    const list = [];
    for (const line of lines.slice(start + 1)) {
        const f = line.trim().split(/\s+/);
        if (f.length < 12) continue;
        const memKb = Number(f[5]), cpu = Number(f[8]);
        if (!isFinite(memKb) || !isFinite(cpu)) continue;
        list.push({ name: f.slice(11).join(" ").split("/")[0], cpu: cpu, memKb: memKb });
    }
    return list;
}

// Processes with the same name become one row, busiest first.
function group(list) {
    const groups = {};
    for (const p of list) {
        const g = groups[p.name] || (groups[p.name] = { name: p.name, count: 0, cpu: 0, memKb: 0 });
        g.count++;
        g.cpu += p.cpu;
        g.memKb += p.memKb;
    }
    return Object.keys(groups).map(k => groups[k]).sort((a, b) => b.cpu - a.cpu || b.memKb - a.memKb || a.name.localeCompare(b.name));
}

function memory(kb) {
    if (kb >= 1048576) return (kb / 1048576).toFixed(1) + " GB";
    if (kb >= 1024) return Math.round(kb / 1024) + " MB";
    return Math.round(kb) + " KB";
}

// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

// Parses `git status --porcelain=v2 --branch`.
function parseGit(text) {
    const status = { branch: "", ahead: 0, behind: 0, dirty: 0 };
    for (const line of String(text).split("\n")) {
        if (!line.length) continue;
        if (line.startsWith("# branch.head ")) status.branch = line.slice(14);
        else if (line.startsWith("# branch.ab ")) {
            const m = /\+(\d+) -(\d+)/.exec(line);
            if (m) { status.ahead = Number(m[1]); status.behind = Number(m[2]); }
        } else if (line[0] !== "#") status.dirty++;
    }
    return status;
}

// Parses /proc/net/tcp or tcp6 text into { host, port } listeners. State 0A is LISTEN.
function parseProcNet(text) {
    const listeners = [];
    for (const line of String(text).split("\n")) {
        const f = line.trim().split(/\s+/);
        if (f.length < 4 || f[3] !== "0A") continue;
        const parts = f[1].split(":");
        if (parts.length === 2) listeners.push({ host: parts[0].toUpperCase(), port: parseInt(parts[1], 16) });
    }
    return listeners;
}

// Addresses are kernel words in host byte order, so 127.0.0.1 reads 0100007F.
function isLocalOrAny(host) {
    if (host.length === 8) return host === "00000000" || host.endsWith("7F");
    return /^0+$/.test(host) || host === "00000000000000000000000001000000"
        || (host.startsWith("0000000000000000FFFF0000") && host.endsWith("7F"));
}

// Sorted, unique dev ports from any number of /proc/net texts.
function devPorts(texts, exclude) {
    const skip = exclude || [];
    const ports = new Set();
    for (const text of texts)
        for (const l of parseProcNet(text))
            if (isLocalOrAny(l.host) && l.port >= 1024 && l.port < 32768 && skip.indexOf(l.port) < 0) ports.add(l.port);
    return Array.from(ports).sort((a, b) => a - b);
}

// Parses /proc/net/dev into { rx, tx } byte totals. Skips loopback and virtual links, whose traffic
// also crosses a real interface and would count twice.
function parseNetDev(text) {
    const total = { rx: 0, tx: 0 };
    for (const line of String(text).split("\n")) {
        const m = /^\s*([^:\s]+):\s*(.*)$/.exec(line);
        if (!m || /^(lo|veth|docker|br-|virbr|podman|cni)/.test(m[1])) continue;
        const f = m[2].trim().split(/\s+/).map(Number);
        if (f.length < 9 || f.some(isNaN)) continue;
        total.rx += f[0];
        total.tx += f[8];
    }
    return total;
}

// Bytes per second -> at most four characters for the bar, such as 512K, 1.2M or 87M.
function shortRate(bytes) {
    const units = ["K", "M", "G", "T"];
    let value = Math.max(0, bytes) / 1024, unit = 0;
    while (Math.round(value) >= 1000 && unit < units.length - 1) { value /= 1024; unit++; }
    return (unit > 0 && value < 9.95 ? value.toFixed(1) : String(Math.round(value))) + units[unit];
}

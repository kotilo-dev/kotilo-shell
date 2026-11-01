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

// Parses `ss -ltnH` into sorted, unique dev ports.
function parseListeners(text, exclude) {
    const skip = exclude || [];
    const ports = new Set();
    for (const line of String(text).split("\n")) {
        const local = line.trim().split(/\s+/)[3];
        if (!local) continue;
        const i = local.lastIndexOf(":");
        const host = local.slice(0, i).replace(/%.*$/, "");
        const port = Number(local.slice(i + 1));
        const reachable = host === "*" || host === "0.0.0.0" || host === "[::]" || host === "[::1]" || host.startsWith("127.");
        if (reachable && port >= 1024 && port < 32768 && skip.indexOf(port) < 0) ports.add(port);
    }
    return Array.from(ports).sort((a, b) => a - b);
}

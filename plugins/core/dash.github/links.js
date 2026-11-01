// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

// A GitHub API address -> the page for it, or "" when it is not one.
function pageFor(apiUrl) {
    const m = /^https:\/\/api\.github\.com\/repos\/([^/]+\/[^/]+)(?:\/(pulls|issues|commits)\/([^/?#]+))?/.exec(String(apiUrl));
    if (!m) return "";
    const base = "https://github.com/" + m[1];
    if (!m[2]) return base;
    return base + "/" + { pulls: "pull", issues: "issues", commits: "commit" }[m[2]] + "/" + m[3];
}

function safe(url) {
    return typeof url === "string" && url.startsWith("https://github.com/");
}

// `gh api notifications` -> list rows.
function notificationRows(list) {
    return list.map(n => {
        const repo = n.repository || {}, subject = n.subject || {};
        return { title: String(subject.title || ""), detail: String(repo.full_name || ""), trailing: String(n.reason || "").replace(/_/g, " "),
                 url: pageFor(subject.url) || repo.html_url || "" };
    });
}

// A GitHub login -> its repositories page. The home page when the login does not look like one.
function repositoriesPage(login) {
    return typeof login === "string" && /^[A-Za-z0-9-]+$/.test(login) ? "https://github.com/" + login + "?tab=repositories" : "https://github.com/";
}

// An ISO date -> "now", "5m", "3h", "2d" or "4mo". "" when it is not a date.
function age(iso, now) {
    const then = Date.parse(iso);
    if (!isFinite(then)) return "";
    const minutes = Math.floor(Math.max(0, now - then) / 60000);
    if (minutes < 1) return "now";
    if (minutes < 60) return minutes + "m";
    if (minutes < 1440) return Math.floor(minutes / 60) + "h";
    if (minutes < 43200) return Math.floor(minutes / 1440) + "d";
    return Math.floor(minutes / 43200) + "mo";
}

function pullRows(list, now) {
    return list.map(p => ({ title: String(p.title || ""), url: p.url, trailing: age(p.updatedAt, now),
                            detail: (p.repository ? p.repository.nameWithOwner || p.repository.name || "" : "") + "#" + p.number }));
}

// A git remote address -> its GitHub page, or "" for anywhere else.
function remotePage(remote) {
    const m = /^(?:git@github\.com:|ssh:\/\/git@github\.com\/|https:\/\/github\.com\/)([^/\s]+\/[^/\s]+?)(?:\.git)?\/?$/.exec(String(remote).trim());
    return m ? "https://github.com/" + m[1] : "";
}

// Output of local-repos.sh -> list rows, the repositories that need attention first.
function localRows(text, home) {
    const repos = [];
    let repo = null;
    for (const line of String(text).split("\n")) {
        if (line.startsWith("### ")) {
            repo = { path: line.slice(4), branch: "", ahead: 0, behind: 0, dirty: 0, time: 0, remote: "" };
            repos.push(repo);
        } else if (!repo || !line.length) continue;
        else if (/^time( |$)/.test(line)) repo.time = Number(line.slice(5)) || 0;
        else if (/^remote( |$)/.test(line)) repo.remote = line.slice(7);
        else if (line.startsWith("# branch.head ")) repo.branch = line.slice(14);
        else if (line.startsWith("# branch.ab ")) {
            const m = /\+(\d+) -(\d+)/.exec(line);
            if (m) { repo.ahead = Number(m[1]); repo.behind = Number(m[2]); }
        } else if (line[0] !== "#") repo.dirty++;
    }
    const attention = r => r.dirty + r.ahead + r.behind > 0;
    return repos.sort((a, b) => attention(b) - attention(a) || b.time - a.time).map(r => {
        const state = [];
        if (r.dirty) state.push(r.dirty + " changed");
        if (r.ahead) state.push("↑" + r.ahead);
        if (r.behind) state.push("↓" + r.behind);
        const place = r.path.startsWith(home + "/") ? "~" + r.path.slice(home.length) : r.path;
        return { title: r.path.split("/").pop(), detail: (r.branch ? r.branch + "  " : "") + place, trailing: state.length ? state.join("  ") : "clean",
                 attention: attention(r), url: remotePage(r.remote) };
    });
}

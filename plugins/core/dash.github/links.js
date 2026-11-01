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

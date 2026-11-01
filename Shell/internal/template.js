// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

function lookup(tokens, path) {
    let value = tokens;
    for (const key of path.split(".")) {
        if (value === null || value === undefined) return undefined;
        value = value[key];
    }
    return value;
}

function rgb(hex) {
    const m = /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/i.exec(String(hex));
    if (!m) return undefined;
    return [m[1], m[2], m[3]].map(h => parseInt(h, 16)).join(",");
}

// {{bg.base}}, {{accent.primary.rgb}}, {{ansi.3}}, {{#isDark}}...{{/isDark}}, {{^isDark}}...{{/isDark}}.
// Throws on a missing token: a half-filled file must never replace a good one.
function render(template, tokens) {
    const data = Object.assign({}, tokens, { isDark: (tokens.variant || "dark") === "dark" });
    const sections = String(template).replace(/\{\{([#^])(\w+)\}\}([\s\S]*?)\{\{\/\2\}\}/g,
        (all, kind, name, body) => (!!data[name] === (kind === "#") ? body : ""));
    return sections.replace(/\{\{\s*([\w.]+)\s*\}\}/g, (all, path) => {
        let value = lookup(data, path);
        if (value === undefined && path.endsWith(".rgb")) value = rgb(lookup(data, path.slice(0, -4)));
        if (value === undefined || typeof value === "object") throw new Error("no token " + path);
        return String(value);
    });
}

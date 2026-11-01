// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

const states = ["running", "awaiting", "idle", "done"];
const maxField = 8192;

function isText(v, required) {
    return typeof v === "string" && v.length <= maxField && (!required || v.length > 0);
}

// One line from a client -> a clean message, or null when it is not valid (ADR-0003).
function parse(line) {
    let m;
    try { m = JSON.parse(line); } catch (e) { return null; }
    if (m === null || typeof m !== "object" || !isText(m.id, true) || m.id.length > 128) return null;
    if (m.type === "agent.status") {
        if (states.indexOf(m.state) < 0 || !isText(m.tool || "") || !isText(m.project || "")) return null;
        return { type: m.type, id: m.id, tool: m.tool || "", project: m.project || "", state: m.state,
                 since: typeof m.since === "number" ? m.since : 0 };
    }
    if (m.type === "agent.approval") {
        if (!isText(m.command, true) || !isText(m.cwd || "")) return null;
        return { type: m.type, id: m.id, command: m.command, cwd: m.cwd || "" };
    }
    return null;
}

function reply(id, allow) {
    return JSON.stringify({ type: "agent.approval.reply", id: id, allow: allow }) + "\n";
}

// Text for a person to judge: no terminal controls and no bidirectional tricks. Newlines stay.
function display(text) {
    return String(text).replace(/\t/g, "    ").replace(/[\u0000-\u0009\u000b-\u001f\u007f-\u009f\u200b-\u200f\u2028-\u202e\u2060-\u2069\ufeff]/g, "\ufffd");
}

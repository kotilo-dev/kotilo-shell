// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io

// Discovers plugins, validates manifests, checks apiVersion and exposes slot lists.
// Search order (later wins on id clash): plugins/core, $XDG_DATA_HOME/kotilo/shell/plugins, ~/.config/kotilo/shell/plugins
Item {
    id: root

    property var plugins: ({})          // id -> { manifest, dir, rank, component|null, enabled, error }
    property var slots: ({})            // slotName -> [plugin ids] (ordered by settings, then id)
    property bool ready: false
    property int pending: 0

    readonly property var searchDirs: [
        Quickshell.shellPath("plugins/core"),
        Shell.dataDir + "/plugins",
        Shell.configDir + "/plugins"
    ]

    // The single definition of a valid manifest, shared with scripts/validate-manifests.py.
    readonly property var schema: JSON.parse(schemaFile.text())

    FileView {
        id: schemaFile
        path: Quickshell.shellPath("plugins/schema/manifest.schema.json")
        blockLoading: true
    }

    // Settings decide which plugins mount and in what order, so scanning waits for them.
    readonly property bool settingsReady: Settings.ready
    onSettingsReadyChanged: if (settingsReady) scan()
    Component.onCompleted: if (settingsReady) scan()

    Connections {
        target: Settings
        function onChanged(pluginId, key) { if (root.ready) root.rebuild(); }
    }

    // -L follows plugin dirs that are symlinks. A missing search dir is normal: find still lists the others.
    Process {
        id: finder
        command: ["find", "-L"].concat(root.searchDirs).concat(["-maxdepth", "2", "-name", "manifest.json"])
        stdout: StdioCollector { id: finderOut }
        onExited: root.onManifestsListed(finderOut.text.trim().split("\n").filter(l => l.length))
    }

    function scan() { if (!finder.running) finder.running = true; }

    function onManifestsListed(paths) {
        Log.info(paths.length + " plugin manifest(s) found", "plugins");
        pending = paths.length;
        if (pending === 0) { rebuild(); return; }
        for (const p of paths) fileViewComp.createObject(root, { path: p, dir: p.substring(0, p.lastIndexOf("/")) });
    }

    Component {
        id: fileViewComp
        FileView {
            property string dir
            onLoaded: { root.register(dir, text()); root.manifestDone(); destroy(); }
            onLoadFailed: (err) => { Log.warn("cannot read " + path + ": " + FileViewError.toString(err), "plugins"); root.manifestDone(); destroy(); }
        }
    }

    function manifestDone() {
        pending--;
        if (pending === 0) rebuild();
    }

    function register(dir, json) {
        let m;
        try { m = JSON.parse(json); } catch (e) { disable({ dir: dir }, dir, "manifest.json is not valid JSON: " + e); return; }

        const entry = { manifest: m, dir: dir, rank: rankOf(dir), component: null, enabled: true, error: "" };
        const problems = validate(m);
        if (problems.length) {
            // Keyed by dir: an invalid plugin must not knock out a valid one with the same id.
            plugins[dir] = entry;
            disable(entry, dir, problems.join("; "));
            return;
        }
        if (!apiCompatible(m.apiVersion)) disable(entry, m.id, "needs API " + m.apiVersion + ", shell has " + Shell.apiVersion);

        // Manifests load asynchronously, so the search-dir rank decides a clash, not arrival order.
        const other = plugins[m.id];
        if (other && other.rank >= entry.rank) { Log.info(m.id + ": ignoring " + dir + ", overridden by " + other.dir, "plugins"); return; }
        if (other) Log.info(m.id + ": " + dir + " overrides " + other.dir, "plugins");
        plugins[m.id] = entry;
    }

    function rankOf(dir) {
        for (let i = searchDirs.length - 1; i >= 0; i--) if (dir.startsWith(searchDirs[i] + "/")) return i;
        return -1;
    }

    function disable(entry, label, reason) {
        entry.enabled = false;
        entry.error = reason;
        Log.warn(label + " disabled: " + reason, "plugins");
        Shell.notify({ summary: "Plugin disabled: " + label, body: reason, urgency: "normal" });
    }

    function validate(m) {
        if (m === null || typeof m !== "object" || Array.isArray(m)) return ["manifest is not an object"];
        const problems = [];
        for (const k of schema.required) if (m[k] === undefined) problems.push("missing " + k);
        for (const k in m) {
            if (!schema.properties[k]) problems.push("unknown field " + k);
            else checkValue(k, m[k], schema.properties[k], problems);
        }
        if (m.kind === "provider" && Array.isArray(m.slots)) {
            const allowed = schema.allOf[0].then.properties.slots.items.enum;
            for (const s of m.slots) if (!allowed.includes(s)) problems.push("slot " + s + " is not for providers");
        }
        return problems;
    }

    // The JSON Schema subset the manifest schema uses.
    function checkValue(name, v, rule, problems) {
        if (rule.type === "array" ? !Array.isArray(v) : (rule.type && typeof v !== rule.type)) { problems.push(name + " must be " + rule.type); return; }
        if (rule.enum && !rule.enum.includes(v)) problems.push(name + " has unknown value " + v);
        if (rule.pattern && !new RegExp(rule.pattern).test(v)) problems.push(name + " has invalid format");
        if (rule.minLength !== undefined && v.length < rule.minLength) problems.push(name + " is too short");
        if (rule.maxLength !== undefined && v.length > rule.maxLength) problems.push(name + " is too long");
        if (Array.isArray(v)) {
            if (rule.minItems !== undefined && v.length < rule.minItems) problems.push(name + " needs at least " + rule.minItems);
            if (rule.uniqueItems && new Set(v).size !== v.length) problems.push(name + " has duplicates");
            if (rule.items) for (const item of v) checkValue(name + " item", item, rule.items, problems);
        }
    }

    // Very small semver-range check: supports "^1.0", "~1.2", "1.x", exact. Expand when needed.
    function apiCompatible(range) {
        const api = Shell.apiVersion.split(".").map(Number);
        const m = /^([\^~]?)(\d+)(?:\.(\d+|x))?(?:\.(\d+|x))?$/.exec(String(range).trim());
        if (!m) return false;
        const major = Number(m[2]), minor = m[3] === undefined || m[3] === "x" ? null : Number(m[3]);
        if (api[0] !== major) return false;
        if (minor === null) return true;
        return m[1] === "^" ? api[1] >= minor : api[1] === minor;
    }

    function mountable(e) {
        if (!e.enabled || Settings.get(e.manifest.id, "enabled", true) === false) return false;
        if (e.manifest.kind === "script" || e.component) return true;
        // Files in the shell must load through Quickshell's own URL scheme: a file:// URL would give
        // them a second copy of every singleton. Plugins elsewhere get the real ones via qs.* imports.
        const inShell = e.dir.startsWith(Quickshell.shellDir);
        const url = inShell ? Qt.resolvedUrl("../" + e.dir.substring(Quickshell.shellDir.length).replace(/^\/+/, "") + "/Main.qml") : "file://" + e.dir + "/Main.qml";
        // Checked here, then mounted by URL: a Loader given a component takes ownership and destroys
        // it with itself, which would break the next mount.
        const c = Qt.createComponent(url);
        if (c.status === Component.Error) { disable(e, e.manifest.id, c.errorString().trim()); return false; }
        e.component = c;
        e.url = url;
        return true;
    }

    function rebuild() {
        const s = {};
        for (const id in plugins) {
            const e = plugins[id];
            if (!mountable(e)) continue;
            for (const slot of e.manifest.slots) { if (!s[slot]) s[slot] = []; s[slot].push(id); }
        }
        const configured = Settings.global.slots || {};
        const position = (order, id) => { const i = order.indexOf(id); return i < 0 ? order.length : i; };
        for (const slot in s) {
            const order = configured[slot] || [];
            s[slot].sort((a, b) => position(order, a) - position(order, b) || a.localeCompare(b));
        }
        // Unrelated settings changes must not remount every plugin.
        if (ready && JSON.stringify(s) === JSON.stringify(slots)) return;
        slots = s;
        ready = true;
        pluginsChanged();
        Log.info("plugins ready: " + Object.keys(s).sort().map(k => k + "=[" + s[k].join(",") + "]").join(" "), "plugins");
    }

    // Returns [{id, manifest, dir, component}] for a slot.
    function slot(name) {
        const ids = slots[name] || [];
        return ids.map(id => Object.assign({ id: id }, plugins[id]));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Theme engine: loads themes/<id>/tokens.json (bundled or user) and exposes tokens.
// Plugins must only use these properties — never literal colours.
Singleton {
    id: root

    property string schemeId: Settings.ready && Settings.global.theme ? Settings.global.theme.id : "catppuccin-mocha"
    property var tokens: ({})
    property bool ready: false
    property bool useBundled: false             // set when the theme has no user override
    signal changed()

    // ---- shorthands -------------------------------------------------------
    readonly property var bg:      tokens.bg      || ({ base: "#1e1e2e", mantle: "#181825", crust: "#11111b" })
    readonly property var surface: tokens.surface || ["#313244", "#45475a", "#585b70"]
    readonly property var text:    tokens.text    || ({ primary: "#cdd6f4", secondary: "#a6adc8", muted: "#6c7086", onAccent: "#11111b" })
    readonly property var accent:  tokens.accent  || ({ primary: "#89b4fa", secondary: "#cba6f7" })
    readonly property var state:   tokens.state   || ({ success: "#a6e3a1", warning: "#fab387", error: "#f38ba8", info: "#94e2d5" })
    readonly property var palette: tokens.palette || ({})
    readonly property var radius:  tokens.radius  || ({ sm: 6, md: 10, lg: 14 })
    readonly property var space:   tokens.space   || ({ xs: 4, sm: 8, md: 12, lg: 16, xl: 24 })
    readonly property var font:    tokens.font    || ({ ui: "Inter", mono: "JetBrains Mono", display: "Inter", size: 13 })
    readonly property bool isDark: (tokens.variant || "dark") === "dark"
    readonly property bool animations: Settings.ready && Settings.global.animations !== undefined ? Settings.global.animations : true
    readonly property int animMs: animations ? 180 : 0

    // ---- loading ----------------------------------------------------------
    // Resolution order: ~/.config/kotilo/shell/themes/<id>/tokens.json, then bundled themes/<id>/tokens.json
    readonly property string userPath: Shell.configDir + "/themes/" + schemeId + "/tokens.json"
    readonly property string bundledPath: Quickshell.shellPath("themes/" + schemeId + "/tokens.json")

    FileView {
        id: userFile
        path: root.userPath
        watchChanges: true
        printErrors: false                      // most themes have no user override
        onFileChanged: reload()
        onLoaded: { root.useBundled = false; root.apply(text(), "user"); }
        onLoadFailed: root.useBundled = true
    }

    FileView {
        id: bundledFile
        // Empty until needed: FileView loads as soon as it has a path, which would race the user file.
        path: root.useBundled ? root.bundledPath : ""
        watchChanges: Shell.devMode
        onFileChanged: reload()
        onLoaded: root.apply(text(), "bundled")
        onLoadFailed: (err) => Log.error("theme '" + root.schemeId + "' not found (" + FileViewError.toString(err) + ")", "theme")
    }

    // FileView cannot watch a file that does not exist, so look for a new override slowly.
    Timer {
        interval: 3000
        repeat: true
        running: root.useBundled
        onTriggered: userFile.reload()
    }

    onSchemeIdChanged: userFile.reload()

    function apply(json, origin) {
        try {
            tokens = JSON.parse(json);
            ready = true;
            changed();
            Log.info("theme '" + schemeId + "' loaded (" + origin + ")", "theme");
            // TODO(0.3): run theme.target providers to propagate to external apps
        } catch (e) {
            Log.error("tokens.json parse error: " + e, "theme");
        }
    }

    // Every theme with a tokens.json, as { id, bg, accent }. User themes replace bundled ones of the same id.
    property var schemes: []
    function scan() {
        Shell.run(["find", "-L", Quickshell.shellPath("themes"), Shell.configDir + "/themes", "-mindepth", "2", "-maxdepth", "2", "-name", "tokens.json"])
            .then(r => Promise.all(r.stdout.trim().split("\n").filter(l => l.length).map(path =>
                Shell.run(["cat", path]).then(c => {
                    const t = JSON.parse(c.stdout);
                    return { id: path.split("/").slice(-2)[0], bg: t.bg.base, accent: t.accent.primary };
                }))))
            .then(found => {
                const byId = {};
                for (const s of found) byId[s.id] = s;
                schemes = Object.keys(byId).sort().map(id => byId[id]);
            })
            .catch(e => Log.warn("theme scan failed: " + e, "theme"));
    }

    // Convenience for state classes used by script plugins: ok|warn|error|info|muted
    function stateColor(cls) {
        switch (cls) {
            case "ok": return state.success;
            case "warn": return state.warning;
            case "error": return state.error;
            case "info": return state.info;
            case "muted": return text.muted;
            default: return text.primary;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K

// Git repositories under the configured roots, most recently touched first.
Item {
    id: root
    property var plugin: null
    property string slot: ""
    readonly property string title: "Projects"
    property var paths: []
    property var tools: []                      // command names that exist on this system

    readonly property string home: Quickshell.env("HOME")
    readonly property string terminal: K.Settings.get("palette.projects", "terminal", "")
        || Quickshell.env("TERMINAL") || "xdg-terminal-exec"
    readonly property var commands: [
        { title: "Open in Neovim", tool: "nvim", argv: [terminal, "nvim", "."] },
        { title: "Open in VS Code", tool: "code", argv: ["code", "."] },
        { title: "Open terminal", tool: terminal, argv: [terminal] }
    ]

    Component.onCompleted: K.Shell.registerPaletteProvider(root)
    Component.onDestruction: K.Shell.unregisterPaletteProvider(root)

    Connections {
        target: K.Shell
        function onPaletteOpened() { root.scan(); }
    }

    function scan() {
        const roots = K.Settings.get("palette.projects", "roots", ["~/dev", "~/src", "~/projects", "~/code"])
            .map(r => r.replace(/^~(?=\/|$)/, home));
        K.Shell.run(["find", "-L"].concat(roots).concat(["-maxdepth", "4", "-name", ".git", "-prune", "-printf", "%T@ %h\n"]))
            .then(r => {
                root.paths = r.stdout.trim().split("\n").filter(l => l.length)
                    .map(l => { const i = l.indexOf(" "); return { time: Number(l.slice(0, i)), path: l.slice(i + 1) }; })
                    .sort((a, b) => b.time - a.time)
                    .map(p => p.path);
                K.Shell.paletteDataChanged();
            }).catch(e => K.Log.warn("project scan failed: " + e, "palette"));

        const names = commands.map(c => c.tool);
        K.Shell.run(["sh", "-c", 'for c do command -v "$c" >/dev/null && echo "$c"; done', "sh"].concat(names))
            .then(r => {
                root.tools = r.stdout.trim().split("\n");
                K.Shell.paletteDataChanged();
            }).catch(e => K.Log.warn("tool check failed: " + e, "palette"));
    }

    function items(query) {
        if (!query.length) return [];
        const available = commands.filter(c => tools.includes(c.tool));
        if (!available.length) return [];
        return paths.map(path => ({
            title: path.split("/").pop(),
            subtitle: path.replace(home, "~"),
            keywords: "project repo",
            actions: available.map(c => ({
                title: c.title,
                run: () => Quickshell.execDetached({ command: c.argv, workingDirectory: path })
            }))
        }));
    }
}

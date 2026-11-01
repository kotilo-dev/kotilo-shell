// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K

// Every theme with a tokens.json, bundled or under the user's themes folder.
Item {
    id: root
    property var plugin: null
    property string slot: ""
    readonly property string title: "Themes"
    property var ids: []

    Component.onCompleted: K.Shell.registerPaletteProvider(root)
    Component.onDestruction: K.Shell.unregisterPaletteProvider(root)

    Connections {
        target: K.Shell
        function onPaletteOpened() { root.scan(); }
    }

    function scan() {
        K.Shell.run(["find", "-L", Quickshell.shellPath("themes"), K.Shell.configDir + "/themes",
                     "-mindepth", "2", "-maxdepth", "2", "-name", "tokens.json"]).then(r => {
            const found = r.stdout.trim().split("\n").filter(l => l.length).map(l => l.split("/").slice(-2)[0]);
            root.ids = Array.from(new Set(found)).sort();
            K.Shell.paletteDataChanged();
        }).catch(e => K.Log.warn("theme scan failed: " + e, "palette"));
    }

    function label(id) {
        return id.split("-").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
    }

    // Listed only on request: six themes would crowd the empty palette.
    function items(query) {
        if (!query.length) return [];
        return ids.map(id => ({
            title: label(id),
            subtitle: id === K.Theme.schemeId ? "Current theme" : "",
            keywords: "theme colours colors " + id,
            actions: [{ title: "Use theme", run: () => K.Settings.setTheme(id) }]
        }));
    }
}

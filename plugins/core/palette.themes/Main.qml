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

    Component.onCompleted: K.Shell.registerPaletteProvider(root)
    Component.onDestruction: K.Shell.unregisterPaletteProvider(root)

    Connections {
        target: K.Theme
        function onSchemesChanged() { K.Shell.paletteDataChanged(); }
    }

    Connections {
        target: K.Shell
        function onPaletteOpened() { K.Theme.scan(); }
    }

    function label(id) {
        return id.split("-").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
    }

    // Listed only on request: six themes would crowd the empty palette.
    function items(query) {
        if (!query.length) return [];
        return K.Theme.schemes.map(s => s.id).map(id => ({
            title: label(id),
            subtitle: id === K.Theme.schemeId ? "Current theme" : "",
            keywords: "theme colours colors " + id,
            actions: [{ title: "Use theme", run: () => K.Settings.setTheme(id) }]
        }));
    }
}

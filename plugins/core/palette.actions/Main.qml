// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K

// Rows for Shell.registerPaletteAction. Listed once something is typed.
Item {
    id: root
    property var plugin: null
    property string slot: ""
    readonly property string title: "Actions"

    Component.onCompleted: K.Shell.registerPaletteProvider(root)
    Component.onDestruction: K.Shell.unregisterPaletteProvider(root)

    Connections {
        target: K.Shell
        function onPaletteActionsChanged() { K.Shell.paletteDataChanged(); }
    }

    function items(query) {
        if (!query.length) return [];
        return K.Shell.paletteActions.map(a => ({
            title: a.title,
            subtitle: a.pluginName,
            icon: a.icon,
            actions: [{ title: "Run", run: () => K.Shell.runPaletteAction(a) }]
        }));
    }
}

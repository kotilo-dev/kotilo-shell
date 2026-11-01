// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Shell as K
import qs.services as S

// Open windows, from the Wayland toplevel protocol. Focus goes through the adapter:
// Hyprland ignores a protocol activate unless misc:focus_on_activate is on.
Item {
    id: root
    property var plugin: null
    property string slot: ""
    readonly property string title: "Windows"
    readonly property int priority: 1           // on an empty query, windows list before apps

    Component.onCompleted: K.Shell.registerPaletteProvider(root)
    Component.onDestruction: K.Shell.unregisterPaletteProvider(root)

    Connections {
        target: ToplevelManager.toplevels
        function onValuesChanged() { K.Shell.paletteDataChanged(); }
    }

    function items(query) {
        return ToplevelManager.toplevels.values.map(t => {
            const entry = DesktopEntries.heuristicLookup(t.appId);
            return {
                title: t.title || t.appId,
                subtitle: t.appId,
                icon: entry ? entry.icon : "",
                keywords: t.appId,
                actions: [
                    { title: "Focus", run: () => S.Workspaces.focusToplevel(t) },
                    { title: "Close", run: () => t.close() }
                ]
            };
        });
    }
}

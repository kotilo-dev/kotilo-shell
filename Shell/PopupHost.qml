// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services" as S

// Hosts Shell.openPopup: a plugin's QML file, placed under the item that asked. Esc or a click
// outside closes it.
Item {
    id: host
    property var current: null                  // { url, x, y }

    function urlFor(plugin, file) {
        if (!plugin || !plugin.url || !/^[A-Za-z0-9_-]+\.qml$/.test(file)) return "";
        return plugin.url.toString().replace(/Main\.qml$/, file);
    }

    Connections {
        target: Shell
        function onOpenPopupRequested(plugin, file, anchorItem) {
            const url = host.urlFor(plugin, file);
            if (!url.length) { Log.warn("refused popup file " + file, "popup"); return; }
            if (host.current && host.current.url === url) { host.current = null; return; }
            const p = anchorItem ? anchorItem.mapToItem(null, 0, anchorItem.height) : Qt.point(0, 0);
            host.current = { url: url, x: p.x, y: p.y };
        }
        function onClosePopupsRequested() { host.current = null; }
    }

    LazyLoader {
        active: host.current !== null

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === S.Workspaces.focusedOutput) || null
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kotilo-popup"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            MouseArea { anchors.fill: parent; onClicked: host.current = null }

            Loader {
                id: content
                focus: true
                source: host.current ? host.current.url : ""
                x: host.current ? Math.max(Theme.space.sm, Math.min(host.current.x, parent.width - width - Theme.space.sm)) : 0
                y: host.current ? Math.min(host.current.y + Theme.space.xs, parent.height - height - Theme.space.sm) : 0
                Component.onCompleted: forceActiveFocus()
                Keys.onEscapePressed: host.current = null
                onStatusChanged: if (status === Loader.Error) { Log.warn("popup failed to load", "popup"); host.current = null; }
                MouseArea { anchors.fill: parent; z: -1 }
            }
        }
    }
}

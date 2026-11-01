// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K

// Installed desktop entries. Tab lists the entry's own desktop actions (New Window, …).
Item {
    id: root
    property var plugin: null
    property string slot: ""
    readonly property string title: "Apps"

    Component.onCompleted: K.Shell.registerPaletteProvider(root)
    Component.onDestruction: K.Shell.unregisterPaletteProvider(root)

    // Entries load one by one after the first read, so rows can arrive while the palette is open.
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { K.Shell.paletteDataChanged(); }
    }

    function items(query) {
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay)
            .map(e => ({
                title: e.name,
                subtitle: e.comment || e.genericName,
                icon: e.icon,
                keywords: [e.genericName].concat(e.keywords).join(" "),
                actions: root.actionsFor(e)
            }));
    }

    // Entry objects can be replaced while rows are held, so actions look the entry up again by id.
    function actionsFor(entry) {
        const id = entry.id;
        const list = [{ title: "Open", run: () => DesktopEntries.byId(id).execute() }];
        entry.actions.forEach((action, i) => list.push({
            title: action.name,
            run: () => DesktopEntries.byId(id).actions[i].execute()
        }));
        return list;
    }
}

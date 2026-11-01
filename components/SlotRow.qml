// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../Shell" as K

// Mounts every enabled plugin of a slot in a Row. Script plugins get a ScriptWidget.
// A hidden plugin takes no space. Plugins with the same manifest barGroup sit close together,
// with a wider gap between groups; one with no group stands alone.
Row {
    id: row
    required property string slotName
    required property var host
    property var screen: null
    readonly property int itemGap: K.Theme.space.xs
    readonly property int groupGap: K.Theme.space.lg

    function arrange() {
        let previous = null;
        for (let i = 0; i < cells.count; i++) {
            const cell = cells.itemAt(i);
            if (!cell || !cell.shown) continue;
            cell.gap = previous === null ? 0 : (previous === cell.group ? itemGap : groupGap);
            previous = cell.group;
        }
    }

    Repeater {
        id: cells
        model: row.host.ready ? row.host.slot(row.slotName) : []
        onItemAdded: row.arrange()

        delegate: Item {
            id: cell
            required property var modelData
            property int gap: 0
            readonly property bool shown: !!loader.item && loader.item.visible
            readonly property string group: modelData.manifest.barGroup || modelData.id
            onShownChanged: row.arrange()
            anchors.verticalCenter: parent.verticalCenter
            width: shown ? gap + loader.width : 0
            height: loader.height

            Loader {
                id: loader
                x: cell.gap
                Component.onCompleted: {
                    if (cell.modelData.manifest.kind === "script") sourceComponent = scriptComp;
                    else source = cell.modelData.url;
                }
                onLoaded: {
                    if (item.hasOwnProperty("plugin")) item.plugin = cell.modelData;
                    if (item.hasOwnProperty("slot")) item.slot = row.slotName;
                    if (item.hasOwnProperty("screen")) item.screen = row.screen;
                    if (item.hasOwnProperty("host")) item.host = row.host;
                }
                onStatusChanged: if (status === Loader.Error) K.Log.error("failed to mount " + cell.modelData.id + " in " + row.slotName, "slot")
            }
        }
    }

    Component { id: scriptComp; ScriptWidget {} }
}

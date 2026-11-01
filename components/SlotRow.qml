// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../Shell" as K

// Mounts every enabled plugin of a slot in a Row. Script plugins get a ScriptWidget.
Row {
    id: row
    required property string slotName
    required property var host
    property var screen: null
    spacing: K.Theme.space.md

    Repeater {
        model: row.host.ready ? row.host.slot(row.slotName) : []
        delegate: Loader {
            required property var modelData
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: modelData.manifest.kind === "script" ? scriptComp : modelData.component
            onLoaded: {
                if (item.hasOwnProperty("plugin")) item.plugin = modelData;
                if (item.hasOwnProperty("slot")) item.slot = row.slotName;
                if (item.hasOwnProperty("screen")) item.screen = row.screen;
                if (item.hasOwnProperty("host")) item.host = row.host;
            }
            onStatusChanged: if (status === Loader.Error) K.Log.error("failed to mount " + modelData.id + " in " + row.slotName, "slot")
        }
    }

    Component { id: scriptComp; ScriptWidget {} }
}

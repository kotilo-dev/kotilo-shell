// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

Row {
    id: root
    property var plugin: null
    property string slot: ""
    readonly property int max: K.Settings.get("bar.ports", "max", 3)
    readonly property int hidden: Math.max(0, S.Ports.list.length - max)
    spacing: K.Theme.space.xs
    visible: S.Ports.list.length > 0

    C.Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: "network"
        size: K.Theme.barSize(16)
        color: K.Theme.text.secondary
    }

    Repeater {
        model: S.Ports.list.slice(0, root.max)

        delegate: C.Pill {
            required property int modelData
            anchors.verticalCenter: parent.verticalCenter
            text: String(modelData)
            onClicked: S.Ports.open(modelData)
        }
    }

    C.Label {
        font.pixelSize: K.Theme.barFontSize
        anchors.verticalCenter: parent.verticalCenter
        visible: root.hidden > 0
        secondary: true
        mono: true
        text: "+" + root.hidden
    }
}

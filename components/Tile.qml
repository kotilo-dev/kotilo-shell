// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../Shell" as K

// Control center tile (ADR-0009). The panel handles selection and calls activate().
Rectangle {
    id: tile
    property var plugin: null
    property string slot: ""
    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property bool active: false
    property bool available: true
    property bool selected: false
    signal activated()
    function activate() { if (available) activated(); }

    readonly property color fg: active ? K.Theme.text.onAccent : K.Theme.text.primary
    implicitWidth: 120
    implicitHeight: 76
    radius: K.Theme.radius.md
    color: active ? K.Theme.accent.primary : K.Theme.surface[0]
    Behavior on color { ColorAnimation { duration: K.Theme.animMs } }

    // Outside the tile, so it shows on a lit tile as well as an unlit one.
    Rectangle {
        anchors { fill: parent; margins: -3 }
        visible: tile.selected
        color: "transparent"
        radius: tile.radius + 3
        border.width: 2
        border.color: K.Theme.text.primary
    }

    Column {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: K.Theme.space.md }
        spacing: K.Theme.space.xs

        Icon { name: tile.icon; size: 16; color: tile.fg }
        Label { width: parent.width; elide: Text.ElideRight; color: tile.fg; text: tile.title }
        Label {
            width: parent.width
            elide: Text.ElideRight
            color: tile.fg
            font.pixelSize: K.Theme.font.size - 2
            font.weight: Font.Normal
            text: tile.available ? tile.subtitle : "Unavailable"
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: tile.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: tile.activate()
    }
}

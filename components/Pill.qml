// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import "../Shell" as K

// Standard bar chip: optional icon + text, optional accent fill, click + hover.
Rectangle {
    id: pill
    property var plugin: null
    property string slot: ""
    property string icon: ""
    property string text: ""
    property string tooltip: ""
    property bool active: false
    property color accent: K.Theme.accent.primary
    property color fg: active ? K.Theme.text.onAccent : K.Theme.text.primary
    property bool mono: true
    default property alias extras: content.data     // placed after the text
    signal clicked()
    signal rightClicked()

    activeFocusOnTab: true
    Keys.onPressed: event => {
        const action = K.Shell.barKey(event, pill);
        if (action === "activate") pill.clicked();
        else if (action === "menu") pill.rightClicked();
    }
    onActiveFocusChanged: if (!activeFocus && !mouse.containsMouse) tipShown = false

    FocusRing { visible: pill.activeFocus }

    implicitHeight: 26
    implicitWidth: content.implicitWidth + K.Theme.space.md * 2
    radius: K.Theme.radius.sm
    color: active ? accent : (mouse.containsMouse ? K.Theme.surface[0] : "transparent")
    Behavior on color { ColorAnimation { duration: K.Theme.animMs } }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6
        Icon { name: pill.icon; visible: pill.icon.length > 0; color: pill.active ? pill.fg : pill.accent; size: 13; anchors.verticalCenter: parent.verticalCenter }
        Label { text: pill.text; visible: pill.text.length > 0; color: pill.fg; mono: pill.mono; anchors.verticalCenter: parent.verticalCenter }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (e) => e.button === Qt.RightButton ? pill.rightClicked() : pill.clicked()
    }

    Timer { id: hoverDelay; interval: 600; running: (mouse.containsMouse || pill.activeFocus) && pill.tooltip.length > 0 }
    property bool tipShown: false
    Connections {
        target: hoverDelay
        function onTriggered() { pill.tipShown = true; }
    }
    Connections {
        target: mouse
        function onContainsMouseChanged() { if (!mouse.containsMouse && !pill.activeFocus) pill.tipShown = false; }
    }

    LazyLoader {
        active: pill.tipShown

        PopupWindow {
            anchor.item: pill
            anchor.rect.y: pill.height + K.Theme.space.xs
            implicitWidth: tipLabel.implicitWidth + 2 * K.Theme.space.md
            implicitHeight: tipLabel.implicitHeight + 2 * K.Theme.space.sm
            color: "transparent"
            visible: true

            Surface {
                anchors.fill: parent
                level: 1
                Label { id: tipLabel; anchors.centerIn: parent; textFormat: Text.PlainText; text: pill.tooltip }
            }
        }
    }
}

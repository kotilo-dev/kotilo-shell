import QtQuick
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
    signal clicked()
    signal rightClicked()

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
        // TODO(0.2): tooltip popup via Shell.openPopup after hover delay
    }
}

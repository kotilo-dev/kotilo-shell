// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Card {
    id: card
    title: S.Mpris.ready ? S.Mpris.player.identity : "Media"
    readonly property var player: S.Mpris.player
    readonly property bool hasLength: !!player && player.lengthSupported && player.length > 0

    component Control: Rectangle {
        id: control
        property string icon: ""
        signal activated()
        width: 36; height: 36
        radius: K.Theme.radius.sm
        color: "transparent"
        activeFocusOnTab: true
        Keys.onPressed: event => {
            if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter) return;
            control.activated();
            event.accepted = true;
        }
        C.StateLayer { hovered: controlMouse.containsMouse; pressed: controlMouse.pressed }
        C.FocusRing { visible: control.activeFocus }
        C.Icon { anchors.centerIn: parent; name: control.icon; size: 18; color: K.Theme.text.primary }
        MouseArea { id: controlMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: control.activated() }
    }

    Row {
        width: parent.width
        spacing: K.Theme.space.md
        visible: S.Mpris.ready

        Image {
            id: art
            width: 64; height: 64
            visible: source.toString().length > 0 && status !== Image.Error
            source: card.player ? card.player.trackArtUrl : ""
            sourceSize: Qt.size(128, 128)
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - (art.visible ? art.width + parent.spacing : 0)

            C.Label { width: parent.width; elide: Text.ElideRight; textFormat: Text.PlainText; text: card.player ? (card.player.trackTitle || "Unknown track") : "" }
            C.Label { width: parent.width; elide: Text.ElideRight; secondary: true; textFormat: Text.PlainText; text: card.player ? card.player.trackArtist : "" }
        }
    }

    Rectangle {
        id: track
        width: parent.width
        height: 4
        radius: 2
        visible: card.hasLength
        color: K.Theme.surface[0]

        Rectangle {
            id: fill
            height: parent.height
            radius: parent.radius
            color: K.Theme.text.secondary
            width: card.hasLength ? Math.min(1, card.player.position / card.player.length) * parent.width : 0
        }
        // MPRIS does not announce position, so it is read while a track plays and the card exists.
        Timer {
            interval: 1000
            repeat: true
            running: track.visible && card.player.isPlaying
            onTriggered: card.player.positionChanged()
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: S.Mpris.ready
        spacing: K.Theme.space.sm
        Control { icon: "media-previous"; onActivated: S.Mpris.previous() }
        Control { icon: S.Mpris.ready && S.Mpris.player.isPlaying ? "media-pause" : "media-play"; onActivated: S.Mpris.toggle() }
        Control { icon: "media-next"; onActivated: S.Mpris.next() }
    }

    C.Label { visible: !S.Mpris.ready; secondary: true; text: "Nothing is playing" }
}

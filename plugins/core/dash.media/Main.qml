// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell.Io
import Quickshell.Widgets
import qs.Shell as K
import qs.services as S
import qs.components as C

// Artwork, track and controls, over a live audio spectrum. Cava runs only while something plays
// and the dashboard is open. Without cava the bars stay flat.
C.Card {
    id: card
    readonly property var area: ({ x: 0.76, y: 0, w: 0.24, h: 1 })
    readonly property var player: S.Mpris.player
    readonly property bool playing: !!player && player.isPlaying
    readonly property bool hasLength: !!player && player.lengthSupported && player.length > 0
    readonly property int barCount: 16
    property var levels: []

    Process {
        running: !!card.plugin && card.playing
        command: ["cava", "-p", card.plugin ? card.plugin.dir + "/cava.conf" : ""]
        stdout: SplitParser {
            onRead: line => { card.levels = line.split(";").slice(0, card.barCount).map(Number); }
        }
        onRunningChanged: if (!running) card.levels = []
    }

    component Control: Rectangle {
        id: control
        property string icon: ""
        signal activated()
        width: 30; height: 30
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
        C.Icon { anchors.centerIn: parent; name: control.icon; size: 16; color: K.Theme.text.primary }
        MouseArea { id: controlMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: control.activated() }
    }

    Item {
        width: parent.width
        height: card.height - 2 * K.Theme.space.md

        // Rings around the artwork, as in a record sleeve.
        Item {
            id: disc
            anchors.horizontalCenter: parent.horizontalCenter
            y: K.Theme.space.sm
            width: Math.min(parent.width, 132); height: width

            Repeater {
                model: [1, 0.86]
                delegate: Rectangle {
                    required property var modelData
                    anchors.centerIn: parent
                    width: disc.width * modelData; height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: K.Theme.surface[0]
                }
            }
            ClippingRectangle {
                anchors.centerIn: parent
                width: disc.width * 0.72; height: width
                radius: width / 2
                color: K.Theme.bg.mantle

                C.Icon {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    name: "image"
                    size: 32
                    color: K.Theme.text.secondary
                }
                Image {
                    id: art
                    anchors.fill: parent
                    source: card.player ? card.player.trackArtUrl : ""
                    sourceSize: Qt.size(192, 192)
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                }
            }
        }

        Column {
            id: track
            anchors { top: disc.bottom; left: parent.left; right: parent.right; topMargin: K.Theme.space.md }
            spacing: K.Theme.space.xs

            C.Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; color: K.Theme.accent.primary; textFormat: Text.PlainText; text: card.player && card.player.trackTitle ? card.player.trackTitle : "No media" }
            C.Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; secondary: true; font.pixelSize: K.Theme.font.size - 1; textFormat: Text.PlainText; text: card.player && card.player.trackAlbum ? card.player.trackAlbum : "No media" }
            C.Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; secondary: true; font.pixelSize: K.Theme.font.size - 1; textFormat: Text.PlainText; text: card.player && card.player.trackArtist ? card.player.trackArtist : "No media" }
        }

        Row {
            id: controls
            anchors { top: track.bottom; horizontalCenter: parent.horizontalCenter; topMargin: K.Theme.space.sm }
            spacing: K.Theme.space.sm
            Control { icon: "media-previous"; onActivated: S.Mpris.previous() }
            Control { icon: card.playing ? "media-pause" : "media-play"; onActivated: S.Mpris.toggle() }
            Control { icon: "media-next"; onActivated: S.Mpris.next() }
        }

        Row {
            anchors { top: controls.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; topMargin: K.Theme.space.sm }
            spacing: 2

            Repeater {
                model: card.barCount
                delegate: Item {
                    required property int index
                    width: (parent.width - (card.barCount - 1) * parent.spacing) / card.barCount
                    height: parent.height

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(3, (card.levels[parent.index] || 0) / 100 * parent.height)
                        radius: width / 2
                        color: K.Theme.accent.primary
                        Behavior on height { NumberAnimation { duration: 50 } }
                    }
                }
            }
        }
    }

    // MPRIS does not announce position, so it is read while a track plays and the card exists.
    Timer {
        interval: 1000
        repeat: true
        running: card.playing && card.hasLength
        onTriggered: card.player.positionChanged()
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Card {
    id: card
    readonly property var area: ({ x: 0, y: 0, w: 0.3, h: 0.36 })
    property string system: "Linux"
    property string uptime: ""
    // A local picture from Settings. Without a usable one the card shows an icon.
    readonly property string image: {
        const path = K.Settings.get("dash.system", "image", "").replace(/^~(?=\/|$)/, Quickshell.env("HOME"));
        return path.startsWith("/") ? "file://" + encodeURI(path) : "";
    }

    FileView {
        path: "/etc/os-release"
        printErrors: false
        onLoaded: {
            const m = /^PRETTY_NAME="?([^"\n]+)"?/m.exec(text());
            if (m) card.system = m[1];
        }
    }

    function readUptime(text) {
        const seconds = Math.floor(Number(text.split(" ")[0]));
        if (!isFinite(seconds)) return;
        const days = Math.floor(seconds / 86400), hours = Math.floor(seconds % 86400 / 3600), minutes = Math.floor(seconds % 3600 / 60);
        uptime = "up " + (days ? days + "d " + hours + "h" : hours ? hours + "h " + minutes + "m" : minutes + "m");
    }
    FileView { id: up; path: "/proc/uptime"; printErrors: false; onLoaded: card.readUptime(text()) }
    Timer { interval: 60000; repeat: true; running: true; onTriggered: up.reload() }

    component Line: Row {
        id: line
        property string icon: ""
        property string text: ""
        width: parent.width
        spacing: K.Theme.space.sm
        C.Icon { anchors.verticalCenter: parent.verticalCenter; name: line.icon; size: 15; color: K.Theme.accent.primary }
        C.Label { anchors.verticalCenter: parent.verticalCenter; width: parent.width - 23; elide: Text.ElideRight; textFormat: Text.PlainText; text: line.text }
    }

    Row {
        width: parent.width
        height: card.height - 2 * K.Theme.space.md
        spacing: K.Theme.space.md

        ClippingRectangle {
            id: frame
            width: Math.round(height * 0.62)
            height: parent.height
            radius: K.Theme.radius.md
            color: K.Theme.surface[0]

            C.Icon { anchors.centerIn: parent; visible: photo.status !== Image.Ready; name: "user"; size: 30; color: K.Theme.text.primary }
            Image {
                id: photo
                anchors.fill: parent
                source: card.image
                sourceSize: Qt.size(frame.width * 3, frame.height * 3)
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - frame.width - parent.spacing
            spacing: K.Theme.space.sm

            Line { icon: "kotilo"; text: card.system }
            Line { icon: "windows"; text: S.Workspaces.compositor.charAt(0).toUpperCase() + S.Workspaces.compositor.slice(1) }
            Line { icon: "clock"; text: card.uptime }
        }
    }
}

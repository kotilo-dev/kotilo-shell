// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Card {
    id: card
    readonly property var area: ({ x: 0.36, y: 0, w: 0.40, h: 0.27 })
    centered: true
    property string system: "Linux"
    property string uptime: ""

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
        const unit = (n, name) => n + " " + name + (n === 1 ? "" : "s");
        uptime = "up " + (days ? unit(days, "day") + ", " + unit(hours, "hour") : hours ? unit(hours, "hour") + ", " + unit(minutes, "minute") : unit(minutes, "minute"));
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
        spacing: K.Theme.space.lg

        Rectangle {
            id: avatar
            anchors.verticalCenter: parent.verticalCenter
            width: 56; height: 56
            radius: K.Theme.radius.lg
            color: K.Theme.surface[0]
            C.Icon { anchors.centerIn: parent; name: "user"; size: 28; color: K.Theme.text.primary }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - avatar.width - parent.spacing
            spacing: K.Theme.space.xs

            Line { icon: "kotilo"; text: card.system }
            Line { icon: "windows"; text: S.Workspaces.compositor.charAt(0).toUpperCase() + S.Workspaces.compositor.slice(1) }
            Line { icon: "clock"; text: card.uptime }
            Line { visible: S.Focus.completed > 0; icon: "cpu"; text: S.Focus.completed + " focus sessions" }
        }
    }
}

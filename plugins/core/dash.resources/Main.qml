// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Card {
    id: card
    readonly property var area: ({ x: 0.64, y: 0.27, w: 0.12, h: 0.73 })
    property int disk: 0

    Component.onCompleted: K.Shell.run(["df", "--output=pcent", "/"]).then(r => {
        const m = /(\d+)%/.exec(r.stdout);
        if (m) card.disk = Number(m[1]);
    }, () => {})

    component Meter: Column {
        id: meter
        property real value: 0
        property string icon: ""
        property string label: ""
        property color tint: K.Theme.accent.primary
        width: parent.width / 3
        height: parent.height
        spacing: K.Theme.space.sm

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 10
            height: parent.height - 16 - parent.spacing
            radius: width / 2
            color: K.Theme.surface[0]

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Math.max(width, Math.min(1, meter.value / 100) * parent.height)
                radius: width / 2
                color: meter.tint
                Behavior on height { NumberAnimation { duration: K.Theme.animMs; easing.type: Easing.OutCubic } }
            }
        }
        C.Icon { anchors.horizontalCenter: parent.horizontalCenter; name: meter.icon; size: 16; color: meter.tint }
    }

    Row {
        width: parent.width
        height: card.height - 2 * K.Theme.space.md
        Meter { icon: "cpu"; value: S.Resources.cpu }
        Meter { icon: "memory"; value: S.Resources.ram; tint: K.Theme.accent.secondary }
        Meter { icon: "disk"; value: card.disk }
    }
}

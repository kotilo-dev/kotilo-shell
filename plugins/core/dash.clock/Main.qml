// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K
import qs.components as C

// The time, stacked.
C.Card {
    id: card
    readonly property var area: ({ x: 0, y: 0.27, w: 0.14, h: 0.73 })

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Item {
        width: parent.width
        height: card.height - 2 * K.Theme.space.md

        Column {
            anchors.centerIn: parent
            spacing: K.Theme.space.xs

            C.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: K.Theme.font.size + 19
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
                text: Qt.formatTime(clock.date, "HH")
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: K.Theme.space.xs
                Repeater {
                    model: 3
                    delegate: Rectangle { width: 6; height: 6; radius: 3; color: K.Theme.accent.primary }
                }
            }
            C.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: K.Theme.font.size + 19
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
                text: Qt.formatTime(clock.date, "mm")
            }
            C.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                color: K.Theme.accent.primary
                font.weight: Font.DemiBold
                text: Qt.formatDate(clock.date, "ddd")
            }
        }
    }
}

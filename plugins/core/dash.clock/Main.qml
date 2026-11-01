// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K
import qs.components as C

C.Card {
    title: Qt.formatDate(clock.date, "dddd")

    SystemClock { id: clock; precision: SystemClock.Minutes }

    C.Label {
        font.pixelSize: K.Theme.font.size + 23
        font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
        text: Qt.formatTime(clock.date, "HH:mm")
    }
    C.Label {
        secondary: true
        text: Qt.formatDate(clock.date, "d MMMM yyyy")
    }
}

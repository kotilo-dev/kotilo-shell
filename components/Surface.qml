// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../Shell" as K

// Level 0: a floating panel with a shadow and hairline. Level 1: a tonal card inside one, with a
// border only when a caller gives it meaning.
Rectangle {
    id: surface
    property int level: 0
    property bool shadow: level === 0           // off where the window has no room around the panel
    color: level === 0 ? K.Theme.bg.mantle : K.Theme.bg.base
    border.color: K.Theme.surface[0]
    border.width: level === 0 ? 1 : 0
    radius: level === 0 ? K.Theme.radius.lg : K.Theme.radius.md

    Loader {
        anchors.fill: parent
        z: -1
        active: surface.shadow
        source: "PanelShadow.qml"
    }
}

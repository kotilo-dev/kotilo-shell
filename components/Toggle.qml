// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../Shell" as K

// On or off, shown as a switch. The parent handles input and keyboard.
Rectangle {
    id: toggle
    property bool checked: false
    width: 30
    height: 18
    radius: height / 2
    color: checked ? K.Theme.accent.primary : K.Theme.surface[1]
    Behavior on color { ColorAnimation { duration: K.Theme.fastMs } }

    Rectangle {
        x: toggle.checked ? toggle.width - width - 2 : 2
        y: 2
        width: toggle.height - 4
        height: width
        radius: width / 2
        color: toggle.checked ? K.Theme.text.onAccent : K.Theme.text.secondary
        Behavior on x { NumberAnimation { duration: K.Theme.fastMs; easing.type: Easing.OutCubic } }
    }
}

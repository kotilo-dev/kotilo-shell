// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../Shell" as K

// Keyboard selection mark. Outside its parent, so it shows on lit and unlit items alike.
Rectangle {
    anchors { fill: parent; margins: -2 }
    color: "transparent"
    radius: K.Theme.radius.sm + 2
    border.width: 2
    border.color: K.Theme.text.primary
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../Shell" as K

// The one hover and press treatment (ADR-0016). Goes first in its parent, under the content.
Rectangle {
    property bool hovered: false
    property bool pressed: false
    anchors.fill: parent
    radius: parent.radius
    color: K.Theme.text.primary
    opacity: pressed ? 0.12 : (hovered ? 0.08 : 0)
    Behavior on opacity { NumberAnimation { duration: K.Theme.fastMs } }
}

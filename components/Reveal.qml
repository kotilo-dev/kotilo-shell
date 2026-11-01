// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../Shell" as K

// Open and close motion for a panel (ADR-0016). A panel stays alive while it leaves, but must use
// `open`, not `alive`, for its keyboard and input: nothing may act on a panel that is closing.
Item {
    id: reveal
    property bool open: false
    property real progress: open ? 1 : 0
    readonly property bool alive: open || progress > 0
    visible: false

    Behavior on progress {
        NumberAnimation {
            duration: reveal.open ? K.Theme.animMs : K.Theme.fastMs
            easing.type: reveal.open ? Easing.OutCubic : Easing.InCubic
        }
    }
}

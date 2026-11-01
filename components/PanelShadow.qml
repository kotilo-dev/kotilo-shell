// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Effects
import "../Shell" as K

// Needs Qt 6.9. Surface loads this file with a Loader, and it stays out of qmldir, so that older Qt
// loses the shadow and not the whole shell (ADR-0016).
RectangularShadow {
    anchors.fill: parent
    offset.y: 8
    blur: 32
    radius: K.Theme.radius.lg
    color: Qt.alpha(K.Theme.bg.crust, 0.55)
}

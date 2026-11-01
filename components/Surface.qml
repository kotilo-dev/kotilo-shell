// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../Shell" as K

// Floating panel surface: mantle background, hairline border, radius. Used by popups/panels.
Rectangle {
    property int level: 0            // 0 panel, 1 card inside panel
    color: level === 0 ? K.Theme.bg.mantle : K.Theme.bg.base
    border.color: K.Theme.surface[level === 0 ? 1 : 0]
    border.width: 1
    radius: level === 0 ? K.Theme.radius.lg : K.Theme.radius.md
    // Shadows: use a layer effect in 0.2 (MultiEffect); kept flat for performance in 0.1.
}

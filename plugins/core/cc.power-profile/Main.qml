// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.services as S
import qs.components as C

C.Tile {
    title: "Power"
    icon: "battery-charging"
    available: S.Power.ready
    subtitle: S.Power.label()
    onActivated: S.Power.cycle()
}

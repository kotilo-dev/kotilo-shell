// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.services as S
import qs.components as C

C.Tile {
    title: "Focus"
    icon: "clock"
    active: S.Focus.active
    subtitle: !active ? "Off" : (S.Focus.phase === "work" ? S.Focus.clock : "Break " + S.Focus.clock)
    onActivated: S.Focus.toggle()
}

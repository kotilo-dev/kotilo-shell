// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.services as S
import qs.components as C

C.Tile {
    title: "Bluetooth"
    icon: S.Bluetooth.icon()
    available: S.Bluetooth.ready
    active: S.Bluetooth.enabled
    subtitle: S.Bluetooth.connected.length ? S.Bluetooth.connected[0].name : (active ? "On" : "Off")
    onActivated: S.Bluetooth.toggle()
}

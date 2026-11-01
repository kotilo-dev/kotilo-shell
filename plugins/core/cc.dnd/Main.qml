// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.services as S
import qs.components as C

C.Tile {
    title: "Do not disturb"
    icon: "bell"
    active: S.Notifications.doNotDisturb
    subtitle: active ? "On" : "Off"
    onActivated: S.Notifications.toggleDoNotDisturb()
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.services as S
import qs.components as C

C.Tile {
    title: "Wi-Fi"
    icon: S.Network.wifiEnabled ? "wifi" : "wifi-off"
    available: S.Network.wifiAvailable
    active: S.Network.wifiEnabled
    subtitle: S.Network.wifi ? S.Network.wifi.name : (active ? "Not connected" : "Off")
    onActivated: S.Network.toggleWifi()
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking as Qs

// Network facade over Quickshell's Networking service. Wired wins when both are connected.
// The import is qualified because this file's name would shadow the module's Network type.
Singleton {
    id: net
    readonly property bool ready: Qs.Networking.backend !== Qs.NetworkBackendType.None
    readonly property string error: ready ? "" : "no network backend (needs NetworkManager)"

    readonly property var devices: ready ? Qs.Networking.devices.values : []
    readonly property var wired: devices.find(d => d.type === Qs.DeviceType.Wired && d.connected) || null
    readonly property var wifiDevice: devices.find(d => d.type === Qs.DeviceType.Wifi) || null
    readonly property var wifi: wifiDevice ? (wifiDevice.networks.values.find(n => n.connected) || null) : null

    readonly property bool connected: wired !== null || wifi !== null
    readonly property string kind: wired ? "wired" : (wifi ? "wifi" : "none")
    readonly property string name: wired ? wired.name : (wifi ? wifi.name : "")
    readonly property int signal: wifi ? Math.round(wifi.signalStrength * 100) : 0
    // Connected to a network, but the shell knows it does not reach the internet.
    readonly property bool limited: connected && (Qs.Networking.connectivity === Qs.NetworkConnectivity.None
        || Qs.Networking.connectivity === Qs.NetworkConnectivity.Limited
        || Qs.Networking.connectivity === Qs.NetworkConnectivity.Portal)

    function icon() { return kind === "wired" ? "network" : (kind === "wifi" ? "wifi" : "wifi-off"); }
}

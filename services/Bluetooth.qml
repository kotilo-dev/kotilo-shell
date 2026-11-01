// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth as Qs

// Bluetooth facade. The import is qualified because this file's name would shadow the singleton.
Singleton {
    id: bt
    readonly property var adapter: Qs.Bluetooth.defaultAdapter
    readonly property bool ready: adapter !== null
    readonly property string error: ready ? "" : "no Bluetooth adapter"

    readonly property bool enabled: ready && adapter.enabled
    readonly property var connected: ready ? adapter.devices.values.filter(d => d.connected) : []

    function toggle() { if (ready) adapter.enabled = !adapter.enabled; }
    function icon() { return enabled ? "bluetooth" : "bluetooth-off"; }
}

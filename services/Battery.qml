pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../Shell" as K

// Battery/power facade over Quickshell's UPower service. Degrades gracefully on desktops.
Singleton {
    id: bat
    readonly property var dev: UPower.displayDevice
    readonly property bool ready: dev !== null && dev.isLaptopBattery
    readonly property string error: ready ? "" : "no battery"
    readonly property int percent: ready ? Math.round(dev.percentage * 100) : 0
    readonly property bool charging: ready && dev.state === UPowerDeviceState.Charging
    readonly property bool low: ready && !charging && percent <= (K.Settings.get("bar.battery", "lowAt", 15))
    readonly property string timeToEmpty: ready && dev.timeToEmpty > 0 ? fmt(dev.timeToEmpty) : ""
    readonly property string timeToFull: ready && dev.timeToFull > 0 ? fmt(dev.timeToFull) : ""

    function fmt(sec) { const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60); return (h ? h + "h " : "") + m + "m"; }
    function stateClass() { return charging ? "ok" : (low ? "error" : (percent < 40 ? "warn" : "ok")); }
}

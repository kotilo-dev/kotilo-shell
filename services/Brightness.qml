// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Shell" as K

// Laptop backlight through sysfs, set with brightnessctl. External monitors (DDC) are not covered.
// sysfs sends no change events for this file, so it is polled.
Singleton {
    id: br
    property string device: ""
    property int max: 0
    property int value: 0
    property bool checked: false

    readonly property bool ready: device.length > 0 && max > 0
    readonly property string error: checked && !ready ? "no backlight device" : ""
    readonly property int percent: ready ? Math.round(100 * value / max) : 0
    readonly property string dir: device.length ? "/sys/class/backlight/" + device : ""

    Component.onCompleted: K.Shell.run(["sh", "-c", "ls /sys/class/backlight 2>/dev/null | head -n 1"]).then(r => {
        device = r.stdout.trim();
        checked = true;
    }, e => { checked = true; K.Log.warn("backlight detection failed: " + e, "brightness"); })

    FileView {
        path: br.dir.length ? br.dir + "/max_brightness" : ""
        printErrors: false
        onLoaded: br.max = parseInt(text())
    }

    FileView {
        id: current
        path: br.dir.length ? br.dir + "/brightness" : ""
        printErrors: false
        onLoaded: br.value = parseInt(text())
    }

    Timer {
        interval: 500
        repeat: true
        running: br.ready
        onTriggered: current.reload()
    }

    function setPercent(p) {
        if (!ready) return;
        K.Shell.run(["brightnessctl", "-d", device, "set", Math.max(1, Math.min(100, Math.round(p))) + "%"])
            .catch(e => K.Log.warn("set failed: " + e, "brightness"));
    }
    function step(delta) { setPercent(percent + delta); }
}

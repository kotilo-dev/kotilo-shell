// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Shell" as K

// CPU and memory use, read from /proc. Reads are asynchronous so they never block the UI thread.
Singleton {
    id: res
    property bool ready: false
    property string error: ""
    property int cpu: 0                 // percent, across all cores
    property int ram: 0                 // percent, MemAvailable counts as free
    property real ramUsedGb: 0
    property var _last: null

    FileView {
        id: stat
        path: "/proc/stat"
        printErrors: false
        onLoaded: res.readCpu(text())
        onLoadFailed: res.error = "/proc/stat is not readable"
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        printErrors: false
        onLoaded: res.readMem(text())
        onLoadFailed: res.error = "/proc/meminfo is not readable"
    }

    Timer {
        interval: Math.max(1, K.Settings.get("bar.resources", "interval", 3)) * 1000
        repeat: true
        running: res.error.length === 0
        onTriggered: { stat.reload(); meminfo.reload(); }
    }

    function readCpu(text) {
        const f = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        const idle = f[3] + f[4];       // idle + iowait
        const total = f.reduce((a, b) => a + b, 0);
        if (_last && total > _last.total) cpu = Math.round(100 * (1 - (idle - _last.idle) / (total - _last.total)));
        _last = { idle: idle, total: total };
    }

    function readMem(text) {
        const kb = key => Number((new RegExp("^" + key + ":\\s+(\\d+)", "m").exec(text) || [0, 0])[1]);
        const total = kb("MemTotal"), available = kb("MemAvailable");
        if (total === 0) { error = "/proc/meminfo has no MemTotal"; return; }
        ram = Math.round(100 * (1 - available / total));
        ramUsedGb = (total - available) / 1048576;
        ready = true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import "../Shell" as K

// Read-only notification count from an already running daemon. Never registers on D-Bus: see docs/adr/0007.
Singleton {
    id: notif
    property var backend: null
    property int count: 0
    property bool checked: false

    readonly property bool ready: backend !== null
    readonly property string error: checked && !ready ? "no supported notification daemon (swaync, dunst, mako)" : ""

    readonly property var backends: ({
        "swaync-client": { count: ["swaync-client", "-c"], open: ["swaync-client", "-t"], parse: o => parseInt(o) },
        "dunstctl": { count: ["dunstctl", "count", "history"], open: ["dunstctl", "history-pop"], parse: o => parseInt(o) },
        "makoctl": { count: ["makoctl", "history"], open: ["makoctl", "restore"], parse: o => (o.match(/^Notification /gm) || []).length }
    })

    // Through sh: a Process for a missing binary logs a warning.
    Component.onCompleted: K.Shell.run(["sh", "-c", "for c in " + Object.keys(backends).join(" ") + "; do command -v \"$c\" >/dev/null && { echo \"$c\"; exit; }; done"]).then(r => {
        backend = backends[r.stdout.trim()] || null;
        checked = true;
        refresh();
    }, e => { checked = true; K.Log.warn("daemon detection failed: " + e, "notifications"); })

    Timer {
        interval: 5000
        repeat: true
        running: notif.ready
        onTriggered: notif.refresh()
    }

    function refresh() {
        if (!backend) return;
        K.Shell.run(backend.count).then(r => {
            const n = backend.parse(r.stdout);
            count = r.code === 0 && n >= 0 ? n : 0;
        }, e => K.Log.debug("count failed: " + e, "notifications"));
    }

    function open() { if (backend) K.Shell.run(backend.open); }
}

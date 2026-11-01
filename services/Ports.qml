// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import "../Shell" as K
import "devstatus.js" as Dev

// Listening dev ports from `ss` (ADR-0010).
Singleton {
    id: ports
    property var list: []
    property bool ready: false
    property string error: ""

    function poll() {
        K.Shell.run(["sh", "-c", "command -v ss >/dev/null && ss -ltnH"]).then(r => {
            ready = r.code === 0;
            error = ready ? "" : "ss not found";
            const next = ready ? Dev.parseListeners(r.stdout, K.Settings.get("bar.ports", "exclude", [])) : [];
            if (JSON.stringify(next) !== JSON.stringify(list)) list = next;
        }, e => K.Log.debug("poll failed: " + e, "ports"));
    }

    Component.onCompleted: poll()
    Timer { interval: 5000; repeat: true; running: true; onTriggered: ports.poll() }

    function open(port) { Quickshell.execDetached(["xdg-open", "http://localhost:" + port]); }
}

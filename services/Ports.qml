// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Shell" as K
import "devstatus.js" as Dev

// Listening dev ports, read from /proc so polling starts no process (ADR-0010).
Singleton {
    id: ports
    property var list: []
    property bool ready: false
    readonly property string error: ready ? "" : "cannot read /proc/net/tcp"

    FileView { id: tcp; path: "/proc/net/tcp"; onLoaded: ports.update() }
    FileView { id: tcp6; path: "/proc/net/tcp6"; printErrors: false; onLoaded: ports.update() }

    function update() {
        ready = true;
        const next = Dev.devPorts([tcp.text(), tcp6.loaded ? tcp6.text() : ""], K.Settings.get("bar.ports", "exclude", []));
        if (JSON.stringify(next) !== JSON.stringify(list)) list = next;
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: { tcp.reload(); tcp6.reload(); }
    }

    function open(port) { Quickshell.execDetached(["xdg-open", "http://localhost:" + port]); }
}

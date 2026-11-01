// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import "../Shell" as K

// Running containers across podman and docker (ADR-0010). `podman ps` is the costliest thing the
// shell polls, so this runs rarely, and the tools are found once. A podman-docker shim counts once.
Singleton {
    id: containers
    property int count: 0
    property var tools: []
    readonly property bool ready: tools.length > 0
    readonly property string error: ready ? "" : "no podman or docker"

    readonly property string detect: 'command -v podman >/dev/null && echo podman
command -v docker >/dev/null && ! docker --version 2>/dev/null | grep -qi podman && echo docker
exit 0'
    readonly property string count_: 'n=0; for c do n=$((n + $("$c" ps -q 2>/dev/null | wc -l))); done; echo "$n"'

    function poll() {
        if (!ready) return;
        K.Shell.run(["sh", "-c", count_, "sh"].concat(tools), { timeout: 10000 })
            .then(r => count = parseInt(r.stdout) || 0, e => K.Log.debug("poll failed: " + e, "containers"));
    }

    Component.onCompleted: K.Shell.run(["sh", "-c", detect]).then(r => {
        tools = r.stdout.trim().split("\n").filter(l => l.length);
        poll();
    }, e => K.Log.debug("detection failed: " + e, "containers"))

    Timer { interval: 120000; repeat: true; running: containers.ready; onTriggered: containers.poll() }
}

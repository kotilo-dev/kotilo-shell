// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import "../Shell" as K

// Running containers across podman and docker. A podman-docker shim counts once (ADR-0010).
Singleton {
    id: containers
    property int count: 0
    property bool ready: false
    readonly property string error: ready ? "" : "no podman or docker"

    readonly property string script: 'found=1; n=0
for c in podman docker; do
  command -v "$c" >/dev/null || continue
  [ "$c" = docker ] && docker --version 2>/dev/null | grep -qi podman && continue
  found=0
  n=$((n + $("$c" ps -q 2>/dev/null | wc -l)))
done
echo "$n"; exit $found'

    function poll() {
        K.Shell.run(["sh", "-c", script], { timeout: 10000 }).then(r => {
            ready = r.code === 0;
            count = ready ? parseInt(r.stdout) || 0 : 0;
        }, e => K.Log.debug("poll failed: " + e, "containers"));
    }

    Component.onCompleted: poll()
    Timer { interval: 15000; repeat: true; running: true; onTriggered: containers.poll() }
}

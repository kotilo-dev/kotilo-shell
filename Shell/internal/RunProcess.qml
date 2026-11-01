// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io

// Transient process wrapper used by Shell.run(). Not for direct use by plugins.
Scope {
    id: root
    property list<string> argv
    property string cwd
    property int timeoutMs: 5000

    signal finished(var result)
    signal failed(string error)

    function start() {
        if (!argv || argv.length === 0) { failed("empty argv"); return; }
        proc.command = argv;
        if (cwd.length) proc.workingDirectory = cwd;
        killer.start();
        proc.running = true;
    }

    Process {
        id: proc
        stdout: StdioCollector { id: outCol }
        stderr: StdioCollector { id: errCol }
        onExited: (code, status) => {
            killer.stop();
            root.finished({ stdout: outCol.text, stderr: errCol.text, code: code });
        }
    }

    Timer {
        id: killer
        interval: root.timeoutMs
        repeat: false
        onTriggered: {
            // Not-running here means the command failed to start: Process then never emits exited.
            if (proc.running) proc.signal(9);
            root.failed("timeout after " + root.timeoutMs + "ms: " + root.argv.join(" "));
        }
    }
}

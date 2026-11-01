// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell.Io
import "../Shell" as K

// Renders a `kind: "script"` plugin: runs widget.json's exec on an interval and shows the JSON result.
Pill {
    id: w
    mono: true

    property var spec: ({})          // parsed widget.json
    property var last: ({})          // last parsed output
    property string error: ""

    text: error.length ? "!" : (last.text || "")
    icon: last.icon || spec.icon || ""
    tooltip: error.length ? error : (last.tooltip || "")
    accent: K.Theme.stateColor(last["class"] || "info")

    onPluginChanged: if (plugin) loadSpec()
    onClicked: if (spec.onClick) K.Shell.run(spec.onClick)

    // Optional meter from the script's `percentage`.
    Rectangle {
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: K.Theme.space.sm }
        visible: typeof w.last.percentage === "number"
        width: (w.width - 2 * K.Theme.space.sm) * Math.max(0, Math.min(100, w.last.percentage || 0)) / 100
        height: 2
        radius: 1
        color: w.accent
    }

    // Script actions join the palette, replaced on each run.
    function publishActions() {
        K.Shell.unregisterPaletteActions(plugin);
        for (const a of last.actions || [])
            if (a.label && Array.isArray(a.exec)) K.Shell.registerPaletteAction(plugin, { title: a.label, icon: a.icon || "", exec: a.exec });
    }
    Component.onDestruction: if (plugin) K.Shell.unregisterPaletteActions(plugin)

    function loadSpec() {
        specFile.path = plugin.dir + "/widget.json";
        specFile.reload();
    }

    FileView {
        id: specFile
        onLoaded: {
            try { w.spec = JSON.parse(text()); w.error = ""; tick.interval = (w.spec.interval || 30) * 1000; tick.start(); proc.running = true; }
            catch (e) { w.error = "widget.json: " + e; K.Log.error(w.error, w.plugin.id); }
        }
        onLoadFailed: (err) => { w.error = "widget.json missing"; K.Log.error(w.error, w.plugin ? w.plugin.id : "script"); }
    }

    Timer { id: tick; repeat: true; onTriggered: if (!proc.running) proc.running = true }

    // A stuck script must not hold the widget forever: tick skips while it runs.
    Timer {
        interval: (w.spec.timeout || 10) * 1000
        running: proc.running
        onTriggered: { w.error = "timed out"; proc.signal(15); }
    }

    Process {
        id: proc
        command: w.spec.exec || ["true"]
        stdout: StdioCollector { id: out }
        onExited: (code) => {
            const t = out.text.trim();
            if (code !== 0) { if (w.error !== "timed out") w.error = "exit " + code; return; }
            if ((w.spec.format || "json") === "text") { w.last = { text: t }; w.error = ""; return; }
            try { w.last = JSON.parse(t); w.error = ""; w.publishActions(); } catch (e) { w.error = "bad JSON from " + w.plugin.id; }
        }
    }
}

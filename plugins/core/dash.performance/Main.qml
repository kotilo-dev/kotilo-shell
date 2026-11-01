// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C
import "processes.js" as Proc
import "system.js" as Sys

// A task manager: resources on the left, the chosen one on the right. Everything here is read only
// while this tab is showing, and top only while Processes is chosen.
Item {
    id: tab
    property var plugin: null
    property string slot: ""
    property bool current: false
    readonly property string title: "System"
    readonly property int historySize: 90

    property var machine: null
    property var previous: null
    property real sampledAt: 0
    property real diskRead: 0
    property real diskWrite: 0
    property real netDown: 0
    property real netUp: 0
    property var diskHistory: []
    property var netHistory: []
    property var gpuHistory: ({})                // gpu index -> recent usage
    property bool sampling: false

    property var groups: []
    property string status: "Reading processes…"
    property bool reading: false
    property int selected: 0

    function pushed(list, value) { return list.slice(1 - historySize).concat([value]); }

    function sample() {
        if (sampling) return;
        sampling = true;
        const chosen = items[selected];
        const nvidia = !!chosen && !!chosen.gpu && chosen.gpu.driver === "nvidia";
        K.Shell.run(["sh", plugin.dir + "/sample.sh", nvidia ? "nvidia" : ""], { timeout: 6000 }).then(r => {
            sampling = false;
            const now = Date.now(), next = Sys.parse(r.stdout);
            if (previous) {
                const seconds = (now - sampledAt) / 1000;
                diskRead = Sys.rate(previous.disk.read, next.disk.read, seconds);
                diskWrite = Sys.rate(previous.disk.written, next.disk.written, seconds);
                const total = m => m.net.reduce((sum, i) => ({ rx: sum.rx + i.rx, tx: sum.tx + i.tx }), { rx: 0, tx: 0 });
                const a = total(previous), b = total(next);
                netDown = Sys.rate(a.rx, b.rx, seconds);
                netUp = Sys.rate(a.tx, b.tx, seconds);
                diskHistory = pushed(diskHistory, diskRead + diskWrite);
                netHistory = pushed(netHistory, netDown + netUp);
            }
            const histories = Object.assign({}, gpuHistory);
            next.gpus.forEach((g, i) => { if (g.busy !== null) histories[i] = pushed(histories[i] || [], g.busy); });
            gpuHistory = histories;
            previous = next;
            sampledAt = now;
            machine = next;
        }, () => { sampling = false; });
    }

    function readProcesses() {
        if (reading) return;
        reading = true;
        K.Shell.run(["env", "LC_ALL=C", "top", "-b", "-n", "2", "-d", "1", "-w", "512", "-e", "k"], { timeout: 6000 }).then(r => {
            reading = false;
            groups = Proc.group(Proc.parseTop(r.stdout));
            status = groups.length ? "" : "top returned nothing readable.";
        }, () => { reading = false; status = "Could not run top."; });
    }

    readonly property bool onProcesses: !!items[selected] && items[selected].key === "processes"
    onCurrentChanged: if (current) sample()
    onOnProcessesChanged: if (onProcesses) readProcesses()
    Timer { interval: 2000; repeat: true; running: tab.current; onTriggered: tab.sample() }
    Timer { interval: 3000; repeat: true; running: tab.current && tab.onProcesses; onTriggered: tab.readProcesses() }

    function key(event) {
        const count = items.length;
        if (event.key === Qt.Key_Down) selected = (selected + 1) % count;
        else if (event.key === Qt.Key_Up) selected = (selected - 1 + count) % count;
        else if (event.key === Qt.Key_PageDown && onProcesses) for (let i = 0; i < 8; i++) processes.step(1);
        else if (event.key === Qt.Key_PageUp && onProcesses) for (let i = 0; i < 8; i++) processes.step(-1);
        else return false;
        return true;
    }

    function pair(label, value) { return { label: label, value: value }; }

    readonly property var items: {
        const m = machine;
        const memory = m ? m.memory : { total: 0, available: 0, cached: 0, swapTotal: 0, swapUsed: 0 };
        const used = (memory.total - memory.available) * 1024;
        const list = [{
            key: "cpu", title: "CPU", heading: m ? m.cpuModel : "CPU", value: S.Resources.cpu + "%", history: S.Resources.history, unit: "100%",
            stats: m ? [pair("Usage", S.Resources.cpu + "%"), pair("Speed", (m.cpuMhz / 1000).toFixed(2) + " GHz"), pair("Cores", String(m.cores)),
                        pair("Temperature", m.cpuTemperature !== null ? m.cpuTemperature + " °C" : "not available"), pair("Load average", m.load), pair("Up", Sys.duration(m.uptime))] : []
        }, {
            key: "memory", title: "Memory", heading: "Memory", value: S.Resources.ramUsedGb.toFixed(1) + " GB", history: S.Resources.ramHistory, unit: "100%",
            stats: [pair("In use", Sys.bytes(used)), pair("Available", Sys.bytes(memory.available * 1024)), pair("Total", Sys.bytes(memory.total * 1024)),
                    pair("Cached", Sys.bytes(memory.cached * 1024)), pair("Swap in use", memory.swapTotal ? Sys.bytes(memory.swapUsed * 1024) : "no swap")]
        }, {
            key: "disk", title: "Disk", heading: "Disk", value: Sys.bytes(diskRead + diskWrite) + "/s", history: Sys.scaled(diskHistory), unit: "recent peak",
            stats: [pair("Read", Sys.bytes(diskRead) + "/s"), pair("Write", Sys.bytes(diskWrite) + "/s")]
                .concat(m && m.diskTemperature !== null ? [pair("Temperature", m.diskTemperature + " °C")] : [])
                .concat(m ? m.filesystems.map(f => pair(f.mount, Sys.bytes(f.used) + " of " + Sys.bytes(f.size))) : [])
        }, {
            key: "network", title: "Network", heading: m ? (m.net.filter(i => i.state === "up").map(i => i.name).join(", ") || "Not connected") : "Network",
            value: "↓" + Sys.bytes(netDown) + "/s", history: Sys.scaled(netHistory), unit: "recent peak",
            stats: [pair("Download", Sys.bytes(netDown) + "/s"), pair("Upload", Sys.bytes(netUp) + "/s")]
                .concat(m ? m.net.map(i => pair(i.name, i.state === "up" ? "↓ " + Sys.bytes(i.rx) + "   ↑ " + Sys.bytes(i.tx) + " in total" : "Not connected")) : [])
        }];
        (m ? m.gpus : []).forEach((g, i) => {
            const usage = g.asleep ? "Asleep" : g.busy !== null ? g.busy + "%" : g.frequency !== null ? g.frequency + " MHz" : g.driver === "nvidia" ? "Select to read" : "Not available";
            const stats = [pair("State", g.asleep ? "Asleep, saving power" : "Awake")];
            if (g.busy !== null) stats.push(pair("Usage", g.busy + "%"));
            else if (!g.asleep && g.driver === "nvidia") stats.push(pair("Usage", "Reading…"));
            else if (!g.asleep && g.driver === "i915") stats.push(pair("Usage", "needs root to read"));
            if (g.frequency !== null) stats.push(pair("Speed", g.frequency + (g.maxFrequency ? " of " + g.maxFrequency : "") + " MHz"));
            if (g.memoryTotal) stats.push(pair("Memory", Sys.bytes(g.memoryUsed) + " of " + Sys.bytes(g.memoryTotal)));
            if (g.temperature !== null) stats.push(pair("Temperature", g.temperature + " °C"));
            list.push({ key: "gpu" + i, title: "GPU " + i, heading: g.name, value: usage, history: gpuHistory[i] || [], unit: "100%", gpu: g, stats: stats });
        });
        list.push({ key: "processes", title: "Processes", heading: "Processes", value: groups.length ? groups.length + " groups" : "", history: [], stats: [] });
        return list;
    }
    readonly property var chosen: items[Math.min(selected, items.length - 1)]

    Column {
        id: side
        width: 190
        height: parent.height
        spacing: 2

        Repeater {
            model: tab.items

            delegate: Rectangle {
                id: entry
                required property var modelData
                required property int index
                width: side.width
                height: 52
                radius: K.Theme.radius.sm
                color: index === tab.selected ? K.Theme.surface[0] : "transparent"

                C.StateLayer { hovered: mouse.containsMouse; pressed: mouse.pressed }

                Rectangle {
                    visible: entry.index === tab.selected
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    width: 3
                    height: 26
                    radius: 1.5
                    color: K.Theme.accent.primary
                }
                Column {
                    anchors { left: parent.left; right: mini.left; leftMargin: K.Theme.space.md; rightMargin: K.Theme.space.sm; verticalCenter: parent.verticalCenter }
                    C.Label { width: parent.width; elide: Text.ElideRight; textFormat: Text.PlainText; text: entry.modelData.title }
                    C.Label { width: parent.width; elide: Text.ElideRight; secondary: true; font.pixelSize: K.Theme.font.size - 2; font.features: { "tnum": 1 }; textFormat: Text.PlainText; text: entry.modelData.value }
                }
                C.Sparkline {
                    id: mini
                    anchors { right: parent.right; rightMargin: K.Theme.space.sm; verticalCenter: parent.verticalCenter }
                    visible: entry.modelData.key !== "processes"
                    count: 20
                    barWidth: 2
                    height: 26
                    linear: true
                    values: entry.modelData.history
                    color: K.Theme.accent.primary
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: tab.selected = entry.index
                }
            }
        }
    }

    Item {
        anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom; leftMargin: K.Theme.space.md }

        C.Label {
            id: heading
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: K.Theme.font.size + 3
            font.weight: Font.DemiBold
            textFormat: Text.PlainText
            text: tab.chosen ? tab.chosen.heading : ""
        }

        Item {
            anchors { top: heading.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; topMargin: K.Theme.space.sm }
            visible: !tab.onProcesses

            Rectangle {
                id: graphFrame
                width: parent.width
                height: 170
                radius: K.Theme.radius.md
                color: K.Theme.bg.base
                border.width: 1
                border.color: K.Theme.surface[0]

                C.Sparkline {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: K.Theme.space.sm }
                    height: parent.height - 2 * K.Theme.space.sm
                    barWidth: 4
                    track: false
                    count: Math.max(0, Math.floor((parent.width - 2 * K.Theme.space.sm + 1) / (barWidth + 1)))
                    linear: true
                    values: tab.chosen ? tab.chosen.history : []
                    color: K.Theme.accent.primary
                }
                C.Label {
                    anchors.centerIn: parent
                    visible: !!tab.chosen && tab.chosen.history.length === 0
                    secondary: true
                    text: tab.chosen && tab.chosen.gpu ? "No usage to graph" : "Collecting…"
                }
                C.Label {
                    anchors { top: parent.top; right: parent.right; margins: K.Theme.space.sm }
                    secondary: true
                    font.pixelSize: K.Theme.font.size - 3
                    textFormat: Text.PlainText
                    text: tab.chosen && tab.chosen.unit ? tab.chosen.unit : ""
                }
            }

            Flickable {
                anchors { top: graphFrame.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; topMargin: K.Theme.space.md }
                clip: true
                contentHeight: stats.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Grid {
                    id: stats
                    width: parent.width
                    columns: 2
                    columnSpacing: K.Theme.space.lg
                    rowSpacing: K.Theme.space.sm

                    Repeater {
                        model: tab.chosen ? tab.chosen.stats : []

                        delegate: Column {
                            required property var modelData
                            width: (stats.width - stats.columnSpacing) / 2

                            C.Label { width: parent.width; elide: Text.ElideRight; secondary: true; font.pixelSize: K.Theme.font.size - 2; textFormat: Text.PlainText; text: modelData.label }
                            C.Label { width: parent.width; elide: Text.ElideRight; font.features: { "tnum": 1 }; textFormat: Text.PlainText; text: modelData.value }
                        }
                    }
                }
            }
        }

        C.PickList {
            id: processes
            anchors { top: heading.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; topMargin: K.Theme.space.sm }
            visible: tab.onProcesses
            empty: tab.status
            rows: tab.groups.map(g => ({
                title: g.count > 1 ? g.name + "  ×" + g.count : g.name,
                trailing: g.cpu.toFixed(1) + "%  " + Proc.memory(g.memKb)
            }))
        }
    }
}

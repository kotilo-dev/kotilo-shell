// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C
import "processes.js" as Proc

// Runs top only while this tab is showing.
Item {
    id: tab
    property var plugin: null
    property string slot: ""
    property bool current: false
    readonly property string title: "Performance"
    property var groups: []
    property string status: "Reading processes…"
    property bool reading: false

    function key(event) { return list.key(event); }

    function read() {
        if (reading) return;
        reading = true;
        K.Shell.run(["env", "LC_ALL=C", "top", "-b", "-n", "2", "-d", "1", "-w", "512", "-e", "k"], { timeout: 6000 }).then(r => {
            tab.reading = false;
            tab.groups = Proc.group(Proc.parseTop(r.stdout));
            tab.status = tab.groups.length ? "" : "top returned nothing readable.";
        }, () => { tab.reading = false; tab.status = "Could not run top."; });
    }

    onCurrentChanged: if (current) read()
    Timer { interval: 3000; repeat: true; running: tab.current; onTriggered: tab.read() }

    component Meter: C.Card {
        id: meter
        property string value: ""
        property var history: []
        width: (row.width - row.spacing) / 2

        C.Label { font.pixelSize: K.Theme.font.size + 6; text: meter.value }
        C.Sparkline {
            count: Math.max(0, Math.floor((parent.width + 1) / (barWidth + 1)))
            barWidth: 5
            height: 44
            linear: true
            values: meter.history
        }
    }

    Row {
        id: row
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: K.Theme.space.md
        Meter { title: "CPU"; value: S.Resources.cpu + "%"; history: S.Resources.history }
        Meter { title: "Memory"; value: S.Resources.ramUsedGb.toFixed(1) + " GB, " + S.Resources.ram + "%"; history: S.Resources.ramHistory }
    }

    C.PickList {
        id: list
        anchors { top: row.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; topMargin: K.Theme.space.md }
        empty: tab.status
        rows: tab.groups.map(g => ({
            title: g.count > 1 ? g.name + "  ×" + g.count : g.name,
            trailing: g.cpu.toFixed(1) + "%  " + Proc.memory(g.memKb)
        }))
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

// Shows agents and what they are waiting for. Answers stay in the agents panel, the one place
// with the safety rules of ADR-0003: this tab can only open it.
Item {
    id: tab
    property var plugin: null
    property string slot: ""
    property bool current: false
    readonly property string title: "Agents"

    function key(event) { return list.key(event); }

    function openPanel() {
        K.Shell.dashboardClosed();
        K.Shell.toggleAgents();
    }

    C.PickList {
        id: list
        anchors.fill: parent
        empty: "No agents are running."
        onChosen: tab.openPanel()
        rows: {
            const waiting = S.Agents.approvals.map(a => ({
                title: a.command.split("\n")[0],
                detail: a.cwd,
                trailing: "open to answer"
            }));
            const running = S.Agents.agents.map(a => ({
                title: a.tool + (a.project ? " · " + a.project : ""),
                trailing: a.state
            }));
            return (waiting.length ? [{ heading: "Waiting for approval" }].concat(waiting) : [])
                .concat(running.length ? [{ heading: "Agents" }].concat(running) : []);
        }
    }
}

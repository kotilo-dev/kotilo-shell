// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Shell" as K
import "agentprotocol.js" as Protocol

// Running agents and their approval requests, over the agent socket (ADR-0003).
Singleton {
    id: ag
    property var agents: []                     // { id, tool, project, state, since, updated }
    property var approvals: []                  // { id, agent, command, cwd, connection }

    readonly property string socketPath: Quickshell.env("KOTILO_AGENT_SOCKET") || K.Shell.runtimeDir + "/kotilo-agents.sock"
    readonly property bool ready: server.active
    readonly property string error: ready ? "" : "agent socket is not listening"
    readonly property int active: agents.filter(a => a.state === "running" || a.state === "awaiting").length

    SocketServer {
        id: server
        active: true
        path: ag.socketPath
        handler: Component {
            Socket {
                id: connection
                parser: SplitParser { onRead: line => ag.handle(line, connection) }
                onConnectedChanged: if (!connected) ag.dropConnection(connection)
            }
        }
    }

    function handle(line, connection) {
        const m = Protocol.parse(line);
        if (!m) { K.Log.warn("dropped an invalid agent message", "agents"); return; }
        if (m.type === "agent.status") updateAgent(m);
        else if (approvals.some(a => a.id === m.id)) K.Log.warn("dropped a repeated approval id", "agents");
        else approvals = approvals.concat([{ id: m.id, agent: m.agent || m.id, command: Protocol.display(m.command), cwd: Protocol.display(m.cwd), connection: connection }]);
    }

    function updateAgent(m) {
        const next = { id: m.id, tool: Protocol.display(m.tool), project: Protocol.display(m.project), state: m.state, since: m.since, updated: Date.now() };
        agents = agents.filter(a => a.id !== m.id).concat([next]).sort((a, b) => a.id.localeCompare(b.id));
        if (m.state !== "awaiting") withdraw(m.id);
    }

    // An agent that has moved on got its answer elsewhere, such as in its own terminal.
    function withdraw(agent) {
        for (const request of approvals.filter(a => a.agent === agent)) request.connection.connected = false;
        approvals = approvals.filter(a => a.agent !== agent);
    }

    function agentFor(id) { return agents.find(a => a.id === id) || null; }

    function answer(id, allow) {
        const request = approvals.find(a => a.id === id);
        if (!request) return;
        approvals = approvals.filter(a => a !== request);
        request.connection.write(Protocol.reply(id, allow));
        request.connection.flush();
    }

    // A closed connection withdraws its requests: nobody is left to hear the answer.
    function dropConnection(connection) {
        approvals = approvals.filter(a => a.connection !== connection);
    }

    // Finished agents leave after a minute, silent ones after an hour.
    Timer {
        interval: 30000
        repeat: true
        running: ag.agents.length > 0
        onTriggered: {
            const now = Date.now();
            ag.agents = ag.agents.filter(a => now - a.updated < (a.state === "done" ? 60000 : 3600000));
        }
    }
}

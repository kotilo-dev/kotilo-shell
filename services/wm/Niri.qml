// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io
import "../../Shell" as K

// Niri adapter. State comes from `niri msg --json event-stream` (one JSON object per line, verified on 26.04).
// Actions go to $NIRI_SOCKET as JSON: the `niri msg action` CLI can only address a workspace by index or
// name, and an index does not identify a workspace once there is more than one output.
Interface {
    id: niri
    readonly property string name: "niri"
    readonly property bool detected: (Quickshell.env("NIRI_SOCKET") || "").length > 0

    property var _windows: ({})     // id -> window
    property var _actions: []       // waiting for the socket to connect

    focusedOutput: (workspaces.find(w => w.focused) || {}).output || ""

    Component.onCompleted: if (detected) stream.running = true; else error = "NIRI_SOCKET not set"

    Process {
        id: stream
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: (line) => niri.handle(line)
        }
        onExited: (code) => { niri.available = false; niri.error = "event-stream exited " + code; retry.start(); }
    }

    Timer { id: retry; interval: 3000; onTriggered: if (niri.detected) stream.running = true }

    Socket {
        id: ipc
        path: Quickshell.env("NIRI_SOCKET") || ""
        onConnectedChanged: if (connected) niri.flushActions()
    }

    function act(action) {
        _actions.push(JSON.stringify({ Action: action }) + "\n");
        if (ipc.connected) flushActions();
        else ipc.connected = true;
    }

    function flushActions() {
        for (const a of _actions) ipc.write(a);
        ipc.flush();
        _actions = [];
    }

    function handle(line) {
        let ev;
        try { ev = JSON.parse(line); } catch (e) { return; }
        available = true; error = "";

        if (ev.WorkspacesChanged) {
            workspaces = ev.WorkspacesChanged.workspaces.map(w => ({
                id: String(w.id), index: w.idx, name: w.name || String(w.idx), output: w.output || "",
                active: w.is_active, focused: w.is_focused, windows: 0, urgent: w.is_urgent || false
            })).sort((a, b) => a.output === b.output ? a.index - b.index : a.output.localeCompare(b.output));
            recount();          // this event rebuilds the list without window counts
        } else if (ev.WorkspaceActivated) {
            const id = String(ev.WorkspaceActivated.id), focused = ev.WorkspaceActivated.focused;
            const target = workspaces.find(w => w.id === id);
            workspaces = workspaces.map(w => {
                const sameOutput = target && w.output === target.output;
                return Object.assign({}, w, {
                    active: sameOutput ? w.id === id : w.active,
                    focused: focused ? w.id === id : (w.id === id ? false : w.focused)
                });
            });
        } else if (ev.WindowsChanged) {
            _windows = {};
            for (const w of ev.WindowsChanged.windows) _windows[w.id] = w;
            recount();
            setFocused(ev.WindowsChanged.windows.find(w => w.is_focused) || null);   // the stream's initial state
        } else if (ev.WindowOpenedOrChanged) {
            const w = ev.WindowOpenedOrChanged.window; _windows[w.id] = w; recount();
            if (w.is_focused) setFocused(w);
        } else if (ev.WindowClosed) {
            delete _windows[ev.WindowClosed.id]; recount();
        } else if (ev.WindowFocusChanged) {
            const id = ev.WindowFocusChanged.id;
            setFocused(id === null ? null : _windows[id]);
        } else if (ev.WorkspaceUrgencyChanged) {
            const u = ev.WorkspaceUrgencyChanged;
            workspaces = workspaces.map(w => w.id === String(u.id) ? Object.assign({}, w, { urgent: u.urgent }) : w);
        }
    }

    function recount() {
        const counts = {};
        for (const id in _windows) { const ws = String(_windows[id].workspace_id); counts[ws] = (counts[ws] || 0) + 1; }
        workspaces = workspaces.map(w => Object.assign({}, w, { windows: counts[w.id] || 0 }));
    }

    function setFocused(w) {
        focusedWindow = w ? { id: String(w.id), title: w.title || "", appId: w.app_id || "", workspaceId: String(w.workspace_id), output: (workspaces.find(s => s.id === String(w.workspace_id)) || {}).output || "" } : {};
    }

    function focusWorkspace(id) { act({ FocusWorkspace: { reference: { Id: Number(id) } } }); }
    function focusWorkspaceRelative(delta) { act(delta > 0 ? { FocusWorkspaceDown: {} } : { FocusWorkspaceUp: {} }); }
    function moveWindowToWorkspace(id) { act({ MoveWindowToWorkspace: { window_id: null, reference: { Id: Number(id) }, focus: true } }); }
    function closeFocusedWindow() { act({ CloseWindow: { id: null } }); }
    // Niri's stream and the Wayland protocol share no window id, so this matches on app and title.
    function workspaceOf(toplevel) {
        for (const id in _windows) {
            const w = _windows[id];
            if (w.app_id !== toplevel.appId || w.title !== toplevel.title) continue;
            const space = workspaces.find(s => s.id === String(w.workspace_id));
            return space ? String(space.index) : "";
        }
        return "";
    }
    function dispatch(command) { K.Shell.run(["niri", "msg", "action"].concat(command.split(" "))); }
}

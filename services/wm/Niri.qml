import QtQuick
import Quickshell
import Quickshell.Io
import "../../Shell" as K

// Niri adapter. Uses `niri msg --json event-stream` (one JSON object per line) and `niri msg action ...`.
// Event names (niri ≥ 25.x): WorkspacesChanged, WorkspaceActivated, WorkspaceActiveWindowChanged,
// WindowsChanged, WindowOpenedOrChanged, WindowClosed, WindowFocusChanged, KeyboardLayoutsChanged.
Interface {
    id: niri
    readonly property string name: "niri"
    readonly property bool detected: (Quickshell.env("NIRI_SOCKET") || "").length > 0

    property var _windows: ({})     // id -> window

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

    function handle(line) {
        let ev;
        try { ev = JSON.parse(line); } catch (e) { return; }
        available = true; error = "";

        if (ev.WorkspacesChanged) {
            workspaces = ev.WorkspacesChanged.workspaces.map(w => ({
                id: String(w.id), index: w.idx, name: w.name || String(w.idx), output: w.output || "",
                active: w.is_active, focused: w.is_focused, windows: 0, urgent: w.is_urgent || false
            })).sort((a, b) => a.output === b.output ? a.index - b.index : a.output.localeCompare(b.output));
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
        } else if (ev.WindowOpenedOrChanged) {
            const w = ev.WindowOpenedOrChanged.window; _windows[w.id] = w; recount();
            if (w.is_focused) setFocused(w);
        } else if (ev.WindowClosed) {
            delete _windows[ev.WindowClosed.id]; recount();
        } else if (ev.WindowFocusChanged) {
            const id = ev.WindowFocusChanged.id;
            setFocused(id === null ? null : _windows[id]);
        }
    }

    function recount() {
        const counts = {};
        for (const id in _windows) { const ws = String(_windows[id].workspace_id); counts[ws] = (counts[ws] || 0) + 1; }
        workspaces = workspaces.map(w => Object.assign({}, w, { windows: counts[w.id] || 0 }));
    }

    function setFocused(w) {
        focusedWindow = w ? { id: String(w.id), title: w.title || "", appId: w.app_id || "", workspaceId: String(w.workspace_id), output: "" } : {};
    }

    function focusWorkspace(id) { K.Shell.run(["niri", "msg", "action", "focus-workspace", String(id)]); }
    function focusWorkspaceRelative(delta) { K.Shell.run(["niri", "msg", "action", delta > 0 ? "focus-workspace-down" : "focus-workspace-up"]); }
    function moveWindowToWorkspace(id) { K.Shell.run(["niri", "msg", "action", "move-window-to-workspace", String(id)]); }
    function closeFocusedWindow() { K.Shell.run(["niri", "msg", "action", "close-window"]); }
    function dispatch(command) { K.Shell.run(["niri", "msg", "action"].concat(command.split(" "))); }
}

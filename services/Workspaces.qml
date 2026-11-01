// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import "wm" as Wm
import "../Shell" as K

// Facade over the active compositor adapter. This is what plugins import.
Singleton {
    id: ws

    readonly property var adapter: niri.detected ? niri : (hypr.detected ? hypr : null)
    readonly property bool ready: adapter !== null && adapter.available
    readonly property string error: adapter ? adapter.error : "no supported compositor detected (need Niri or Hyprland)"
    readonly property string compositor: adapter ? adapter.name : "none"

    readonly property var list: adapter ? adapter.workspaces : []
    readonly property var focusedWindow: adapter ? adapter.focusedWindow : ({})
    readonly property string focusedOutput: (list.find(w => w.focused) || {}).output || ""

    Wm.Niri { id: niri }
    Wm.Hyprland { id: hypr }

    Component.onCompleted: K.Log.info("compositor: " + compositor, "wm")

    function focus(id) { if (adapter) adapter.focusWorkspace(id); }
    function focusRelative(delta) { if (adapter) adapter.focusWorkspaceRelative(delta); }
    function moveWindowTo(id) { if (adapter) adapter.moveWindowToWorkspace(id); }
    function focusToplevel(toplevel) { if (adapter) adapter.focusToplevel(toplevel); else toplevel.activate(); }
    function closeFocused() { if (adapter) adapter.closeFocusedWindow(); }
    function dispatch(cmd) { if (adapter) adapter.dispatch(cmd); }

    // Workspaces visible on a given output (screen name); falls back to all.
    function forOutput(name) {
        const l = list.filter(w => !name || !w.output || w.output === name);
        return l.length ? l : list;
    }
}

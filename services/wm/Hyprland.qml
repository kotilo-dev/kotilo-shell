// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland as Hypr

// Hyprland adapter on top of Quickshell's built-in Hyprland module, which handles the socket2 events.
// The import is qualified because this file is itself named Hyprland, which would shadow the singleton.
//
// The model is bindings, not an event-driven sync: Quickshell fills its objects asynchronously, and a
// binding re-evaluates on every property it reads, including ones no socket2 event announces.
Interface {
    id: hypr
    readonly property string name: "hyprland"
    readonly property bool detected: (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "").length > 0

    available: detected
    error: detected ? "" : "HYPRLAND_INSTANCE_SIGNATURE not set"

    workspaces: detected ? readWorkspaces() : []
    focusedWindow: detected ? readFocusedWindow() : ({})
    focusedOutput: detected && Hypr.Hyprland.focusedMonitor ? Hypr.Hyprland.focusedMonitor.name : ""

    function readWorkspaces() {
        return Hypr.Hyprland.workspaces.values
            .filter(w => w.id > 0)     // negative ids are special workspaces
            .map(w => ({
                id: String(w.id), index: w.id, name: w.name, output: w.monitor ? w.monitor.name : "",
                active: w.active, focused: w.focused,
                windows: w.toplevels.values.length, urgent: w.urgent
            }))
            .sort((a, b) => a.index - b.index);
    }

    function readFocusedWindow() {
        // Hyprland.activeToplevel stays null until focus next changes after startup.
        const wl = ToplevelManager.activeToplevel;
        if (!wl) return {};
        const top = Hypr.Hyprland.toplevels.values.find(t => t.wayland === wl);
        return {
            id: top ? top.address : "", title: wl.title, appId: wl.appId,
            workspaceId: top && top.workspace ? String(top.workspace.id) : "",
            output: top && top.monitor ? top.monitor.name : ""
        };
    }

    // Dispatchers have a different syntax under a Lua config. Lua strings use JSON quoting rules here.
    function dsp(lua, legacy) { Hypr.Hyprland.dispatch(Hypr.Hyprland.usingLua ? lua : legacy); }
    function focusTarget(target) { dsp("hl.dsp.focus({ workspace = " + JSON.stringify(target) + " })", "workspace " + target); }

    function focusWorkspace(id) { focusTarget(String(id)); }
    function focusWorkspaceRelative(delta) { focusTarget(delta > 0 ? "e+1" : "e-1"); }
    function moveWindowToWorkspace(id) { dsp("hl.dsp.window.move({ workspace = " + JSON.stringify(String(id)) + " })", "movetoworkspace " + id); }
    function closeFocusedWindow() { dsp("hl.dsp.window.close()", "killactive"); }
    function focusToplevel(toplevel) {
        const top = Hypr.Hyprland.toplevels.values.find(t => t.wayland === toplevel);
        if (!top) { toplevel.activate(); return; }
        const target = "address:0x" + top.address;
        dsp("hl.dsp.focus({ window = " + JSON.stringify(target) + " })", "focuswindow " + target);
    }
    function dispatch(command) { Hypr.Hyprland.dispatch(command); }   // raw: the caller's syntax, not translated
}

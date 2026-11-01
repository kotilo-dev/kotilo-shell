// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell

// Compositor adapter interface. Every adapter (Niri, Hyprland, later Sway) must provide
// exactly these properties/signals/functions. Modules talk to services/Workspaces.qml,
// which delegates to the active adapter — never to an adapter directly.
// Scope (not QtObject) because adapters hold child objects such as Process and Timer.
Scope {
    readonly property string name: "interface"
    property bool available: false            // adapter detected its compositor and connected
    property string error: ""

    // Normalised model. One entry per workspace:
    // { id: string, index: int, name: string, output: string, active: bool, focused: bool, windows: int, urgent: bool }
    property var workspaces: []
    // { id, title, appId, workspaceId, output }
    property var focusedWindow: ({})
    property string focusedOutput: ""

    function focusWorkspace(id) {}
    function focusWorkspaceRelative(delta) {}   // +1 / -1
    function moveWindowToWorkspace(id) {}
    function closeFocusedWindow() {}
    function dispatch(command) {}               // raw passthrough for power users (palette "Shell command")
}

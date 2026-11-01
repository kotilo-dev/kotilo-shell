//@ pragma UseQApplication
// SPDX-License-Identifier: GPL-3.0-or-later
// Kotilo Shell — entry point. Run with: qs -c kotilo  (after install) or ./scripts/dev.sh
import QtQuick
import Quickshell
import Quickshell.Io
import "Shell" as K
import "components" as C
import "services" as S

ShellRoot {
    id: root

    Component.onCompleted: K.Log.info("Kotilo Shell " + K.Shell.version + " starting (api " + K.Shell.apiVersion + ")")

    // Core singletons are instantiated on first use (Theme, Settings, Log).
    // PluginHost discovers and validates plugins; Bar mounts the bar.* slots.
    K.PluginHost { id: pluginHost }
    K.PopupHost {}

    // User plugins live outside the shell folder, so Quickshell does not watch them.
    IpcHandler {
        target: "plugins"
        function reload(): void { Quickshell.reload(false); }
    }

    // Bar keyboard mode (ADR-0014). Also the way out from a script.
    IpcHandler {
        target: "bar"
        function toggle(): void {
            const screens = Quickshell.screens;
            const output = screens.some(s => s.name === S.Workspaces.focusedOutput) ? S.Workspaces.focusedOutput : (screens.length ? screens[0].name : "");
            K.Shell.barKeyboardOutput = K.Shell.barKeyboardOutput ? "" : output;
        }
    }

    // One bar per screen.
    Variants {
        model: Quickshell.screens
        delegate: K.Bar {
            required property var modelData
            screen: modelData
            host: pluginHost
        }
    }

    // Non-bar slots. These plugins own their windows or draw nothing, so this host is never shown.
    C.SlotRow { slotName: "osd.kind"; host: pluginHost; visible: false }
    C.SlotRow { slotName: "shell.overlay"; host: pluginHost; visible: false }
    C.SlotRow { slotName: "palette.provider"; host: pluginHost; visible: false }
    C.SlotRow { slotName: "theme.target"; host: pluginHost; visible: false }
    C.SlotRow { slotName: "notification.handler"; host: pluginHost; visible: false }

    // Popups / panels are LazyLoaders inside their plugins; nothing else is created at startup.
}

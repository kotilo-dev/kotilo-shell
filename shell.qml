//@ pragma UseQApplication
// SPDX-License-Identifier: GPL-3.0-or-later
// Kotilo Shell — entry point. Run with: qs -c kotilo  (after install) or ./scripts/dev.sh
import QtQuick
import Quickshell
import "Shell" as K
import "components" as C

ShellRoot {
    id: root

    Component.onCompleted: K.Log.info("Kotilo Shell " + K.Shell.version + " starting (api " + K.Shell.apiVersion + ")")

    // Core singletons are instantiated on first use (Theme, Settings, Log).
    // PluginHost discovers and validates plugins; Bar mounts the bar.* slots.
    K.PluginHost { id: pluginHost }

    // One bar per screen.
    Variants {
        model: Quickshell.screens
        delegate: K.Bar {
            required property var modelData
            screen: modelData
            host: pluginHost
        }
    }

    // Non-bar slots. OSD plugins own their windows, so this host is never shown.
    C.SlotRow { slotName: "osd.kind"; host: pluginHost; visible: false }

    // Popups / panels are LazyLoaders inside their plugins; nothing else is created at startup.
}

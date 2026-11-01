// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../Shell" as K

// System tray facade. Passive items are ones the app itself marks as not worth showing.
Singleton {
    readonly property bool ready: true  // an empty tray is valid, not an error
    readonly property string error: ""
    readonly property bool showPassive: K.Settings.get("bar.tray", "showPassive", false)
    readonly property var items: SystemTray.items.values.filter(i => showPassive || i.status !== Status.Passive)
}

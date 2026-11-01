// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell

// Global constants and the sanctioned shell-out helper.
Singleton {
    id: root

    readonly property string version: "0.1.0-dev"
    readonly property string apiVersion: "1.0.0"

    // Resolved config/data dirs (XDG-compliant; never assume a distro layout).
    // The shell/ level keeps these apart from Kotilo Desktop's own files: see docs/adr/0005.
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/kotilo/shell"
    readonly property string dataDir:   (Quickshell.env("XDG_DATA_HOME")   || (Quickshell.env("HOME") + "/.local/share")) + "/kotilo/shell"
    readonly property string cacheDir:  (Quickshell.env("XDG_CACHE_HOME")  || (Quickshell.env("HOME") + "/.cache")) + "/kotilo/shell"
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property bool devMode: Quickshell.env("KOTILO_DEV") === "1"

    // Path of the shell sources themselves (plugins/core, themes live beside shell.qml).
    readonly property string shellDir: Quickshell.shellDir

    // run(argv, {timeout, cwd}) -> Promise<{stdout, stderr, code}>
    // The ONLY way plugins may shell out. Implemented with a transient Process.
    function run(argv, opts) {
        opts = opts || {};
        return new Promise(function (resolve, reject) {
            const comp = Qt.createComponent(Qt.resolvedUrl("internal/RunProcess.qml"));
            if (comp.status !== Component.Ready) { reject(comp.errorString()); return; }
            const p = comp.createObject(root, {
                argv: argv,
                cwd: opts.cwd || "",
                timeoutMs: opts.timeout || 5000
            });
            p.finished.connect(function (result) { resolve(result); p.destroy(); });
            p.failed.connect(function (err) { reject(err); p.destroy(); });
            p.start();
        });
    }

    // Popups: implemented by PluginHost; exposed here for plugins.
    signal openPopupRequested(var plugin, string file, var anchorItem)
    signal closePopupsRequested()
    function openPopup(plugin, file, anchorItem) { openPopupRequested(plugin, file, anchorItem || null); }
    function closePopups() { closePopupsRequested(); }

    // Notifications: forwarded to the Notifications service when it exists (0.2).
    signal notifyRequested(var notification)
    function notify(n) { notifyRequested(n); }
}

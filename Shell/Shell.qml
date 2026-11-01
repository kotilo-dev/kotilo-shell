// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import "internal/fuzzy.js" as Fuzzy
import "internal/schemaform.js" as Form

// Global constants and the sanctioned shell-out helper.
Singleton {
    id: root

    readonly property string version: "0.3.0"
    readonly property string apiVersion: "1.13.0"

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

    // Palette providers (ADR-0008): each exposes `title` and `items(query)`.
    property var paletteProviders: []
    signal paletteDataChanged()                 // a provider's rows changed while the palette may be open
    signal paletteOpened()                      // refresh anything that goes stale here
    signal paletteClosed()
    function registerPaletteProvider(p) { paletteProviders = paletteProviders.concat([p]); }
    function unregisterPaletteProvider(p) { paletteProviders = paletteProviders.filter(x => x !== p); }

    // -1 for no match, otherwise higher is better.
    function fuzzyScore(query, text) { return Fuzzy.score(query, text); }
    function fuzzyRank(query, title, keywords) { return Fuzzy.rank(query, title, keywords); }

    // Settings forms from a JSON schema (ADR-0004).
    function formFields(schema, values) { return Form.fields(schema, values); }
    function formStep(field, direction) { return Form.step(field, direction); }
    function formParse(field, text) { return Form.parse(field, text); }
    function formDisplay(field) { return Form.display(field); }
    function formText(field) { return Form.text(field); }
    function formMove(rows, index, direction) { return Form.move(rows, index, direction); }

    signal controlCenterToggled()
    function toggleControlCenter() { controlCenterToggled(); }

    // Palette actions: exec is a function or an argv array.
    property var paletteActions: []
    function registerPaletteAction(plugin, action) {
        const entry = Object.assign({}, action, { pluginId: plugin.id, pluginName: plugin.manifest.name });
        paletteActions = paletteActions.filter(a => a.pluginId !== plugin.id || a.title !== action.title).concat([entry]);
    }
    function unregisterPaletteActions(plugin) { paletteActions = paletteActions.filter(a => a.pluginId !== plugin.id); }
    function runPaletteAction(action) {
        if (typeof action.exec === "function") action.exec();
        else Quickshell.execDetached(action.exec);
    }

    // Notification handlers: match(n) picks a notification, handle(n) returns true to hold its popup.
    property var notificationHandlers: []
    function registerNotificationHandler(h) { notificationHandlers = notificationHandlers.concat([h]); }
    function unregisterNotificationHandler(h) { notificationHandlers = notificationHandlers.filter(x => x !== h); }

    // Bar keyboard mode (ADR-0014): the output whose bar holds the keyboard, or "".
    property string barKeyboardOutput: ""

    // Handles a key for a bar item. Returns "activate" or "menu" when the item has work to do.
    function barKey(event, item) {
        const key = event.key;
        let action = "";
        if (key === Qt.Key_Left || key === Qt.Key_Right) {
            const next = item.nextItemInFocusChain(key === Qt.Key_Right);
            if (next) next.forceActiveFocus();
        } else if (key === Qt.Key_Escape) barKeyboardOutput = "";
        else if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space) action = "activate";
        else if (key === Qt.Key_Menu) action = "menu";
        else return "";
        event.accepted = true;
        if (action) barKeyboardOutput = "";     // what it opens needs the keyboard
        return action;
    }

    // Asks the dashboard to close, for a card or tab whose action leaves the shell.
    signal dashboardClosed()
    signal dashboardToggled()
    function toggleDashboard() { dashboardToggled(); }

    signal settingsToggled()
    function toggleSettings() { settingsToggled(); }

    signal agentsToggled()
    function toggleAgents() { agentsToggled(); }

    // Notifications: sent through the Notifications service.
    signal notifyRequested(var notification)
    function notify(n) { notifyRequested(n); }
}

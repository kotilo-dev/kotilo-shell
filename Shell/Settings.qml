// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// settings.json loader with hot reload. Plugins read through get()/set().
// Defaults come from config/settings.default.json shipped with the shell.
Singleton {
    id: root

    readonly property string path: Shell.configDir + "/settings.json"
    property var global: ({})
    property bool ready: false
    property bool useDefaults: false            // set when settings.json cannot be read
    property bool parseError: false             // the file does not parse, so saving would lose the user's edits

    signal changed(string pluginId, string key)

    FileView {
        id: file
        path: root.path
        watchChanges: true
        printErrors: false                      // a missing file is normal: loadFailed falls back to defaults
        onFileChanged: reload()
        onLoaded: { root.useDefaults = false; root.apply(text()); }
        onLoadFailed: (err) => {
            if (root.useDefaults) return;
            Log.warn("settings.json missing or unreadable (" + FileViewError.toString(err) + "); using defaults", "settings");
            root.useDefaults = true;
        }
    }

    FileView {
        id: defaults
        // Empty until needed: FileView loads as soon as it has a path, which would race the user file.
        path: root.useDefaults ? Quickshell.shellPath("config/settings.default.json") : ""
        onLoaded: root.apply(text())
    }

    function apply(json) {
        try {
            global = JSON.parse(json);
            parseError = false;
            ready = true;
            changed("", "");
            Log.info("settings loaded from " + root.path, "settings");
        } catch (e) {
            parseError = true;
            Log.error("settings parse error: " + e, "settings");
        }
    }

    function get(pluginId, key, fallback) {
        const p = global && global.plugins ? global.plugins[pluginId] : undefined;
        if (p && p[key] !== undefined) return p[key];
        return fallback;
    }

    function set(pluginId, key, value) {
        if (!global.plugins) global.plugins = {};
        if (!global.plugins[pluginId]) global.plugins[pluginId] = {};
        global.plugins[pluginId][key] = value;
        commit(pluginId, key);
    }

    function setTheme(id) {
        if (!global.theme) global.theme = {};
        global.theme.id = id;
        commit("", "theme");
    }

    // A new object wakes every binding on global. The file watcher cannot do this: it does not
    // fire for our own writes on every filesystem (btrfs, for one).
    function commit(pluginId, key) {
        global = Object.assign({}, global);
        save();
        changed(pluginId, key);
    }

    function save() {
        if (parseError) { Log.warn("settings.json has a syntax error, so nothing was saved", "settings"); return; }
        file.setText(JSON.stringify(global, null, 2));
    }
}

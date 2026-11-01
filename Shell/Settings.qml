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
            ready = true;
            changed("", "");
            Log.info("settings loaded from " + root.path, "settings");
        } catch (e) {
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
        save();
        changed(pluginId, key);
    }

    function save() {
        file.setText(JSON.stringify(global, null, 2));
    }
}

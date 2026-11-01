// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io
import "../Shell" as K
import "../Shell/internal/template.js" as Template

// Root of a theme.target plugin (ADR-0011). Renders template.conf into the shell's generated
// folder on every theme change, and touches no other file.
Item {
    id: target
    property var plugin: null
    property string slot: ""
    property string fileName: ""                // generated file, such as ghostty.conf
    property var reloadCommand: []              // run after a change when the plugin's reload setting is on

    readonly property string pluginId: plugin ? plugin.manifest.id : ""
    readonly property string outputDir: K.Shell.dataDir + "/generated"
    readonly property bool enabled: K.Settings.ready && (!K.Settings.global.theme || K.Settings.global.theme.propagate !== false)
    property string lastWritten: ""

    FileView {
        id: template
        path: target.plugin ? target.plugin.dir + "/template.conf" : ""
        onLoaded: target.update()
    }

    FileView {
        id: output
        path: target.fileName.length ? target.outputDir + "/" + target.fileName : ""
        printErrors: false
        onSaved: target.reloadApp()
        onSaveFailed: err => K.Log.warn(target.fileName + ": " + FileViewError.toString(err), "theme")
    }

    Connections {
        target: K.Theme
        function onChanged() { target.update(); }
    }

    function update() {
        if (!enabled || !K.Theme.ready || !template.loaded || !fileName.length) return;
        let text;
        try { text = Template.render(template.text(), K.Theme.tokens); }
        catch (e) { K.Log.warn(pluginId + ": " + e, "theme"); return; }
        if (text === lastWritten) return;
        K.Shell.run(["mkdir", "-p", outputDir]).then(() => {
            lastWritten = text;
            output.setText(text);
        }, e => K.Log.warn(pluginId + ": " + e, "theme"));
    }

    function reloadApp() {
        if (reloadCommand.length && K.Settings.get(pluginId, "reload", false))
            K.Shell.run(reloadCommand).catch(e => K.Log.warn(pluginId + ": " + e, "theme"));
    }
}

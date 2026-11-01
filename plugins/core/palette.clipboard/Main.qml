// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K

// cliphist history. Entries can hold secrets, so they are never logged or kept after the palette closes.
Item {
    id: root
    property var plugin: null
    property string slot: ""
    readonly property string title: "Clipboard"
    property var entries: []                    // { id, text }
    readonly property int limit: 200

    Component.onCompleted: K.Shell.registerPaletteProvider(root)
    Component.onDestruction: K.Shell.unregisterPaletteProvider(root)

    Connections {
        target: K.Shell
        function onPaletteOpened() { root.load(); }
        function onPaletteClosed() { root.entries = []; }
    }

    function load() {
        K.Shell.run(["sh", "-c", 'command -v cliphist >/dev/null && cliphist list']).then(r => {
            if (r.code !== 0) return;           // no cliphist: this provider stays empty
            root.entries = r.stdout.split("\n").filter(l => l.length).slice(0, root.limit).map(l => {
                const i = l.indexOf("\t");
                return { id: l.slice(0, i), text: l.slice(i + 1) };
            });
            K.Shell.paletteDataChanged();
        }).catch(() => K.Log.warn("cliphist list failed", "palette"));
    }

    function pipe(script, id) {
        K.Shell.run(["sh", "-c", script, "sh", id]).catch(() => K.Log.warn("cliphist command failed", "palette"));
    }

    // Long text contains most short queries as a subsequence, so match it as a substring.
    // The explicit score keeps clips below anything matched by title.
    function items(query) {
        const q = query.toLowerCase();
        if (!q.length) return [];
        return entries.filter(e => e.text.toLowerCase().includes(q)).map(e => ({
            title: e.text,
            score: K.Shell.fuzzyScore(q, e.text),
            actions: [
                { title: "Copy", run: () => pipe('printf "%s\\t\\n" "$1" | cliphist decode | wl-copy >/dev/null 2>&1', e.id) },
                { title: "Delete from history", run: () => pipe('printf "%s\\t\\n" "$1" | cliphist delete', e.id) }
            ]
        }));
    }
}

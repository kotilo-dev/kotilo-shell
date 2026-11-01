// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Label {
    property var plugin: null
    property string slot: ""
    readonly property int maxLen: K.Settings.get("bar.window-title", "maxLength", 60)
    readonly property var w: S.Workspaces.focusedWindow
    secondary: true
    elide: Text.ElideRight
    text: {
        if (!w || !w.title) return "";
        const app = w.appId ? w.appId.split(".").pop() : "";
        const t = app && !w.title.startsWith(app) ? app + " — " + w.title : w.title;
        return t.length > maxLen ? t.substring(0, maxLen - 1) + "…" : t;
    }
}

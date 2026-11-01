// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K
import qs.components as C
import "feed.js" as Feed

// Fetches only the feeds the user listed, under time and size limits. Feed text is shown as plain text.
Item {
    id: tab
    property var plugin: null
    property string slot: ""
    property bool current: false
    readonly property string title: "RSS"
    readonly property var addresses: K.Settings.get("dash.rss", "feeds", [])
    readonly property int limit: K.Settings.get("dash.rss", "limit", 60)
    property var feeds: []
    property string status: ""
    property bool loaded: false

    function key(event) { return list.key(event); }

    function read() {
        if (!addresses.length) { status = "Add feed addresses in Settings, under RSS tab."; return; }
        status = "Loading…";
        for (const address of addresses) {
            if (!/^https?:\/\//i.test(address)) continue;
            K.Shell.run(["curl", "-fsSL", "--max-time", "10", "--max-filesize", "5000000", "--proto", "=https,http", "--", address], { timeout: 12000 }).then(r => {
                if (r.code !== 0) { K.Log.warn("feed failed: " + address, "rss"); tab.status = "Some feeds could not be read."; return; }
                const feed = Feed.parse(r.stdout);
                tab.feeds = tab.feeds.concat([feed]);
                if (!feed.items.length) tab.status = "Some feeds had no articles.";
            }, () => { tab.status = "Could not run curl."; });
        }
    }

    onCurrentChanged: if (current && !loaded) { loaded = true; read(); }

    C.PickList {
        id: list
        anchors { top: parent.top; left: parent.left; right: parent.right; bottom: summary.visible ? summary.top : parent.bottom; bottomMargin: K.Theme.space.sm }
        empty: tab.status
        rows: Feed.merge(tab.feeds, tab.limit).map(i => ({ title: i.title, detail: i.source, trailing: i.date ? Qt.formatDate(new Date(i.date), "d MMM") : "", link: i.link, summary: i.summary }))
        onChosen: row => {
            if (!row.link) return;
            Quickshell.execDetached(["xdg-open", row.link]);
            K.Shell.dashboardClosed();
        }
    }

    C.Label {
        id: summary
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        readonly property var row: list.rows[list.selected]
        visible: text.length > 0
        wrapMode: Text.Wrap
        maximumLineCount: 3
        elide: Text.ElideRight
        secondary: true
        textFormat: Text.PlainText
        text: row && row.summary ? row.summary : ""
    }
}

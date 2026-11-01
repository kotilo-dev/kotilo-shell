// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K
import qs.components as C
import "links.js" as Links

// Fetches when first shown, and each time the panel opens. Read-only: nothing here changes GitHub.
Item {
    id: tab
    property var plugin: null
    property string slot: ""
    property bool current: false
    readonly property string title: "GitHub"
    property var notifications: []
    property var reviews: []
    property var repositories: []
    property string status: "Loading…"
    property bool loaded: false

    function key(event) { return list.key(event); }

    function gh(args, done) {
        return K.Shell.run(["gh"].concat(args), { timeout: 15000 }).then(r => {
            if (r.code !== 0) { tab.status = "Sign in with gh auth login to see GitHub."; return; }
            try { done(JSON.parse(r.stdout)); tab.status = "Nothing to show."; }
            catch (e) { tab.status = "gh returned something unreadable."; }
        }, () => { tab.status = "Could not run gh. Is it installed?"; });
    }

    onCurrentChanged: {
        if (!current || loaded) return;
        loaded = true;
        gh(["api", "notifications"], d => tab.notifications = Links.notificationRows(d));
        gh(["search", "prs", "--review-requested=@me", "--state=open", "--limit", "10", "--json", "title,url,repository,number"],
           d => tab.reviews = d.map(p => ({ title: p.title, detail: (p.repository ? p.repository.nameWithOwner : "") + "#" + p.number, url: p.url })));
        gh(["repo", "list", "--limit", "10", "--json", "nameWithOwner,description,url"],
           d => tab.repositories = d.map(p => ({ title: p.nameWithOwner, detail: p.description || "", url: p.url })));
    }

    function section(heading, rows) { return rows.length ? [{ heading: heading }].concat(rows) : []; }

    C.PickList {
        id: list
        anchors.fill: parent
        empty: tab.status
        rows: tab.section("Notifications", tab.notifications)
            .concat(tab.section("Review requests", tab.reviews))
            .concat(tab.section("Repositories", tab.repositories))
        onChosen: row => {
            if (!Links.safe(row.url)) return;
            Quickshell.execDetached(["xdg-open", row.url]);
            K.Shell.dashboardClosed();
        }
    }
}

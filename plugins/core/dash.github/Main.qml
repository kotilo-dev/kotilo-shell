// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K
import qs.components as C
import "links.js" as Links

// Four panels, each fetched on its own so that one failure leaves the others working, and each with
// a More link to its page on GitHub. Read-only: nothing here changes GitHub.
Item {
    id: tab
    property var plugin: null
    property string slot: ""
    property bool current: false
    readonly property string title: "GitHub"
    property bool loaded: false
    property string login: ""
    property int selected: 0

    readonly property int rowHeight: 40
    // Rows that fit a panel, below its heading and above its More link.
    readonly property int shown: Math.max(1, Math.floor((panels.height / 2 - 2 * K.Theme.space.md - 60) / rowHeight))

    property var sections: [
        { key: "notifications", title: "Notifications", empty: "You are all caught up.", more: "https://github.com/notifications", rows: [], status: "Loading…" },
        { key: "pulls", title: "Your pull requests", empty: "No open pull requests.", more: "https://github.com/pulls", rows: [], status: "Loading…" },
        { key: "reviews", title: "Review requests", empty: "Nothing to review.", more: "https://github.com/pulls/review-requested", rows: [], status: "Loading…" },
        { key: "repos", title: "Local repositories", empty: "No repositories in the folders set under Projects.", more: "https://github.com/", rows: [], status: "Loading…" }
    ]

    // Every place the keyboard can land, in reading order.
    readonly property var stops: {
        const list = [];
        sections.forEach((section, s) => {
            section.rows.slice(0, shown).forEach((row, r) => list.push({ section: s, row: r, url: row.url }));
            list.push({ section: s, row: -1, url: section.more });
        });
        return list;
    }
    readonly property var stop: stops[Math.min(selected, stops.length - 1)] || ({})

    function isAt(section, row) { return stop.section === section && stop.row === row; }

    function open(url) {
        if (!Links.safe(url)) return;
        Quickshell.execDetached(["xdg-open", url]);
        K.Shell.dashboardClosed();
    }

    function key(event) {
        if (event.key === Qt.Key_Down) selected = (selected + 1) % stops.length;
        else if (event.key === Qt.Key_Up) selected = (selected - 1 + stops.length) % stops.length;
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) open(stop.url);
        else return false;
        return true;
    }

    // Repositories on this machine, from the folders the Projects palette provider searches.
    function readLocal() {
        const home = Quickshell.env("HOME");
        const roots = K.Settings.get("palette.projects", "roots", ["~/dev", "~/src", "~/projects", "~/code"]).map(r => r.replace(/^~(?=\/|$)/, home));
        K.Shell.run(["sh", plugin.dir + "/local-repos.sh"].concat(roots), { timeout: 15000 }).then(r => {
            const list = Links.localRows(r.stdout, home);
            update("repos", { rows: list, status: list.length ? "" : "empty" });
        }, () => { update("repos", { status: "Could not read the repositories." }); });
    }

    function update(key, change) {
        sections = sections.map(s => s.key === key ? Object.assign({}, s, change) : s);
    }

    function fetch(key, args, rows) {
        K.Shell.run(["gh"].concat(args), { timeout: 15000 }).then(r => {
            if (r.code !== 0) { update(key, { status: "Sign in with gh auth login." }); return; }
            try {
                const list = rows(JSON.parse(r.stdout));
                update(key, { rows: list, status: list.length ? "" : "empty" });
            } catch (e) {
                update(key, { status: "gh returned something unreadable." });
            }
        }, () => { update(key, { status: "Could not run gh. Is it installed?" }); });
    }

    onCurrentChanged: {
        if (!current || loaded) return;
        loaded = true;
        const now = Date.now();
        const pullFields = "title,url,repository,number,updatedAt";
        fetch("notifications", ["api", "notifications"], d => Links.notificationRows(d));
        fetch("pulls", ["search", "prs", "--author=@me", "--state=open", "--limit", "20", "--sort", "updated", "--json", pullFields], d => Links.pullRows(d, now));
        fetch("reviews", ["search", "prs", "--review-requested=@me", "--state=open", "--limit", "20", "--sort", "updated", "--json", pullFields], d => Links.pullRows(d, now));
        readLocal();
        K.Shell.run(["gh", "api", "user"], { timeout: 15000 }).then(r => {
            try { update("repos", { more: Links.repositoriesPage(JSON.parse(r.stdout).login) }); } catch (e) {}
        }, () => {});
    }

    Grid {
        id: panels
        anchors.fill: parent
        columns: 2
        spacing: K.Theme.space.sm

        Repeater {
            model: tab.sections

            delegate: C.Card {
                id: panel
                required property var modelData
                required property int index
                width: (panels.width - panels.spacing) / 2
                height: (panels.height - panels.spacing) / 2
                title: modelData.title + (modelData.rows.length ? "  " + (modelData.rows.length >= 20 ? "20+" : modelData.rows.length) : "")

                Item {
                    width: parent.width
                    height: panel.height - 2 * K.Theme.space.md - 24

                    Column {
                        width: parent.width

                        C.Label {
                            width: parent.width
                            height: tab.rowHeight
                            visible: panel.modelData.rows.length === 0
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            secondary: true
                            textFormat: Text.PlainText
                            text: panel.modelData.status === "empty" ? panel.modelData.empty : panel.modelData.status
                        }

                        Repeater {
                            model: panel.modelData.rows.slice(0, tab.shown)

                            delegate: Rectangle {
                                id: row
                                required property var modelData
                                required property int index
                                width: parent.width
                                height: tab.rowHeight
                                radius: K.Theme.radius.sm
                                color: tab.isAt(panel.index, index) ? K.Theme.surface[1] : "transparent"

                                C.StateLayer { hovered: rowMouse.containsMouse; pressed: rowMouse.pressed }

                                Column {
                                    anchors { left: parent.left; right: age.left; leftMargin: K.Theme.space.sm; rightMargin: K.Theme.space.sm; verticalCenter: parent.verticalCenter }
                                    C.Label { width: parent.width; elide: Text.ElideRight; textFormat: Text.PlainText; text: row.modelData.title }
                                    C.Label { width: parent.width; visible: text.length > 0; elide: Text.ElideRight; secondary: true; textFormat: Text.PlainText; font.pixelSize: K.Theme.font.size - 2; text: row.modelData.detail }
                                }
                                C.Label {
                                    id: age
                                    anchors { right: parent.right; rightMargin: K.Theme.space.sm; verticalCenter: parent.verticalCenter }
                                    secondary: true
                                    textFormat: Text.PlainText
                                    font.pixelSize: K.Theme.font.size - 2
                                    color: row.modelData.attention ? K.Theme.state.warning : K.Theme.text.secondary
                                    text: row.modelData.trailing
                                }
                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: tab.open(row.modelData.url)
                                }
                            }
                        }

                    }

                    Rectangle {
                        id: more
                        anchors { right: parent.right; bottom: parent.bottom }
                        width: moreLabel.implicitWidth + 2 * K.Theme.space.sm
                        height: 24
                        radius: K.Theme.radius.sm
                        color: tab.isAt(panel.index, -1) ? K.Theme.surface[1] : "transparent"

                        C.StateLayer { hovered: moreMouse.containsMouse; pressed: moreMouse.pressed }
                        C.Label {
                            id: moreLabel
                            anchors.centerIn: parent
                            color: K.Theme.accent.primary
                            font.pixelSize: K.Theme.font.size - 1
                            text: "More ›"
                        }
                        MouseArea {
                            id: moreMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: tab.open(panel.modelData.more)
                        }
                    }
                }
            }
        }
    }
}

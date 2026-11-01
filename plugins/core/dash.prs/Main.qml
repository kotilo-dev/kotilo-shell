// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K
import qs.components as C

// Fetches once when the dashboard opens, so it costs nothing while closed.
C.Card {
    id: card
    title: "Open pull requests"
    property var rows: []
    property string status: "Loading…"

    Component.onCompleted: {
        const limit = String(K.Settings.get("dash.prs", "limit", 6));
        K.Shell.run(["gh", "search", "prs", "--author=@me", "--state=open", "--limit", limit, "--json", "title,url,repository,number"], { timeout: 15000 }).then(r => {
            if (r.code !== 0) { card.status = "Sign in with gh auth login to see pull requests."; return; }
            try {
                card.rows = JSON.parse(r.stdout);
                card.status = card.rows.length ? "" : "No open pull requests";
            } catch (e) {
                card.status = "gh returned something unreadable.";
            }
        }, () => { card.status = "Could not run gh. Is it installed?"; });
    }

    function open(row) {
        if (typeof row.url === "string" && row.url.startsWith("https://github.com/")) {
            Quickshell.execDetached(["xdg-open", row.url]);
            K.Shell.dashboardClosed();
        }
    }

    C.Label {
        width: parent.width
        visible: card.status.length > 0
        wrapMode: Text.Wrap
        secondary: true
        textFormat: Text.PlainText
        text: card.status
    }

    Repeater {
        model: card.rows

        delegate: Rectangle {
            id: row
            required property var modelData
            width: parent.width
            height: 30
            radius: K.Theme.radius.sm
            color: mouse.containsMouse ? K.Theme.surface[1] : "transparent"
            activeFocusOnTab: true
            Keys.onPressed: event => {
                const key = event.key;
                if (key === Qt.Key_Return || key === Qt.Key_Enter) card.open(row.modelData);
                else if (key === Qt.Key_Down || key === Qt.Key_Up) row.nextItemInFocusChain(key === Qt.Key_Down).forceActiveFocus();
                else return;
                event.accepted = true;
            }

            C.FocusRing { visible: row.activeFocus }

            C.Label {
                anchors { left: parent.left; right: parent.right; leftMargin: K.Theme.space.sm; rightMargin: K.Theme.space.sm; verticalCenter: parent.verticalCenter }
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: row.modelData.title + "  " + (row.modelData.repository ? row.modelData.repository.name : "") + "#" + row.modelData.number
            }
            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: card.open(row.modelData)
            }
        }
    }
}

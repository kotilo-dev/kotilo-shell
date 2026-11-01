// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K
import qs.components as C
import "market.js" as Market

// Two lists the user chooses. Reads only while this tab shows, one request at a time. Prices are
// for reading: nothing here can trade, and they may be delayed.
Item {
    id: tab
    property var plugin: null
    property string slot: ""
    property bool current: false
    readonly property string title: "Trade"
    readonly property int maxItems: 100

    // Panels come from Settings: their names, their number, and what each one holds.
    readonly property var panels: K.Settings.get("dash.trade", "panels", []).slice(0, 12).map(p => ({
        title: String(p.title || ""),
        items: (Array.isArray(p.items) ? p.items : []).slice(0, maxItems).map(Market.source).filter(i => i !== null)
    }))
    readonly property var stops: panels.reduce((all, p) => all.concat(p.items), [])
    // Each part of a formula is read once, even when several lines use it.
    readonly property var reads: {
        const seen = {};
        for (const item of stops) for (const need of item.needs) seen[need.kind + ":" + need.symbol] = need;
        return Object.keys(seen).map(k => seen[k]);
    }
    // Two rows fit; more panels scroll.
    readonly property real panelHeight: (pages.height - (panels.length > 2 ? row.spacing : 0)) / (panels.length > 2 ? 2 : 1)
    property var quotes: ({})                   // source key -> quote, or { error }
    property int selected: 0
    property bool reading: false
    property string updated: ""

    function quoteOf(item) {
        return item.terms ? Market.compute(item, quotes) : (quotes[item.key] || null);
    }
    // Brings the panel holding the selection into view when there are more panels than fit.
    onSelectedChanged: {
        for (let i = 0, start = 0; i < panels.length; start += panels[i].items.length, i++) {
            if (selected < start + panels[i].items.length) {
                const top = Math.floor(i / 2) * (panelHeight + row.spacing);
                if (top < pages.contentY) pages.contentY = top;
                else if (top + panelHeight > pages.contentY + pages.height) pages.contentY = top + panelHeight - pages.height;
                return;
            }
        }
    }
    function offsetOf(index) {
        return panels.slice(0, index).reduce((sum, p) => sum + p.items.length, 0);
    }

    function readAll() {
        if (reading || !reads.length) return;
        reading = true;
        const queue = reads.slice();
        const next = () => {
            if (!queue.length || !current) {
                reading = false;
                updated = Qt.formatTime(new Date(), "HH:mm");
                return;
            }
            read(queue.shift(), next);
        };
        next();
    }

    function read(item, done) {
        // Yahoo refuses curl's own agent string.
        K.Shell.run(["curl", "-fsSL", "--max-time", "8", "--max-filesize", "1000000", "--proto", "=https", "-A", "Mozilla/5.0 (X11; Linux x86_64)", "--", Market.dataUrl(item)], { timeout: 10000 }).then(r => {
            let quote = null;
            if (r.code === 0) {
                try { quote = item.kind === "tefas" ? Market.parseTefas(r.stdout) : Market.parseChart(r.stdout); } catch (e) {}
            }
            store(item, quote || { error: true });
            done();
        }, () => { store(item, { error: true }); done(); });
    }

    function store(item, quote) {
        quotes = Object.assign({}, quotes, { [item.kind + ":" + item.symbol]: quote });
    }

    onCurrentChanged: if (current) readAll()
    Timer { interval: 60000; repeat: true; running: tab.current; onTriggered: tab.readAll() }

    function open(item) {
        Quickshell.execDetached(["xdg-open", Market.pageUrl(item)]);
        K.Shell.dashboardClosed();
    }

    function key(event) {
        if (!stops.length) return false;
        if (event.key === Qt.Key_Down) selected = (selected + 1) % stops.length;
        else if (event.key === Qt.Key_Up) selected = (selected - 1 + stops.length) % stops.length;
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) open(stops[selected]);
        else return false;
        return true;
    }

    component Panel: C.Card {
        id: panel
        property var items: []
        property int offset: 0
        width: tab.panels.length === 1 ? row.width : (row.width - row.spacing) / 2
        height: tab.panelHeight

        C.Label {
            width: parent.width
            visible: panel.items.length === 0
            wrapMode: Text.Wrap
            secondary: true
            text: "No valid symbols in this panel."
        }

        ListView {
            id: view
            width: parent.width
            height: panel.height - 2 * K.Theme.space.md - 24
            visible: panel.items.length > 0
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: panel.items
            readonly property int chosen: tab.selected - panel.offset
            onChosenChanged: if (chosen >= 0 && chosen < count) positionViewAtIndex(chosen, ListView.Contain)

            // A thin mark, shown only when the list is longer than its panel.
            Rectangle {
                z: 1
                anchors.right: parent.right
                visible: view.contentHeight > view.height
                width: 3
                radius: 1.5
                y: view.contentHeight > 0 ? view.contentY / view.contentHeight * view.height : 0
                height: view.contentHeight > 0 ? view.height * view.height / view.contentHeight : 0
                color: K.Theme.surface[1]
            }

            delegate: Rectangle {
                id: line
                required property var modelData
                required property int index
                readonly property var quote: tab.quoteOf(modelData)
                readonly property bool failed: !!quote && !!quote.error
                readonly property bool ready: !!quote && !quote.error
                readonly property color tone: !ready || quote.change === null || quote.change === 0 ? K.Theme.text.secondary
                    : quote.change > 0 ? K.Theme.state.success : K.Theme.state.error
                width: ListView.view.width
                height: 36
                radius: K.Theme.radius.sm
                color: panel.offset + index === tab.selected ? K.Theme.surface[1] : "transparent"

                C.StateLayer { hovered: mouse.containsMouse; pressed: mouse.pressed }

                Column {
                    anchors { left: parent.left; right: graph.left; leftMargin: K.Theme.space.sm; rightMargin: K.Theme.space.sm; verticalCenter: parent.verticalCenter }
                    C.Label { width: parent.width; elide: Text.ElideRight; font.weight: Font.DemiBold; textFormat: Text.PlainText; text: line.modelData.label }
                    C.Label { width: parent.width; visible: text.length > 0; elide: Text.ElideRight; secondary: true; textFormat: Text.PlainText; font.pixelSize: K.Theme.font.size - 3; text: line.ready ? line.quote.name : "" }
                }
                C.Sparkline {
                    id: graph
                    anchors { right: figures.left; rightMargin: K.Theme.space.sm; verticalCenter: parent.verticalCenter }
                    readonly property var points: line.ready ? Market.shape(line.quote.history) : []
                    visible: points.length > 0
                    track: false
                    linear: true
                    count: 22
                    barWidth: 1
                    height: 20
                    values: points
                    color: line.tone
                }
                Column {
                    id: figures
                    anchors { right: parent.right; rightMargin: K.Theme.space.sm; verticalCenter: parent.verticalCenter }

                    C.Label {
                        anchors.right: parent.right
                        font.features: { "tnum": 1 }
                        textFormat: Text.PlainText
                        secondary: !line.ready
                        text: line.ready ? Market.price(line.quote.price, line.quote.currency) : line.failed ? "Unavailable" : "…"
                    }
                    C.Label {
                        anchors.right: parent.right
                        visible: text.length > 0
                        color: line.tone
                        font.pixelSize: K.Theme.font.size - 2
                        font.features: { "tnum": 1 }
                        text: line.ready ? Market.percent(line.quote.change) : ""
                    }
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tab.open(line.modelData)
                }
            }
        }
    }

    Flickable {
        id: pages
        anchors { top: parent.top; bottom: note.top; left: parent.left; right: parent.right; bottomMargin: K.Theme.space.xs }
        clip: true
        contentHeight: row.height
        boundsBehavior: Flickable.StopAtBounds

        Flow {
            id: row
            width: pages.width
            spacing: K.Theme.space.sm

            Repeater {
                model: tab.panels
                delegate: Panel {
                    required property var modelData
                    required property int index
                    title: modelData.title
                    items: modelData.items
                    offset: tab.offsetOf(index)
                }
            }
        }
    }

    C.Label {
        anchors.centerIn: pages
        width: parent.width - 2 * K.Theme.space.xl
        visible: tab.panels.length === 0
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        secondary: true
        text: "Add panels in Settings under Trade."
    }

    C.Label {
        id: note
        anchors { bottom: parent.bottom; left: parent.left }
        secondary: true
        font.pixelSize: K.Theme.font.size - 3
        text: "Prices may be delayed." + (tab.updated ? "  Updated " + tab.updated : "")
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Shell as K
import qs.services as S
import qs.components as C

// The palette only ranks and displays. All rows come from palette.provider plugins (ADR-0008).
Item {
    id: root
    property var plugin: null
    property string slot: ""

    property bool shown: false
    onShownChanged: shown ? K.Shell.paletteOpened() : K.Shell.paletteClosed()
    readonly property var targetScreen: Quickshell.screens.find(s => s.name === S.Workspaces.focusedOutput) || null
    readonly property int maxResults: K.Settings.get("palette", "maxResults", 50)

    function count(n, noun) { return n + " " + noun + (n === 1 ? "" : "s"); }

    // Actions run once the palette is gone: while it holds the keyboard, a compositor would
    // hand focus straight back to the previous window and undo a Focus action.
    property var pending: null
    function runAfterClose(action) {
        pending = action;
        shown = false;
        afterClose.restart();
    }
    Timer {
        id: afterClose
        interval: 80
        onTriggered: {
            try { root.pending.run(); }
            catch (e) { K.Log.warn("action failed: " + e, "palette"); }
            root.pending = null;
        }
    }

    IpcHandler {
        target: "palette"
        function toggle(): void { root.shown = !root.shown; }
        function open(): void { root.shown = true; }
        function close(): void { root.shown = false; }
    }

    LazyLoader {
        active: root.shown

        PanelWindow {
            id: win
            screen: root.targetScreen
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kotilo-palette"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            property var results: []
            property int total: 0
            property int selected: 0
            property var menuFor: null          // the row whose actions are listed (Tab), else null
            readonly property var rows: menuFor ? menuFor.actions : results

            // Data can change while the palette is open. A row the person chose stays chosen; otherwise
            // the selection stays on top, so Enter always means the current best match.
            property bool navigated: false
            function refresh(keepSelection) {
                const previous = keepSelection && navigated ? results[selected] : null;
                const q = input.text;
                const out = [];
                for (const p of K.Shell.paletteProviders) {
                    let items = [];
                    try { items = p.items(q) || []; }
                    catch (e) { K.Log.warn(p.title + ": " + e, "palette"); }
                    for (const it of items) {
                        const s = it.score !== undefined ? it.score : K.Shell.fuzzyRank(q, it.title, it.keywords);
                        if (s >= 0) out.push(Object.assign({}, it, { provider: p.title, priority: p.priority || 0, rank: s }));
                    }
                }
                out.sort((a, b) => b.rank - a.rank || b.priority - a.priority || a.title.localeCompare(b.title));
                total = out.length;
                results = out.slice(0, root.maxResults);
                if (keepSelection) {
                    selected = Math.max(0, results.findIndex(r => previous && r.title === previous.title && r.subtitle === previous.subtitle));
                    return;
                }
                selected = 0;
                navigated = false;
                menuFor = null;
            }

            function run(row) {
                const action = menuFor ? row : (row.actions || [])[0];
                if (!action) return;
                root.runAfterClose(action);
            }

            // Rows also pass under a resting pointer as results change, and that must not select one.
            property point pointer: Qt.point(-1, -1)
            function pointerMoved(p, index) {
                const first = pointer.x < 0;
                const moved = p.x !== pointer.x || p.y !== pointer.y;
                pointer = p;
                if (moved && !first) { selected = index; navigated = true; }
            }

            function move(delta) {
                if (!rows.length) return;
                selected = (selected + delta + rows.length) % rows.length;
                navigated = true;
            }

            function openMenu() {
                if (menuFor) { menuFor = null; selected = 0; return; }
                const row = results[selected];
                if (row && row.actions && row.actions.length) { menuFor = row; selected = 0; }
            }

            Connections {
                target: K.Shell
                function onPaletteProvidersChanged() { win.refresh(); }
                function onPaletteDataChanged() { if (!win.menuFor) win.refresh(true); }
            }

            MouseArea { anchors.fill: parent; onClicked: root.shown = false }

            C.Surface {
                id: panel
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.round(parent.height * 0.18)
                width: Math.min(640, parent.width - 2 * K.Theme.space.lg)
                height: column.implicitHeight
                clip: true

                NumberAnimation on opacity { from: 0; to: 1; duration: K.Theme.animMs }
                MouseArea { anchors.fill: parent }

                Column {
                    id: column
                    width: parent.width

                    Item {
                        width: parent.width
                        height: 52

                        TextInput {
                            id: input
                            anchors { fill: parent; leftMargin: K.Theme.space.lg; rightMargin: K.Theme.space.lg }
                            verticalAlignment: TextInput.AlignVCenter
                            color: K.Theme.text.primary
                            selectionColor: K.Theme.accent.primary
                            selectedTextColor: K.Theme.text.onAccent
                            font.family: K.Theme.font.ui
                            font.pixelSize: K.Theme.font.size + 3
                            focus: true
                            onTextChanged: win.refresh()
                            Component.onCompleted: { forceActiveFocus(); win.refresh(); }

                            Keys.onPressed: event => {
                                const ctrl = event.modifiers & Qt.ControlModifier;
                                if (event.key === Qt.Key_Escape) {
                                    if (win.menuFor) win.openMenu(); else root.shown = false;
                                } else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_N)) win.move(1);
                                else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_P)) win.move(-1);
                                else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) win.openMenu();
                                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (win.rows.length) win.run(win.rows[win.selected]);
                                } else return;
                                event.accepted = true;
                            }

                            C.Label {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: input.text.length === 0
                                secondary: true
                                font.pixelSize: input.font.pixelSize
                                text: win.menuFor ? win.menuFor.title : "Search"
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: K.Theme.surface[1] }

                    ListView {
                        id: list
                        width: parent.width
                        height: Math.min(contentHeight, 44 * 8)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: win.rows
                        currentIndex: win.selected
                        highlightMoveDuration: 0

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 44
                            color: index === win.selected ? K.Theme.surface[0] : "transparent"

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onPositionChanged: mouse => win.pointerMoved(mapToItem(null, mouse.x, mouse.y), index)
                                onClicked: win.run(modelData)
                            }

                            Row {
                                anchors { fill: parent; leftMargin: K.Theme.space.lg; rightMargin: K.Theme.space.lg }
                                spacing: K.Theme.space.md

                                Image {
                                    id: rowIcon
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !!modelData.icon
                                    width: 24; height: 24
                                    sourceSize: Qt.size(48, 48)
                                    asynchronous: true
                                    source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - (rowIcon.visible ? rowIcon.width + K.Theme.space.md : 0) - tag.width - K.Theme.space.md

                                    C.Label {
                                        width: parent.width
                                        elide: Text.ElideRight
                                        text: modelData.title
                                    }
                                    C.Label {
                                        width: parent.width
                                        visible: text.length > 0
                                        elide: Text.ElideRight
                                        secondary: index !== win.selected
                                        font.pixelSize: K.Theme.font.size - 2
                                        text: modelData.subtitle || ""
                                    }
                                }

                                C.Label {
                                    id: tag
                                    anchors.verticalCenter: parent.verticalCenter
                                    secondary: index !== win.selected
                                    font.pixelSize: K.Theme.font.size - 2
                                    text: modelData.provider || ""
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 44
                        visible: win.rows.length === 0

                        C.Label {
                            anchors.centerIn: parent
                            secondary: true
                            text: K.Shell.paletteProviders.length ? "No results" : "No providers loaded"
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: K.Theme.surface[1] }

                    Item {
                        width: parent.width
                        height: 32

                        C.Label {
                            anchors { left: parent.left; leftMargin: K.Theme.space.lg; verticalCenter: parent.verticalCenter }
                            secondary: true
                            font.pixelSize: K.Theme.font.size - 2
                            text: root.count(win.total, "result") + " · " + root.count(K.Shell.paletteProviders.length, "provider")
                        }
                        C.Label {
                            anchors { right: parent.right; rightMargin: K.Theme.space.lg; verticalCenter: parent.verticalCenter }
                            secondary: true
                            font.pixelSize: K.Theme.font.size - 2
                            text: win.menuFor ? "↵ run   esc back" : "↵ open   ⇥ actions   esc close"
                        }
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Shell as K
import qs.services as S
import qs.components as C

// A large panel of tabs: the dashboard.card slot, then the dashboard.tab slot (ADR-0015, ADR-0017).
// Everything inside exists only while the panel is open.
Item {
    id: root
    property var plugin: null
    property string slot: ""
    property var host: null

    property bool shown: false
    property int tab: 0                         // kept between openings
    readonly property var targetScreen: Quickshell.screens.find(s => s.name === S.Workspaces.focusedOutput) || null

    IpcHandler {
        target: "dashboard"
        function toggle(): void { root.shown = !root.shown; }
        function open(): void { root.shown = true; }
        function close(): void { root.shown = false; }
    }

    onPluginChanged: if (plugin) K.Shell.registerPaletteAction(plugin, { title: "Open overview", exec: () => { root.shown = true; } })
    Component.onDestruction: if (plugin) K.Shell.unregisterPaletteActions(plugin)

    Connections {
        target: K.Shell
        function onDashboardClosed() { root.shown = false; }
        function onDashboardToggled() { root.shown = !root.shown; }
    }

    C.Reveal { id: reveal; open: root.shown }

    LazyLoader {
        active: reveal.alive

        PanelWindow {
            id: win
            screen: root.targetScreen
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kotilo-dashboard"
            WlrLayershell.keyboardFocus: reveal.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            readonly property var tabEntries: root.host && root.host.ready ? root.host.slot("dashboard.tab") : []
            readonly property var titles: [{ name: "Overview", icon: "dashboard" }]
                .concat(tabEntries.map(t => ({ name: t.manifest.name.replace(/ tab$/, ""), icon: t.manifest.icon || "dashboard" })))
            readonly property int barInset: {
                const bar = K.Settings.global.bar || {};
                return bar.position === "bottom" ? 0 : K.Theme.barSize(bar.height || 36);
            }

            function show(index) { if (index >= 0 && index < titles.length) root.tab = index; }

            MouseArea { anchors.fill: parent; onClicked: root.shown = false }

            C.Surface {
                anchors.horizontalCenter: parent.horizontalCenter
                y: win.barInset + K.Theme.space.sm
                width: Math.min(860, parent.width - 2 * K.Theme.space.lg)
                height: Math.min(520, parent.height - win.barInset - 2 * K.Theme.space.sm)
                radius: K.Theme.radius.lg * 1.5

                opacity: reveal.progress
                enabled: reveal.open
                transform: Translate { y: (1 - reveal.progress) * -K.Theme.space.sm }
                MouseArea { anchors.fill: parent }

                Item {
                    id: keys
                    anchors { fill: parent; margins: K.Theme.space.lg }
                    focus: true
                    Component.onCompleted: forceActiveFocus()

                    Keys.onPressed: event => {
                        const key = event.key;
                        const count = win.titles.length;
                        if (key === Qt.Key_Escape) root.shown = false;
                        else if (key === Qt.Key_Right) win.show((root.tab + 1) % count);
                        else if (key === Qt.Key_Left) win.show((root.tab - 1 + count) % count);
                        else if (key >= Qt.Key_1 && key <= Qt.Key_9) win.show(key - Qt.Key_1);
                        else {
                            const page = pages.itemAt(root.tab - 1);
                            if (!page || !page.item || !page.item.key || !page.item.key(event)) return;
                        }
                        event.accepted = true;
                    }

                    Row {
                        id: tabBar
                        width: parent.width
                        height: 54

                        Repeater {
                            model: win.titles

                            delegate: Item {
                                id: tabButton
                                required property var modelData
                                required property int index
                                readonly property bool chosen: index === root.tab
                                readonly property color tone: chosen ? K.Theme.accent.primary : K.Theme.text.secondary
                                width: parent.width / win.titles.length
                                height: parent.height

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: K.Theme.space.xs
                                    radius: K.Theme.radius.sm
                                    color: "transparent"
                                    C.StateLayer { hovered: tabMouse.containsMouse; pressed: tabMouse.pressed }
                                }
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    C.Icon { anchors.horizontalCenter: parent.horizontalCenter; name: tabButton.modelData.icon; size: 18; color: tabButton.tone }
                                    C.Label { anchors.horizontalCenter: parent.horizontalCenter; textFormat: Text.PlainText; color: tabButton.tone; text: tabButton.modelData.name }
                                }
                                Rectangle {
                                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                                    visible: tabButton.chosen
                                    width: Math.min(76, parent.width * 0.7)
                                    height: 3
                                    radius: 1.5
                                    color: K.Theme.accent.primary
                                }
                                MouseArea {
                                    id: tabMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.tab = tabButton.index
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: tabLine
                        anchors { top: tabBar.bottom; left: parent.left; right: parent.right }
                        height: 1
                        color: K.Theme.surface[0]
                    }

                    Item {
                        anchors { top: tabLine.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; topMargin: K.Theme.space.md }

                        // Each card places itself with `area`, fractions of this grid. A third-party card
                        // without one takes the free space a Card fills: a row of its own below.
                        Item {
                            id: grid
                            anchors.fill: parent
                            visible: root.tab === 0
                            readonly property int gap: K.Theme.space.sm

                            Repeater {
                                model: root.host && root.host.ready ? root.host.slot("dashboard.card") : []

                                delegate: Loader {
                                    required property var modelData
                                    readonly property var area: item && item.area ? item.area : ({ x: 0, y: 1, w: 1, h: 0.2 })
                                    x: area.x * (grid.width + grid.gap)
                                    y: area.y * (grid.height + grid.gap)
                                    width: area.w * (grid.width + grid.gap) - grid.gap
                                    height: area.h * (grid.height + grid.gap) - grid.gap
                                    source: modelData.url
                                    onLoaded: {
                                        item.plugin = modelData;
                                        item.slot = "dashboard.card";
                                        item.width = Qt.binding(() => width);
                                        item.height = Qt.binding(() => height);
                                    }
                                    onStatusChanged: if (status === Loader.Error) K.Log.error("failed to mount " + modelData.id, "dashboard")
                                }
                            }
                        }

                        Repeater {
                            id: pages
                            model: win.tabEntries

                            // A tab loads on its first visit and stays until the panel closes.
                            delegate: Loader {
                                required property var modelData
                                required property int index
                                readonly property bool showing: root.tab === index + 1
                                property bool visited: false
                                onShowingChanged: if (showing) visited = true
                                Component.onCompleted: visited = showing
                                anchors.fill: parent
                                visible: showing
                                active: visited
                                source: modelData.url
                                onLoaded: {
                                    item.plugin = modelData;
                                    item.slot = "dashboard.tab";
                                    item.current = Qt.binding(() => showing);
                                }
                                onStatusChanged: if (status === Loader.Error) K.Log.error("failed to mount " + modelData.id, "dashboard")
                            }
                        }
                    }
                }
            }
        }
    }
}

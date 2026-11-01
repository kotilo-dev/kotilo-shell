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

    onPluginChanged: if (plugin) K.Shell.registerPaletteAction(plugin, { title: "Open dashboard", exec: () => { root.shown = true; } })
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
            readonly property var titles: ["Dashboard"].concat(tabEntries.map(t => t.manifest.name.replace(/ tab$/, "")))
            readonly property int barInset: {
                const bar = K.Settings.global.bar || {};
                return bar.position === "bottom" ? 0 : K.Theme.barSize(bar.height || 36);
            }

            function show(index) { if (index >= 0 && index < titles.length) root.tab = index; }

            MouseArea { anchors.fill: parent; onClicked: root.shown = false }

            C.Surface {
                anchors.horizontalCenter: parent.horizontalCenter
                y: win.barInset + K.Theme.space.sm
                width: Math.min(1000, parent.width - 2 * K.Theme.space.lg)
                height: parent.height - win.barInset - 2 * K.Theme.space.sm

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
                        spacing: K.Theme.space.xs

                        Repeater {
                            model: win.titles

                            delegate: Rectangle {
                                id: tabButton
                                required property var modelData
                                required property int index
                                readonly property bool chosen: index === root.tab
                                width: tabLabel.implicitWidth + 2 * K.Theme.space.md
                                height: 32
                                radius: K.Theme.radius.sm
                                color: chosen ? K.Theme.surface[0] : "transparent"

                                C.StateLayer { hovered: tabMouse.containsMouse; pressed: tabMouse.pressed }
                                C.Label {
                                    id: tabLabel
                                    anchors.centerIn: parent
                                    textFormat: Text.PlainText
                                    color: tabButton.chosen ? K.Theme.text.primary : K.Theme.text.secondary
                                    text: tabButton.modelData
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

                    Item {
                        anchors { top: tabBar.bottom; bottom: hints.top; left: parent.left; right: parent.right; topMargin: K.Theme.space.md; bottomMargin: K.Theme.space.sm }

                        Flickable {
                            anchors.fill: parent
                            visible: root.tab === 0
                            clip: true
                            contentHeight: flow.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds

                            Flow {
                                id: flow
                                width: parent.width
                                spacing: K.Theme.space.md

                                Repeater {
                                    model: root.host && root.host.ready ? root.host.slot("dashboard.card") : []

                                    delegate: Loader {
                                        required property var modelData
                                        width: (flow.width - flow.spacing) / 2
                                        source: modelData.url
                                        onLoaded: {
                                            item.plugin = modelData;
                                            item.slot = "dashboard.card";
                                            item.width = Qt.binding(() => width);
                                        }
                                        onStatusChanged: if (status === Loader.Error) K.Log.error("failed to mount " + modelData.id, "dashboard")
                                    }
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

                    C.Label {
                        id: hints
                        anchors { bottom: parent.bottom; left: parent.left }
                        secondary: true
                        font.pixelSize: K.Theme.font.size - 2
                        text: "←→ or 1–" + win.titles.length + " tabs   ↑↓ move   ↵ open   esc close"
                    }
                }
            }
        }
    }
}

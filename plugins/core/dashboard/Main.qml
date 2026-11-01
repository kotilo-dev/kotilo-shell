// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Shell as K
import qs.services as S
import qs.components as C

// Cards from the dashboard.card slot (ADR-0015). They exist only while the panel is open.
Item {
    id: root
    property var plugin: null
    property string slot: ""
    property var host: null

    property bool shown: false
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
            WlrLayershell.namespace: "kotilo-dashboard"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            MouseArea { anchors.fill: parent; onClicked: root.shown = false }

            C.Surface {
                id: surface
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.round(parent.height * 0.08)
                width: Math.min(860, parent.width - 2 * K.Theme.space.lg)
                height: Math.min(parent.height * 0.84, flow.implicitHeight + heading.implicitHeight + 3 * K.Theme.space.lg + K.Theme.space.md)
                clip: true

                NumberAnimation on opacity { from: 0; to: 1; duration: K.Theme.animMs }
                MouseArea { anchors.fill: parent }

                Item {
                    anchors.fill: parent
                    focus: true
                    Component.onCompleted: forceActiveFocus()
                    Keys.onEscapePressed: root.shown = false

                    C.Label {
                        id: heading
                        anchors { top: parent.top; left: parent.left; margins: K.Theme.space.lg }
                        font.pixelSize: K.Theme.font.size + 2
                        text: "Dashboard"
                    }

                    Flickable {
                        anchors {
                            top: heading.bottom; bottom: parent.bottom; left: parent.left; right: parent.right
                            topMargin: K.Theme.space.md; bottomMargin: K.Theme.space.lg
                            leftMargin: K.Theme.space.lg; rightMargin: K.Theme.space.lg
                        }
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
                }
            }
        }
    }
}

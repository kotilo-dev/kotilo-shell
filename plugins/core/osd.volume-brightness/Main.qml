// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Shell as K
import qs.services as S
import qs.components as C

Item {
    id: root
    property var plugin: null
    property string slot: ""

    property string kind: ""            // "volume" | "brightness"
    property bool armed: false
    readonly property bool isVolume: kind === "volume"
    readonly property int percent: isVolume ? S.Audio.percent : S.Brightness.percent
    readonly property string iconName: isVolume ? S.Audio.icon() : "sun"
    readonly property var targetScreen: Quickshell.screens.find(s => s.name === S.Workspaces.focusedOutput) || null

    function show(what) {
        if (!armed) return;
        kind = what;
        hide.restart();
    }

    // Values settle at startup and on a device switch. Those are not changes the user made.
    function settle() {
        armed = false;
        arm.restart();
    }
    Component.onCompleted: settle()
    Timer { id: arm; interval: 1500; onTriggered: root.armed = true }

    Timer {
        id: hide
        interval: K.Settings.get("osd.volume-brightness", "timeout", 1200)
        onTriggered: root.kind = ""
    }

    Connections {
        target: S.Audio
        function onPercentChanged() { root.show("volume"); }
        function onMutedChanged() { root.show("volume"); }
        function onSinkChanged() { root.settle(); }
    }

    Connections {
        target: S.Brightness
        function onPercentChanged() { root.show("brightness"); }
        function onReadyChanged() { root.settle(); }
    }

    LazyLoader {
        active: root.kind.length > 0

        PanelWindow {
            screen: root.targetScreen
            anchors.bottom: true
            margins.bottom: K.Theme.space.xl * 3
            implicitWidth: 280
            implicitHeight: 52
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}                // clicks pass through
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kotilo-osd"

            C.Surface {
                shadow: false
                anchors.fill: parent
                NumberAnimation on opacity { from: 0; to: 1; duration: K.Theme.animMs }

                Row {
                    anchors.centerIn: parent
                    spacing: K.Theme.space.md

                    C.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: root.iconName
                        size: 18
                        color: K.Theme.accent.primary
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 170
                        height: 6
                        radius: height / 2
                        color: K.Theme.surface[0]

                        Rectangle {
                            width: parent.width * Math.min(1, root.percent / 100)
                            height: parent.height
                            radius: parent.radius
                            color: S.Audio.muted && root.isVolume ? K.Theme.text.muted : K.Theme.accent.primary
                        }
                    }

                    C.Label {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        horizontalAlignment: Text.AlignRight
                        mono: true
                        text: root.percent + "%"
                    }
                }
            }
        }
    }
}

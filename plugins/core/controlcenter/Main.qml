// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.Shell as K
import qs.services as S
import qs.components as C

// Quick tiles from the controlcenter.tile slot, sliders, theme swatches and the media card.
Item {
    id: root
    property var plugin: null
    property string slot: ""
    property var host: null

    property bool shown: false
    onShownChanged: if (shown) K.Theme.scan()
    readonly property var targetScreen: Quickshell.screens.find(s => s.name === S.Workspaces.focusedOutput) || null

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { root.shown = !root.shown; }
        function open(): void { root.shown = true; }
        function close(): void { root.shown = false; }
    }

    Connections {
        target: K.Shell
        function onControlCenterToggled() { root.shown = !root.shown; }
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
            WlrLayershell.namespace: "kotilo-controlcenter"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            PwObjectTracker { objects: S.Audio.streams }

            readonly property var tileEntries: root.host && root.host.ready ? root.host.slot("controlcenter.tile") : []

            // Everything the keyboard can reach, in visual order.
            readonly property var stops: {
                const list = tileEntries.map((t, i) => ({ kind: "tile", index: i }));
                if (S.Audio.ready) list.push({ kind: "volume" });
                if (S.Brightness.ready) list.push({ kind: "brightness" });
                S.Audio.streams.forEach((n, i) => list.push({ kind: "stream", index: i }));
                K.Theme.schemes.forEach((s, i) => list.push({ kind: "theme", index: i }));
                if (S.Mpris.ready) ["previous", "toggle", "next"].forEach(a => list.push({ kind: "media", action: a }));
                return list;
            }
            property int cursor: 0
            readonly property var stop: stops[Math.min(cursor, stops.length - 1)] || ({})

            function isAt(kind, key) {
                return stop.kind === kind && (key === undefined || stop.index === key || stop.action === key);
            }

            function move(delta) {
                if (stops.length) cursor = (cursor + delta + stops.length) % stops.length;
            }

            function adjust(delta) {
                if (stop.kind === "volume") S.Audio.step(delta);
                else if (stop.kind === "brightness") S.Brightness.step(delta * 100);
                else if (stop.kind === "stream") {
                    const audio = S.Audio.streams[stop.index].audio;
                    audio.volume = Math.max(0, Math.min(1, audio.volume + delta));
                } else move(delta > 0 ? 1 : -1);
            }

            function activate() {
                if (stop.kind === "tile") tileRepeater.itemAt(stop.index).item.activate();
                else if (stop.kind === "volume") S.Audio.toggleMute();
                else if (stop.kind === "stream") {
                    const audio = S.Audio.streams[stop.index].audio;
                    audio.muted = !audio.muted;
                } else if (stop.kind === "theme") K.Settings.setTheme(K.Theme.schemes[stop.index].id);
                else if (stop.kind === "media") S.Mpris[stop.action]();
            }

            MouseArea { anchors.fill: parent; onClicked: root.shown = false }

            C.Surface {
                anchors { top: parent.top; right: parent.right; margins: K.Theme.space.sm }
                width: 400
                height: Math.min(parent.height - 2 * K.Theme.space.sm, content.implicitHeight + 2 * K.Theme.space.lg)
                clip: true

                NumberAnimation on opacity { from: 0; to: 1; duration: K.Theme.animMs }
                MouseArea { anchors.fill: parent }

                Item {
                    anchors.fill: parent
                    focus: true
                    Component.onCompleted: forceActiveFocus()

                    Keys.onPressed: event => {
                        const key = event.key;
                        if (key === Qt.Key_Escape) root.shown = false;
                        else if (key === Qt.Key_Down || key === Qt.Key_Tab) win.move(1);
                        else if (key === Qt.Key_Up || key === Qt.Key_Backtab) win.move(-1);
                        else if (key === Qt.Key_Right) win.adjust(0.05);
                        else if (key === Qt.Key_Left) win.adjust(-0.05);
                        else if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space) win.activate();
                        else return;
                        event.accepted = true;
                    }

                    Flickable {
                        anchors { fill: parent; margins: K.Theme.space.lg }
                        contentHeight: content.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: content
                            width: parent.width
                            spacing: K.Theme.space.lg

                            Grid {
                                id: tiles
                                width: parent.width
                                columns: 3
                                spacing: K.Theme.space.sm

                                Repeater {
                                    id: tileRepeater
                                    model: win.tileEntries

                                    delegate: Loader {
                                        required property var modelData
                                        required property int index
                                        width: (tiles.width - 2 * tiles.spacing) / 3
                                        sourceComponent: modelData.component
                                        onLoaded: {
                                            item.plugin = modelData;
                                            item.slot = "controlcenter.tile";
                                            item.selected = Qt.binding(() => win.isAt("tile", index));
                                            item.width = Qt.binding(() => width);
                                        }
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: K.Theme.space.sm
                                visible: S.Audio.ready || S.Brightness.ready

                                C.Slider {
                                    width: parent.width
                                    visible: S.Audio.ready
                                    icon: S.Audio.icon()
                                    value: S.Audio.volume
                                    selected: win.isAt("volume")
                                    onMoved: v => S.Audio.setVolume(v)
                                    onIconClicked: S.Audio.toggleMute()
                                }
                                C.Slider {
                                    width: parent.width
                                    visible: S.Brightness.ready
                                    icon: "sun"
                                    value: S.Brightness.percent / 100
                                    selected: win.isAt("brightness")
                                    onMoved: v => S.Brightness.setPercent(v * 100)
                                }
                                Repeater {
                                    model: S.Audio.streams

                                    delegate: C.Slider {
                                        required property var modelData
                                        required property int index
                                        width: parent.width
                                        label: S.Audio.streamName(modelData)
                                        value: modelData.audio.volume
                                        selected: win.isAt("stream", index)
                                        onMoved: v => modelData.audio.volume = v
                                    }
                                }
                            }

                            Flow {
                                width: parent.width
                                spacing: K.Theme.space.sm

                                Repeater {
                                    model: K.Theme.schemes

                                    delegate: Rectangle {
                                        required property var modelData
                                        required property int index
                                        readonly property bool current: modelData.id === K.Theme.schemeId
                                        width: 32; height: 32
                                        radius: K.Theme.radius.sm
                                        color: modelData.bg
                                        border.width: win.isAt("theme", index) || current ? 2 : 1
                                        border.color: win.isAt("theme", index) ? K.Theme.text.primary : (current ? K.Theme.accent.primary : K.Theme.surface[1])

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 14; height: 14
                                            radius: width / 2
                                            color: parent.modelData.accent
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: K.Settings.setTheme(parent.modelData.id)
                                        }
                                    }
                                }
                            }

                            C.Surface {
                                level: 1
                                width: parent.width
                                visible: S.Mpris.ready
                                height: 72

                                Row {
                                    anchors { fill: parent; margins: K.Theme.space.md }
                                    spacing: K.Theme.space.md

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - controls.width - K.Theme.space.md

                                        C.Label {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            textFormat: Text.PlainText
                                            text: S.Mpris.ready ? (S.Mpris.player.trackTitle || S.Mpris.player.identity) : ""
                                        }
                                        C.Label {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            secondary: true
                                            textFormat: Text.PlainText
                                            font.pixelSize: K.Theme.font.size - 2
                                            text: S.Mpris.ready ? S.Mpris.player.trackArtist : ""
                                        }
                                    }

                                    Row {
                                        id: controls
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: K.Theme.space.xs

                                        Repeater {
                                            model: [
                                                { action: "previous", icon: "media-previous" },
                                                { action: "toggle", icon: S.Mpris.ready && S.Mpris.player.isPlaying ? "media-pause" : "media-play" },
                                                { action: "next", icon: "media-next" }
                                            ]

                                            delegate: Rectangle {
                                                required property var modelData
                                                width: 32; height: 32
                                                radius: K.Theme.radius.sm
                                                color: win.isAt("media", modelData.action) ? K.Theme.surface[1] : "transparent"

                                                C.Icon {
                                                    anchors.centerIn: parent
                                                    name: parent.modelData.icon
                                                    size: 16
                                                    color: K.Theme.text.primary
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: S.Mpris[parent.modelData.action]()
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            C.Label {
                                secondary: true
                                font.pixelSize: K.Theme.font.size - 2
                                text: "⇥ move   ←→ adjust   ↵ toggle   esc close"
                            }
                        }
                    }
                }
            }
        }
    }
}

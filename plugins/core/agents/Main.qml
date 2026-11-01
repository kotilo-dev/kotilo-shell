// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Shell as K
import qs.services as S
import qs.components as C

// Approval popups and the agents panel. An answer lets a program run a command, so it always
// takes a deliberate act: see the safety rules in docs/adr/0003.
Item {
    id: root
    property var plugin: null
    property string slot: ""

    property bool panelOpen: false
    readonly property var targetScreen: Quickshell.screens.find(s => s.name === S.Workspaces.focusedOutput) || null

    function title(request) {
        const agent = S.Agents.agentFor(request.agent);
        return agent ? (agent.tool + (agent.project ? " · " + agent.project : "")) : "Agent";
    }

    // Open and close only. Answering here would let any script approve a command.
    IpcHandler {
        target: "agents"
        function toggle(): void { root.panelOpen = !root.panelOpen; }
        function open(): void { root.panelOpen = true; }
        function close(): void { root.panelOpen = false; }
    }

    Connections {
        target: K.Shell
        function onAgentsToggled() { root.panelOpen = !root.panelOpen; }
    }

    component Button: Rectangle {
        id: button
        property string text: ""
        property color tint: K.Theme.surface[1]
        property color ink: K.Theme.text.primary
        signal clicked()
        width: label.implicitWidth + 2 * K.Theme.space.lg
        height: 30
        radius: K.Theme.radius.sm
        color: tint

        C.StateLayer { hovered: buttonMouse.containsMouse; pressed: buttonMouse.pressed; color: button.ink }
        C.Label { id: label; anchors.centerIn: parent; color: button.ink; text: button.text }
        MouseArea { id: buttonMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: button.clicked() }
    }

    component Request: C.Surface {
        id: card
        required property var request
        property int maxLines: 0               // 0 shows the whole command
        property bool highlighted: false
        readonly property bool hiddenText: command.truncated
        level: 1
        border.width: 1
        width: parent ? parent.width : 0
        implicitHeight: column.implicitHeight + 2 * K.Theme.space.md
        height: implicitHeight
        color: highlighted ? K.Theme.surface[0] : K.Theme.bg.base
        border.color: K.Theme.state.warning

        Column {
            id: column
            x: K.Theme.space.md
            y: K.Theme.space.md
            width: parent.width - 2 * K.Theme.space.md
            spacing: K.Theme.space.sm

            C.Label {
                width: parent.width
                elide: Text.ElideRight
                textFormat: Text.PlainText
                secondary: !card.highlighted
                font.pixelSize: K.Theme.font.size - 2
                text: root.title(card.request) + " asks to run"
            }
            C.Label {
                id: command
                width: parent.width
                mono: true
                wrapMode: Text.WrapAnywhere
                textFormat: Text.PlainText
                maximumLineCount: card.maxLines > 0 ? card.maxLines : 100000
                elide: card.maxLines > 0 ? Text.ElideRight : Text.ElideNone
                text: card.request.command
            }
            C.Label {
                width: parent.width
                visible: card.request.cwd.length > 0
                elide: Text.ElideMiddle
                textFormat: Text.PlainText
                secondary: !card.highlighted
                font.pixelSize: K.Theme.font.size - 2
                text: "in " + card.request.cwd
            }
            C.Label {
                width: parent.width
                visible: card.hiddenText
                wrapMode: Text.Wrap
                color: K.Theme.state.warning
                font.pixelSize: K.Theme.font.size - 2
                text: "Too long to judge here. Open the agents panel to see all of it."
            }
            Row {
                spacing: K.Theme.space.sm
                Button {
                    visible: !card.hiddenText
                    text: "Allow"
                    tint: K.Theme.accent.primary
                    ink: K.Theme.text.onAccent
                    onClicked: S.Agents.answer(card.request.id, true)
                }
                Button { text: "Deny"; onClicked: S.Agents.answer(card.request.id, false) }
            }
        }
    }

    // Top center, away from notifications. Never takes the keyboard: a stray Enter must not approve.
    LazyLoader {
        active: S.Agents.approvals.length > 0 && !root.panelOpen

        PanelWindow {
            screen: root.targetScreen
            anchors.top: true
            margins.top: K.Theme.space.sm
            implicitWidth: 520
            implicitHeight: popups.implicitHeight
            exclusionMode: ExclusionMode.Normal
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kotilo-approvals"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Column {
                id: popups
                width: parent.width
                spacing: K.Theme.space.sm

                Repeater {
                    model: S.Agents.approvals
                    delegate: Request {
                        required property var modelData
                        request: modelData
                        maxLines: 6
                    }
                }
            }
        }
    }

    C.Reveal { id: reveal; open: root.panelOpen }

    LazyLoader {
        active: reveal.alive

        PanelWindow {
            id: panel
            screen: root.targetScreen
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kotilo-agents-panel"
            WlrLayershell.keyboardFocus: reveal.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            property int selected: 0
            readonly property var requests: S.Agents.approvals
            onRequestsChanged: selected = Math.max(0, Math.min(selected, requests.length - 1))

            function move(delta) {
                if (requests.length) selected = (selected + delta + requests.length) % requests.length;
            }
            function answer(allow) {
                const r = requests[selected];
                // No yes to text that has not been on screen.
                if (r && (!allow || scroller.atYEnd)) S.Agents.answer(r.id, allow);
            }
            function page(delta) {
                const end = Math.max(0, scroller.contentHeight - scroller.height);
                scroller.contentY = Math.max(0, Math.min(end, scroller.contentY + delta * scroller.height * 0.9));
            }

            MouseArea { anchors.fill: parent; onClicked: root.panelOpen = false }

            C.Surface {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.round(parent.height * 0.12)
                width: Math.min(640, parent.width - 2 * K.Theme.space.lg)
                height: Math.min(parent.height * 0.76, content.implicitHeight + 2 * K.Theme.space.lg)

                opacity: reveal.progress
                enabled: reveal.open
                transform: Translate { y: (1 - reveal.progress) * K.Theme.space.sm }
                MouseArea { anchors.fill: parent }

                Item {
                    anchors.fill: parent
                    focus: true
                    Component.onCompleted: forceActiveFocus()

                    // Answers are a and d only. Enter is what a person presses by reflex.
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) root.panelOpen = false;
                        else if (event.key === Qt.Key_Down) panel.move(1);
                        else if (event.key === Qt.Key_Up) panel.move(-1);
                        else if (event.key === Qt.Key_PageDown) panel.page(1);
                        else if (event.key === Qt.Key_PageUp) panel.page(-1);
                        else if (event.key === Qt.Key_A && event.modifiers === Qt.NoModifier) panel.answer(true);
                        else if (event.key === Qt.Key_D && event.modifiers === Qt.NoModifier) panel.answer(false);
                        else return;
                        event.accepted = true;
                    }

                    Flickable {
                        id: scroller
                        anchors { fill: parent; margins: K.Theme.space.lg }
                        contentHeight: content.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: content
                            width: parent.width
                            spacing: K.Theme.space.md

                            C.Label { font.pixelSize: K.Theme.font.size + 2; text: "Agents" }

                            Repeater {
                                model: panel.requests
                                delegate: Request {
                                    required property var modelData
                                    required property int index
                                    request: modelData
                                    highlighted: index === panel.selected
                                }
                            }

                            Repeater {
                                model: S.Agents.agents
                                delegate: Item {
                                    required property var modelData
                                    width: parent.width
                                    height: 24

                                    C.Label {
                                        anchors { left: parent.left; right: state.left; rightMargin: K.Theme.space.md; verticalCenter: parent.verticalCenter }
                                        elide: Text.ElideRight
                                        textFormat: Text.PlainText
                                        text: parent.modelData.tool + (parent.modelData.project ? " · " + parent.modelData.project : "")
                                    }
                                    C.Label {
                                        id: state
                                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                        secondary: true
                                        text: parent.modelData.state
                                    }
                                }
                            }

                            C.Label {
                                visible: panel.requests.length === 0 && S.Agents.agents.length === 0
                                secondary: true
                                text: "No agents running"
                            }

                            C.Label {
                                secondary: true
                                font.pixelSize: K.Theme.font.size - 2
                                text: panel.requests.length ? "a allow   d deny   pgdn scroll   ↑↓ move   esc close" : "esc close"
                            }
                        }
                    }
                }
            }
        }
    }
}

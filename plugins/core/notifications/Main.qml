// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications as N
import Quickshell.Wayland
import qs.Shell as K
import qs.services as S
import qs.components as C

// Popups and the history panel. State lives in services/Notifications.qml.
Item {
    id: root
    property var plugin: null
    property string slot: ""

    property bool panelOpen: false
    readonly property var targetScreen: Quickshell.screens.find(s => s.name === S.Workspaces.focusedOutput) || null

    function imageFor(n) {
        if (n.image) return n.image;
        return n.appIcon ? Quickshell.iconPath(n.appIcon, true) : "";
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { root.panelOpen = S.Notifications.owning && !root.panelOpen; }
        function clear(): void { S.Notifications.clear(); }
    }

    Connections {
        target: S.Notifications
        function onOpenRequested() { root.panelOpen = !root.panelOpen; }
        function onOwningChanged() { if (!S.Notifications.owning) root.panelOpen = false; }
    }

    // One notification. Used by the popups and the panel.
    component Card: C.Surface {
        id: card
        required property var notification
        property bool highlighted: false
        property int chosenAction: -1
        readonly property bool critical: notification.urgency === N.NotificationUrgency.Critical
        level: 1
        width: parent ? parent.width : 0
        implicitHeight: content.implicitHeight + 2 * K.Theme.space.md
        height: implicitHeight
        color: highlighted ? K.Theme.surface[0] : K.Theme.bg.base
        border.color: critical ? K.Theme.state.error : K.Theme.surface[1]

        Row {
            id: content
            x: K.Theme.space.md
            y: K.Theme.space.md
            width: parent.width - 2 * K.Theme.space.md
            spacing: K.Theme.space.md

            Image {
                id: picture
                visible: source.toString().length > 0
                width: 32; height: 32
                sourceSize: Qt.size(64, 64)
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                source: root.imageFor(card.notification)
            }

            Column {
                width: parent.width - (picture.visible ? picture.width + K.Theme.space.md : 0)
                spacing: K.Theme.space.xs

                C.Label {
                    width: parent.width
                    elide: Text.ElideRight
                    secondary: !card.highlighted
                    font.pixelSize: K.Theme.font.size - 2
                    text: card.notification.appName
                }
                C.Label {
                    width: parent.width
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: card.notification.summary
                }
                C.Label {
                    width: parent.width
                    visible: text.length > 0
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    secondary: !card.highlighted
                    font.weight: Font.Normal
                    text: card.notification.body
                }

                Row {
                    visible: card.notification.actions.length > 0
                    spacing: K.Theme.space.sm

                    Repeater {
                        model: card.notification.actions

                        delegate: Rectangle {
                            id: actionButton
                            required property var modelData
                            required property int index
                            readonly property bool chosen: index === card.chosenAction
                            width: actionLabel.implicitWidth + 2 * K.Theme.space.md
                            height: 28
                            radius: K.Theme.radius.sm
                            color: chosen ? K.Theme.accent.primary : K.Theme.surface[1]

                            C.Label {
                                id: actionLabel
                                anchors.centerIn: parent
                                textFormat: Text.PlainText
                                color: actionButton.chosen ? K.Theme.text.onAccent : K.Theme.text.primary
                                text: parent.modelData.text
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: parent.modelData.invoke()
                            }
                        }
                    }
                }
            }
        }
    }

    // Popups never take the keyboard, and only the cards catch the mouse.
    LazyLoader {
        active: S.Notifications.popups.length > 0 && !root.panelOpen

        PanelWindow {
            screen: root.targetScreen
            anchors { top: true; right: true }
            margins { top: K.Theme.space.sm; right: K.Theme.space.sm }
            implicitWidth: 380
            implicitHeight: popupColumn.implicitHeight
            exclusionMode: ExclusionMode.Normal
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kotilo-notifications"

            Column {
                id: popupColumn
                width: parent.width
                spacing: K.Theme.space.sm

                Repeater {
                    model: S.Notifications.popups

                    delegate: Card {
                        id: popup
                        required property var modelData
                        notification: modelData

                        NumberAnimation on opacity { from: 0; to: 1; duration: K.Theme.animMs }

                        Timer {
                            interval: S.Notifications.timeoutFor(popup.modelData)
                            running: interval > 0 && !hover.containsMouse
                            onTriggered: S.Notifications.hidePopup(popup.modelData)
                        }

                        // Under the action buttons, so they still get their clicks.
                        MouseArea {
                            id: hover
                            z: -1
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: S.Notifications.dismiss(popup.modelData)
                        }
                    }
                }
            }
        }
    }

    // History, grouped by app with the newest first.
    LazyLoader {
        active: root.panelOpen

        PanelWindow {
            id: panel
            screen: root.targetScreen
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kotilo-notifications-panel"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            property int selected: 0
            property int action: 0                  // in the selected row; Enter must not act on a stale choice
            readonly property var rows: {
                const newest = S.Notifications.history.slice().reverse();
                const apps = Array.from(new Set(newest.map(n => n.appName)));
                return apps.reduce((rows, app) => rows.concat(newest.filter(n => n.appName === app)), []);
            }
            onRowsChanged: { selected = Math.max(0, Math.min(selected, rows.length - 1)); action = 0; }
            onSelectedChanged: action = 0

            function move(delta) {
                if (rows.length) selected = (selected + delta + rows.length) % rows.length;
            }

            function moveAction(delta) {
                const n = rows[selected];
                if (n && n.actions.length) action = (action + delta + n.actions.length) % n.actions.length;
            }

            function activate() {
                const n = rows[selected];
                if (!n) return;
                root.panelOpen = false;
                if (n.actions.length) n.actions[action].invoke();
            }

            MouseArea { anchors.fill: parent; onClicked: root.panelOpen = false }

            C.Surface {
                anchors { top: parent.top; right: parent.right; bottom: parent.bottom; margins: K.Theme.space.sm }
                width: 400

                NumberAnimation on opacity { from: 0; to: 1; duration: K.Theme.animMs }
                MouseArea { anchors.fill: parent }

                Item {
                    id: keys
                    anchors.fill: parent
                    focus: true
                    Component.onCompleted: forceActiveFocus()

                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier;
                        if (event.key === Qt.Key_Escape) root.panelOpen = false;
                        else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_N)) panel.move(1);
                        else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_P)) panel.move(-1);
                        else if (event.key === Qt.Key_Right) panel.moveAction(1);
                        else if (event.key === Qt.Key_Left) panel.moveAction(-1);
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) panel.activate();
                        else if (event.key === Qt.Key_Delete && panel.rows[panel.selected]) S.Notifications.dismiss(panel.rows[panel.selected]);
                        else if (event.key === Qt.Key_C) S.Notifications.clear();
                        else return;
                        event.accepted = true;
                    }

                    C.Label {
                        id: heading
                        anchors { top: parent.top; left: parent.left; margins: K.Theme.space.lg }
                        font.pixelSize: K.Theme.font.size + 2
                        text: "Notifications"
                    }

                    ListView {
                        id: list
                        anchors {
                            top: heading.bottom; bottom: hints.top; left: parent.left; right: parent.right
                            margins: K.Theme.space.lg
                        }
                        clip: true
                        spacing: K.Theme.space.sm
                        boundsBehavior: Flickable.StopAtBounds
                        model: panel.rows
                        currentIndex: panel.selected
                        highlightMoveDuration: 0

                        delegate: Card {
                            required property var modelData
                            required property int index
                            notification: modelData
                            highlighted: index === panel.selected
                            chosenAction: highlighted && notification.actions.length > 1 ? panel.action : -1
                            width: ListView.view.width
                        }

                        C.Label {
                            anchors.centerIn: parent
                            visible: panel.rows.length === 0
                            secondary: true
                            text: "No notifications"
                        }
                    }

                    C.Label {
                        id: hints
                        anchors { bottom: parent.bottom; left: parent.left; margins: K.Theme.space.lg }
                        secondary: true
                        font.pixelSize: K.Theme.font.size - 2
                        text: "↵ open   ←→ action   del dismiss   c clear all   esc close"
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Shell as K
import qs.services as S
import qs.components as C

// Every open window, by workspace. PopupHost places it and closes it on Esc or an outside click.
C.Surface {
    id: popup
    width: 360
    height: Math.min(list.contentHeight, rowHeight * 10) + 2 * K.Theme.space.sm
    readonly property int rowHeight: 40
    focus: true
    Component.onCompleted: forceActiveFocus()

    readonly property var rows: ToplevelManager.toplevels.values
        .map(t => ({ toplevel: t, workspace: S.Workspaces.workspaceOf(t) }))
        .sort((a, b) => a.workspace.localeCompare(b.workspace, undefined, { numeric: true }))
    property int selected: Math.max(0, rows.findIndex(r => r.toplevel === ToplevelManager.activeToplevel))

    function choose(row) {
        K.Shell.closePopups();
        S.Workspaces.focusToplevel(row.toplevel);
    }

    function move(delta) {
        if (rows.length) selected = (selected + delta + rows.length) % rows.length;
    }

    Keys.onPressed: event => {
        const key = event.key;
        const ctrl = event.modifiers & Qt.ControlModifier;
        if (key === Qt.Key_Down || key === Qt.Key_Tab || (ctrl && key === Qt.Key_N)) move(1);
        else if (key === Qt.Key_Up || key === Qt.Key_Backtab || (ctrl && key === Qt.Key_P)) move(-1);
        else if ((key === Qt.Key_Return || key === Qt.Key_Enter) && rows[selected]) choose(rows[selected]);
        else return;
        event.accepted = true;
    }

    ListView {
        id: list
        anchors { fill: parent; margins: K.Theme.space.sm }
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: popup.rows
        currentIndex: popup.selected
        highlightMoveDuration: 0

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property var entry: DesktopEntries.heuristicLookup(modelData.toplevel.appId)
            width: ListView.view.width
            height: popup.rowHeight
            radius: K.Theme.radius.sm
            color: index === popup.selected ? K.Theme.surface[0] : "transparent"

            C.StateLayer { hovered: mouse.containsMouse; pressed: mouse.pressed }

            IconImage {
                id: appIcon
                anchors { left: parent.left; leftMargin: K.Theme.space.sm; verticalCenter: parent.verticalCenter }
                implicitSize: 20
                source: row.entry ? Quickshell.iconPath(row.entry.icon, true) : ""
            }
            C.Label {
                anchors { left: appIcon.right; right: place.left; leftMargin: K.Theme.space.sm; rightMargin: K.Theme.space.sm; verticalCenter: parent.verticalCenter }
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: row.modelData.toplevel.title || row.modelData.toplevel.appId
            }
            C.Label {
                id: place
                anchors { right: parent.right; rightMargin: K.Theme.space.sm; verticalCenter: parent.verticalCenter }
                secondary: true
                mono: true
                textFormat: Text.PlainText
                text: row.modelData.workspace
            }
            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: popup.choose(row.modelData)
            }
        }

        C.Label {
            anchors.centerIn: parent
            visible: popup.rows.length === 0
            secondary: true
            text: "No open windows"
        }
    }
}

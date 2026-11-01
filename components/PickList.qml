// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../Shell" as K

// A keyboard list for panels. rows hold { heading } or { title, detail, trailing }. Text is plain.
Item {
    id: list
    property var rows: []
    property string empty: ""
    property int selected: 0
    signal chosen(var row)

    function step(delta) {
        for (let i = 1; i <= rows.length; i++) {
            const next = (selected + delta * i + rows.length * i) % rows.length;
            if (rows[next].title !== undefined) { selected = next; return; }
        }
    }
    onRowsChanged: { selected = Math.max(0, Math.min(selected, rows.length - 1)); if (rows.length && rows[selected].title === undefined) step(1); }

    // Returns true when it used the key.
    function key(event) {
        if (event.key === Qt.Key_Down) step(1);
        else if (event.key === Qt.Key_Up) step(-1);
        else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && rows[selected] && rows[selected].title !== undefined) chosen(rows[selected]);
        else return false;
        return true;
    }

    ListView {
        id: view
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: list.rows
        currentIndex: list.selected
        highlightMoveDuration: 0

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool pickable: modelData.title !== undefined
            width: ListView.view.width
            height: !pickable ? 32 : (modelData.detail ? 46 : 32)

            Label {
                visible: !row.pickable
                anchors { left: parent.left; bottom: parent.bottom; bottomMargin: K.Theme.space.xs }
                secondary: true
                textFormat: Text.PlainText
                font.pixelSize: K.Theme.font.size - 2
                text: row.modelData.heading || ""
            }

            Rectangle {
                visible: row.pickable
                anchors.fill: parent
                radius: K.Theme.radius.sm
                color: row.index === list.selected ? K.Theme.surface[0] : "transparent"

                StateLayer { hovered: mouse.containsMouse; pressed: mouse.pressed }

                Column {
                    anchors { left: parent.left; right: trailing.left; leftMargin: K.Theme.space.sm; rightMargin: K.Theme.space.md; verticalCenter: parent.verticalCenter }
                    Label { width: parent.width; elide: Text.ElideRight; textFormat: Text.PlainText; text: row.modelData.title || "" }
                    Label {
                        width: parent.width
                        visible: !!row.modelData.detail
                        elide: Text.ElideRight
                        secondary: true
                        textFormat: Text.PlainText
                        font.pixelSize: K.Theme.font.size - 2
                        text: row.modelData.detail || ""
                    }
                }
                Label {
                    id: trailing
                    anchors { right: parent.right; rightMargin: K.Theme.space.sm; verticalCenter: parent.verticalCenter }
                    secondary: true
                    mono: true
                    textFormat: Text.PlainText
                    text: row.modelData.trailing || ""
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: { list.selected = row.index; list.chosen(row.modelData); }
                }
            }
        }

        Label {
            anchors.centerIn: parent
            width: parent.width - 2 * K.Theme.space.xl
            visible: list.rows.length === 0 && list.empty.length > 0
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            secondary: true
            textFormat: Text.PlainText
            text: list.empty
        }
    }
}

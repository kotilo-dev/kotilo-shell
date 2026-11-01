// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../Shell" as K

// Recent percentages as small bars over a faint track, newest on the right. The square root keeps
// a quiet system visible; the exact value belongs in the text beside it. The bars stay and only
// change height.
Row {
    id: spark
    property var values: []
    property int count: 10
    property color color: K.Theme.text.secondary
    property int barWidth: 2
    property bool linear: false                 // true height, for a panel with room
    height: K.Theme.barSize(14)
    spacing: 1

    Repeater {
        model: spark.count

        delegate: Rectangle {
            id: column
            required property int index
            readonly property real value: spark.values[spark.values.length - spark.count + index] || 0
            width: spark.barWidth
            height: spark.height
            color: K.Theme.surface[0]

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: column.value > 0 ? Math.max(2, (spark.linear ? Math.min(1, column.value / 100) : Math.sqrt(Math.min(1, column.value / 100))) * parent.height) : 0
                color: spark.color
            }
        }
    }
}

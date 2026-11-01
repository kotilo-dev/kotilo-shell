// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../Shell" as K

// Recent percentages as small bars, newest on the right. The bars stay and only change height.
Row {
    id: spark
    property var values: []
    property int count: 10
    property color color: K.Theme.accent.primary
    height: 14
    spacing: 1

    Repeater {
        model: spark.count

        delegate: Rectangle {
            required property int index
            readonly property real value: spark.values[spark.values.length - spark.count + index] || 0
            width: 2
            height: Math.max(1, Math.min(1, value / 100) * spark.height)
            y: spark.height - height
            color: spark.color
        }
    }
}

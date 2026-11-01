// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../Shell" as K

// Labelled slider. value is 0..1; moved() fires only for a change the person made.
Item {
    id: slider
    property real value: 0
    property string icon: ""
    property string label: ""
    property bool selected: false
    signal moved(real value)
    signal iconClicked()

    implicitHeight: label.length ? 44 : 28

    Label {
        id: heading
        visible: slider.label.length > 0
        width: parent.width
        elide: Text.ElideRight
        secondary: true
        font.pixelSize: K.Theme.font.size - 2
        textFormat: Text.PlainText
        text: slider.label
    }

    Row {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 28
        spacing: K.Theme.space.md

        Icon {
            id: glyph
            anchors.verticalCenter: parent.verticalCenter
            name: slider.icon
            visible: slider.icon.length > 0
            size: 16
            color: K.Theme.accent.primary
            MouseArea { anchors.fill: parent; onClicked: slider.iconClicked() }
        }

        Item {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - (glyph.visible ? glyph.width + K.Theme.space.md : 0) - percent.width - K.Theme.space.md
            height: 28

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: slider.selected ? 8 : 6
                radius: height / 2
                color: K.Theme.surface[1]

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, slider.value))
                    height: parent.height
                    radius: parent.radius
                    color: K.Theme.accent.primary
                }
            }

            MouseArea {
                anchors.fill: parent
                function update(x) { slider.moved(Math.max(0, Math.min(1, x / width))); }
                onPressed: mouse => update(mouse.x)
                onPositionChanged: mouse => { if (pressed) update(mouse.x); }
            }
        }

        Label {
            id: percent
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            mono: true
            horizontalAlignment: Text.AlignRight
            text: Math.round(slider.value * 100) + "%"
        }
    }
}

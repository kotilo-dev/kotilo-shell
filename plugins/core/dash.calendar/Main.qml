// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K
import qs.components as C
import "month.js" as Month

C.Card {
    id: card
    readonly property var area: ({ x: 0.14, y: 0.36, w: 0.5, h: 0.64 })

    SystemClock { id: clock; precision: SystemClock.Hours }
    readonly property date today: clock.date
    property int year: today.getFullYear()
    property int month: today.getMonth()
    // Qt counts Monday 1 to Sunday 7, JavaScript Sunday 0 to Saturday 6.
    readonly property int firstDay: Qt.locale().firstDayOfWeek % 7

    function shift(delta) {
        const next = new Date(year, month + delta, 1);
        year = next.getFullYear();
        month = next.getMonth();
    }

    component Step: Rectangle {
        id: step
        property string text: ""
        signal activated()
        width: 28; height: 28
        radius: K.Theme.radius.sm
        color: "transparent"
        activeFocusOnTab: true
        Keys.onPressed: event => {
            if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter) return;
            step.activated();
            event.accepted = true;
        }
        C.StateLayer { hovered: stepMouse.containsMouse; pressed: stepMouse.pressed }
        C.FocusRing { visible: step.activeFocus }
        C.Label { anchors.centerIn: parent; text: step.text }
        MouseArea { id: stepMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: step.activated() }
    }

    Item {
        width: parent.width
        height: 28

        Step { anchors.left: parent.left; text: "‹"; onActivated: card.shift(-1) }
        C.Label {
            anchors.centerIn: parent
            color: K.Theme.accent.primary
            font.weight: Font.DemiBold
            text: Qt.formatDate(new Date(card.year, card.month, 1), "MMMM yyyy")
        }
        Step { anchors.right: parent.right; text: "›"; onActivated: card.shift(1) }
    }

    Grid {
        id: days
        width: parent.width
        columns: 7
        readonly property real cell: width / 7
        // Rows share the card's height, with one row for the weekday names.
        readonly property real rowHeight: (card.height - 2 * K.Theme.space.md - 28 - 2 * K.Theme.space.sm) / (Month.weeks(card.year, card.month, card.firstDay).length + 1)

        Repeater {
            model: Month.weekdays(card.firstDay)
            delegate: C.Label {
                required property var modelData
                width: days.cell
                height: days.rowHeight
                horizontalAlignment: Text.AlignHCenter
                secondary: true
                font.pixelSize: K.Theme.font.size - 2
                // 4 January 1970 was a Sunday.
                text: Qt.formatDate(new Date(1970, 0, 4 + modelData), "ddd")
            }
        }

        Repeater {
            model: [].concat.apply([], Month.weeks(card.year, card.month, card.firstDay))
            delegate: Item {
                id: day
                required property var modelData
                readonly property bool isToday: modelData.inMonth && card.year === card.today.getFullYear()
                    && card.month === card.today.getMonth() && modelData.day === card.today.getDate()
                width: days.cell
                height: days.rowHeight

                Rectangle {
                    anchors.centerIn: parent
                    width: 24; height: 24
                    radius: width / 2
                    visible: day.isToday
                    color: K.Theme.accent.primary
                }
                C.Label {
                    anchors.centerIn: parent
                    color: day.isToday ? K.Theme.text.onAccent : (day.modelData.inMonth ? K.Theme.text.primary : K.Theme.text.muted)
                    font.features: { "tnum": 1 }
                    text: day.modelData.day
                }
            }
        }
    }
}

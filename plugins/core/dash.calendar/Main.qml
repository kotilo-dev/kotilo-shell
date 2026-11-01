// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K
import qs.components as C
import "month.js" as Month

C.Card {
    id: card
    title: Qt.formatDate(new Date(year, month, 1), "MMMM yyyy")

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

    Row {
        spacing: K.Theme.space.xs
        Step { text: "‹"; onActivated: card.shift(-1) }
        Step { text: "›"; onActivated: card.shift(1) }
    }

    Grid {
        id: days
        width: parent.width
        columns: 7
        readonly property real cell: width / 7

        Repeater {
            model: Month.weekdays(card.firstDay)
            delegate: C.Label {
                required property var modelData
                width: days.cell
                horizontalAlignment: Text.AlignHCenter
                secondary: true
                font.pixelSize: K.Theme.font.size - 2
                // 4 January 1970 was a Sunday.
                text: Qt.formatDate(new Date(1970, 0, 4 + modelData), "ddd").slice(0, 2)
            }
        }

        Repeater {
            model: [].concat.apply([], Month.weeks(card.year, card.month, card.firstDay))
            delegate: Item {
                id: day
                required property var modelData
                readonly property bool isToday: modelData > 0 && card.year === card.today.getFullYear()
                    && card.month === card.today.getMonth() && modelData === card.today.getDate()
                width: days.cell
                height: 28

                Rectangle {
                    anchors.centerIn: parent
                    width: 26; height: 26
                    radius: width / 2
                    visible: day.isToday
                    color: K.Theme.accent.primary
                }
                C.Label {
                    anchors.centerIn: parent
                    visible: day.modelData > 0
                    color: day.isToday ? K.Theme.text.onAccent : K.Theme.text.primary
                    font.features: { "tnum": 1 }
                    text: day.modelData
                }
            }
        }
    }
}

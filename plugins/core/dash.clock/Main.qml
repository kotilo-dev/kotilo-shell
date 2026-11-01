// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K
import qs.services as S
import qs.components as C

// The local time, with up to two world clocks below it.
C.Card {
    id: card
    readonly property var area: ({ x: 0, y: 0.36, w: 0.24, h: 0.64 })
    readonly property var zones: K.Settings.get("dash.clock", "zones", []).slice(0, 2)
    property var offsets: ({})                  // tz -> minutes east of UTC

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // QML has no time zones, so the system supplies each offset, read again for daylight saving.
    function readOffsets() {
        for (const zone of zones) {
            const tz = zone.tz;
            K.Shell.run(["env", "TZ=" + tz, "date", "+%z"]).then(r => {
                const m = /^([+-])(\d\d)(\d\d)$/.exec(r.stdout.trim());
                if (!m) return;
                const minutes = (m[1] === "-" ? -1 : 1) * (Number(m[2]) * 60 + Number(m[3]));
                card.offsets = Object.assign({}, card.offsets, { [tz]: minutes });
            }, () => {});
        }
    }
    onZonesChanged: readOffsets()
    Component.onCompleted: readOffsets()
    Timer { interval: 15 * 60 * 1000; repeat: true; running: card.zones.length > 0; onTriggered: card.readOffsets() }

    function timeIn(tz) {
        const offset = offsets[tz];
        if (offset === undefined) return "--:--";
        return Qt.formatTime(new Date(clock.date.getTime() + (clock.date.getTimezoneOffset() + offset) * 60000), "HH:mm");
    }

    Item {
        width: parent.width
        height: card.height - 2 * K.Theme.space.md

        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: K.Theme.space.sm

            Column {
                width: parent.width

                C.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: K.Theme.font.size + 23
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                    text: Qt.formatTime(clock.date, "HH:mm")
                }
                C.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: K.Theme.accent.primary
                    font.weight: Font.DemiBold
                    text: Qt.formatDate(clock.date, "ddd d MMM")
                }
            }

            Rectangle {
                visible: card.zones.length > 0
                width: parent.width
                height: 1
                color: K.Theme.surface[0]
            }

            Repeater {
                model: card.zones

                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: 22

                    C.Label {
                        anchors { left: parent.left; right: time.left; rightMargin: K.Theme.space.sm; verticalCenter: parent.verticalCenter }
                        elide: Text.ElideRight
                        secondary: true
                        textFormat: Text.PlainText
                        text: parent.modelData.label
                    }
                    C.Label {
                        id: time
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        font.pixelSize: K.Theme.font.size + 1
                        font.features: { "tnum": 1 }
                        text: card.timeIn(parent.modelData.tz)
                    }
                }
            }

            C.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: S.Focus.completed > 0
                secondary: true
                font.pixelSize: K.Theme.font.size - 2
                text: S.Focus.completed === 1 ? "1 focus session" : S.Focus.completed + " focus sessions"
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.Shell as K
import qs.components as C

// Clock with extra zones: settings.plugins["bar.clock"].zones = [{"label":"SFO","tz":"America/Los_Angeles"}]
Row {
    id: root
    property var plugin: null
    property string slot: ""
    spacing: 8

    readonly property string format: K.Settings.get("bar.clock", "format", "HH:mm")
    readonly property var zones: K.Settings.get("bar.clock", "zones", [])
    readonly property string localLabel: K.Settings.get("bar.clock", "localLabel", "")

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // QML has no time zones, and toLocaleTimeString ignores a timeZone option without an error.
    // So the system supplies each zone's offset, read again in time for daylight saving changes.
    property var offsets: ({})                  // tz -> minutes east of UTC

    function readOffsets() {
        for (const zone of root.zones) {
            const tz = zone.tz;
            K.Shell.run(["env", "TZ=" + tz, "date", "+%z"]).then(r => {
                const m = /^([+-])(\d\d)(\d\d)$/.exec(r.stdout.trim());
                if (!m) return;
                const minutes = (m[1] === "-" ? -1 : 1) * (Number(m[2]) * 60 + Number(m[3]));
                root.offsets = Object.assign({}, root.offsets, { [tz]: minutes });
            }, e => K.Log.warn("no offset for " + tz + ": " + e, "bar.clock"));
        }
    }

    onZonesChanged: readOffsets()
    Timer { interval: 15 * 60 * 1000; repeat: true; running: root.zones.length > 0; onTriggered: root.readOffsets() }

    function fmt(date, tz) {
        const offset = root.offsets[tz];
        if (offset === undefined) return "--:--";
        return Qt.formatTime(new Date(date.getTime() + (date.getTimezoneOffset() + offset) * 60000), root.format);
    }

    C.Label {
        mono: true
        font.weight: Font.DemiBold
        text: Qt.formatTime(clock.date, root.format) + (root.localLabel ? " " : "")
        anchors.verticalCenter: parent.verticalCenter
    }
    C.Label { visible: root.localLabel.length > 0; text: root.localLabel; secondary: true; mono: true; anchors.verticalCenter: parent.verticalCenter }

    Repeater {
        model: root.zones
        delegate: Row {
            required property var modelData
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            C.Label { text: "·"; secondary: true; anchors.verticalCenter: parent.verticalCenter }
            C.Label { mono: true; text: root.fmt(clock.date, modelData.tz); anchors.verticalCenter: parent.verticalCenter }
            C.Label { mono: true; secondary: true; text: modelData.label; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // TODO(0.2): click -> calendar popup via K.Shell.openPopup(plugin, "Calendar.qml")
}

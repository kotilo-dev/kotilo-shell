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

    function fmt(date, tz) {
        // Qt's JS Date supports toLocaleTimeString with timeZone in recent Qt; fall back to local.
        try { return date.toLocaleTimeString(Qt.locale(), { hour: "2-digit", minute: "2-digit", hour12: false, timeZone: tz }); }
        catch (e) { return Qt.formatTime(date, root.format); }
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

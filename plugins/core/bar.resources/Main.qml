// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

Row {
    id: root
    property var plugin: null
    property string slot: ""
    spacing: K.Theme.space.xs
    visible: S.Resources.ready

    readonly property int warnAt: K.Settings.get("bar.resources", "warnAt", 85)
    readonly property bool high: S.Resources.cpu >= warnAt || S.Resources.ram >= warnAt

    C.Pill {
        anchors.verticalCenter: parent.verticalCenter
        icon: "cpu"
        text: S.Resources.cpu + "% " + S.Resources.ram + "%"
        fg: root.high ? K.Theme.state.warning : K.Theme.text.primary
        tooltip: "CPU " + S.Resources.cpu + "%, memory " + S.Resources.ramUsedGb.toFixed(1) + " GB"

        C.Sparkline {
            anchors.verticalCenter: parent.verticalCenter
            visible: K.Settings.get("bar.resources", "sparkline", true)
            count: S.Resources.historySize
            values: S.Resources.history
            color: root.high ? K.Theme.state.warning : K.Theme.text.secondary
        }
    }

    C.Pill {
        anchors.verticalCenter: parent.verticalCenter
        visible: S.Resources.netReady && K.Settings.get("bar.resources", "network", true)
        text: "↓" + S.Resources.netDownText + " ↑" + S.Resources.netUpText
        tooltip: "Network down " + S.Resources.netDownText + "/s, up " + S.Resources.netUpText + "/s"
    }
}

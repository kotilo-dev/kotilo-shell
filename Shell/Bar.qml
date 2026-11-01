// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components" as C
import "../services" as S

// The bar: one PanelWindow per screen, three slot regions filled by PluginHost.
PanelWindow {
    id: bar
    required property var host

    readonly property int barHeight: Settings.ready && Settings.global.bar ? (Settings.global.bar.height || 40) : 40
    readonly property string position: Settings.ready && Settings.global.bar ? (Settings.global.bar.position || "top") : "top"

    anchors { top: position === "top"; bottom: position === "bottom"; left: true; right: true }
    implicitHeight: barHeight
    exclusiveZone: barHeight
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "kotilo-bar"

    Rectangle {
        anchors.fill: parent
        color: Theme.bg.mantle
        border.width: 0

        Rectangle {   // hairline on the inner edge
            width: parent.width; height: 1
            anchors.bottom: bar.position === "top" ? parent.bottom : undefined
            anchors.top: bar.position === "bottom" ? parent.top : undefined
            color: Theme.surface[0]
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.space.lg
            anchors.rightMargin: Theme.space.lg
            spacing: 0

            C.SlotRow { slotName: "bar.left";   host: bar.host; screen: bar.screen; Layout.alignment: Qt.AlignLeft }
            Item { Layout.fillWidth: true }
            C.SlotRow {
                slotName: "bar.center"
                host: bar.host
                screen: bar.screen
                visible: !(S.Focus.active && S.Focus.compactBar)
                Layout.alignment: Qt.AlignHCenter
            }
            Item { Layout.fillWidth: true }
            C.SlotRow { slotName: "bar.right";  host: bar.host; screen: bar.screen; Layout.alignment: Qt.AlignRight }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components" as C
import "../services" as S

// The bar: one PanelWindow per screen, three slot regions filled by PluginHost.
PanelWindow {
    id: bar
    required property var host

    readonly property int barHeight: Theme.barSize(Settings.ready && Settings.global.bar ? (Settings.global.bar.height || 36) : 36)
    readonly property string position: Settings.ready && Settings.global.bar ? (Settings.global.bar.position || "top") : "top"

    anchors { top: position === "top"; bottom: position === "bottom"; left: true; right: true }
    implicitHeight: barHeight
    exclusiveZone: barHeight
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "kotilo-bar"
    WlrLayershell.keyboardFocus: keyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Keyboard mode (ADR-0014). With nothing to focus, nothing could answer Esc, so it ends at once.
    readonly property bool keyboard: !!screen && Shell.barKeyboardOutput === screen.name
    onKeyboardChanged: if (keyboard) focusFirst.restart()

    Timer {
        id: focusFirst
        interval: 50
        onTriggered: {
            const first = bar.contentItem.nextItemInFocusChain(true);
            if (first && first.activeFocusOnTab) first.forceActiveFocus();
            else Shell.barKeyboardOutput = "";
        }
    }

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

        C.SlotRow {
            id: leftSlots
            anchors { left: parent.left; leftMargin: Theme.barSize(Theme.space.lg); verticalCenter: parent.verticalCenter }
            slotName: "bar.left"
            host: bar.host
            screen: bar.screen
        }
        C.SlotRow {
            id: rightSlots
            anchors { right: parent.right; rightMargin: Theme.barSize(Theme.space.lg); verticalCenter: parent.verticalCenter }
            slotName: "bar.right"
            host: bar.host
            screen: bar.screen
        }
        // On the bar's true center, whatever the sides hold, and moved aside only to avoid them.
        C.SlotRow {
            readonly property int gap: Theme.barSize(Theme.space.sm)
            readonly property real leftLimit: leftSlots.x + leftSlots.width + gap
            readonly property real rightLimit: rightSlots.x - width - gap
            x: Math.round(Math.max(leftLimit, Math.min((parent.width - width) / 2, rightLimit)))
            anchors.verticalCenter: parent.verticalCenter
            slotName: "bar.center"
            host: bar.host
            screen: bar.screen
            visible: !(S.Focus.active && S.Focus.compactBar)
        }
    }
}

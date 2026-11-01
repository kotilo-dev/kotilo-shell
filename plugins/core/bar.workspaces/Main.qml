// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C
import "labels.js" as Labels

Row {
    id: root
    property var plugin: null
    property string slot: ""
    property var screen: null
    spacing: 4

    readonly property bool showEmpty: K.Settings.get("bar.workspaces", "showEmpty", true)
    readonly property bool showNames: K.Settings.get("bar.workspaces", "showNames", false)
    readonly property string style: K.Settings.get("bar.workspaces", "style", "numbers")
    readonly property bool glyphs: !showNames && (style === "dots" || style === "circles")
    readonly property var model: S.Workspaces.forOutput(screen ? screen.name : "").filter(w => showEmpty || w.windows > 0 || w.active)

    Repeater {
        model: root.model
        delegate: C.Pill {
            required property var modelData
            id: entry
            readonly property color tone: modelData.urgent ? K.Theme.state.error
                : modelData.focused ? K.Theme.accent.primary
                : modelData.active ? K.Theme.text.primary
                : modelData.windows > 0 ? K.Theme.text.secondary : K.Theme.text.muted
            text: root.glyphs ? "" : root.showNames ? modelData.name
                : root.style === "roman" ? Labels.roman(modelData.index) : String(modelData.index)
            tooltip: root.glyphs ? "Workspace " + modelData.index : ""
            active: modelData.focused && !root.glyphs
            accent: modelData.urgent ? K.Theme.state.error : K.Theme.accent.primary
            fg: modelData.focused ? K.Theme.text.onAccent : (modelData.active ? K.Theme.text.primary : (modelData.windows > 0 ? K.Theme.text.secondary : K.Theme.text.muted))
            implicitWidth: root.glyphs ? 20 : Math.max(26, implicitHeight) + (text.length > 1 ? (text.length - 1) * 7 : 0)
            onClicked: S.Workspaces.focus(modelData.id)

            // Dots use colour alone. Circles also show content: a ring is empty, a disc has windows.
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.glyphs
                width: entry.modelData.focused ? 10 : 8
                height: width
                radius: width / 2
                border.width: 2
                border.color: entry.tone
                color: root.style === "dots" || entry.modelData.focused || entry.modelData.windows > 0 ? entry.tone : "transparent"
                Behavior on color { ColorAnimation { duration: K.Theme.fastMs } }
            }
        }
    }

    // Empty state when no compositor is detected — keep the bar honest.
    C.Pill {
        visible: root.model.length === 0
        text: S.Workspaces.ready ? "" : "no wm"
        fg: K.Theme.text.muted
        tooltip: S.Workspaces.error
    }

    WheelHandler {
        onWheel: (e) => S.Workspaces.focusRelative(e.angleDelta.y < 0 ? 1 : -1)
    }
}

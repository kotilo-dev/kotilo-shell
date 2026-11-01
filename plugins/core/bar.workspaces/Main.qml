import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

Row {
    id: root
    property var plugin: null
    property string slot: ""
    property var screen: null
    spacing: 4

    readonly property bool showEmpty: K.Settings.get("bar.workspaces", "showEmpty", true)
    readonly property bool showNames: K.Settings.get("bar.workspaces", "showNames", false)
    readonly property var model: S.Workspaces.forOutput(screen ? screen.name : "").filter(w => showEmpty || w.windows > 0 || w.active)

    Repeater {
        model: root.model
        delegate: C.Pill {
            required property var modelData
            text: root.showNames ? modelData.name : String(modelData.index)
            active: modelData.focused
            accent: modelData.urgent ? K.Theme.state.error : K.Theme.accent.primary
            fg: modelData.focused ? K.Theme.text.onAccent : (modelData.active ? K.Theme.text.primary : (modelData.windows > 0 ? K.Theme.text.secondary : K.Theme.text.muted))
            implicitWidth: Math.max(26, implicitHeight) + (text.length > 1 ? (text.length - 1) * 7 : 0)
            onClicked: S.Workspaces.focus(modelData.id)
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

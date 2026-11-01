import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Pill {
    property var plugin: null
    property string slot: ""
    visible: S.Battery.ready
    icon: S.Battery.charging ? "battery-charging" : "battery"
    text: S.Battery.percent + "%"
    accent: K.Theme.stateColor(S.Battery.stateClass())
    fg: accent
    tooltip: S.Battery.charging ? ("Full in " + S.Battery.timeToFull) : ("Empty in " + S.Battery.timeToEmpty)
}

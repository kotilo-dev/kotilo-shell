import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Pill {
    readonly property int warnAt: K.Settings.get("bar.resources", "warnAt", 85)
    readonly property bool high: S.Resources.cpu >= warnAt || S.Resources.ram >= warnAt
    visible: S.Resources.ready
    icon: "cpu"
    text: S.Resources.cpu + "% " + S.Resources.ram + "%"
    accent: high ? K.Theme.state.warning : K.Theme.accent.primary
    fg: high ? K.Theme.state.warning : K.Theme.text.primary
    tooltip: "CPU " + S.Resources.cpu + "%, memory " + S.Resources.ramUsedGb.toFixed(1) + " GB"
}

import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Pill {
    readonly property bool showName: K.Settings.get("bar.network", "showName", false)
    visible: S.Network.ready
    icon: S.Network.icon()
    text: S.Network.kind === "wifi" ? (showName ? S.Network.name : S.Network.signal + "%") : ""
    accent: S.Network.limited ? K.Theme.state.warning : (S.Network.connected ? K.Theme.accent.primary : K.Theme.text.muted)
    tooltip: S.Network.connected ? S.Network.name : "Not connected"
}

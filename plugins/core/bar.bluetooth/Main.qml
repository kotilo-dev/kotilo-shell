import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Pill {
    visible: S.Bluetooth.ready
    icon: S.Bluetooth.icon()
    text: S.Bluetooth.connected.length > 0 ? String(S.Bluetooth.connected.length) : ""
    accent: S.Bluetooth.enabled ? K.Theme.accent.primary : K.Theme.text.muted
    tooltip: S.Bluetooth.connected.map(d => d.name).join(", ")
    onClicked: S.Bluetooth.toggle()
}

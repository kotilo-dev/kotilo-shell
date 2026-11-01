import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Pill {
    visible: S.Notifications.ready
    icon: "bell"
    text: S.Notifications.count > 0 ? String(S.Notifications.count) : ""
    accent: S.Notifications.count > 0 ? K.Theme.accent.primary : K.Theme.text.muted
    onClicked: S.Notifications.open()
}

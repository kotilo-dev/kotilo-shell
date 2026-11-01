// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Pill {
    visible: S.Notifications.ready
    icon: "bell"
    text: S.Notifications.count > 0 ? String(S.Notifications.count) : ""
    fg: S.Notifications.count > 0 ? K.Theme.text.primary : K.Theme.text.muted
    onClicked: S.Notifications.open()
}

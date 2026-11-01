// SPDX-License-Identifier: GPL-3.0-or-later
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
    fg: S.Battery.low && !S.Battery.charging ? K.Theme.state.error : K.Theme.text.primary
    iconColor: S.Battery.charging ? K.Theme.state.success : (S.Battery.low ? K.Theme.state.error : K.Theme.text.secondary)
    tooltip: S.Battery.charging ? ("Full in " + S.Battery.timeToFull) : ("Empty in " + S.Battery.timeToEmpty)
}

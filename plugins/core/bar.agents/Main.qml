// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Pill {
    readonly property int waiting: S.Agents.approvals.length
    visible: S.Agents.active > 0 || waiting > 0
    icon: "agent"
    text: String(S.Agents.active) + (waiting ? " !" + waiting : "")
    fg: waiting ? K.Theme.state.warning : K.Theme.text.primary
    iconColor: waiting ? K.Theme.state.warning : K.Theme.accent.primary
    onClicked: K.Shell.toggleAgents()
}

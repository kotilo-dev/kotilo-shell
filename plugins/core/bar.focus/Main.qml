// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Pill {
    visible: S.Focus.active
    icon: "clock"
    text: S.Focus.clock
    accent: S.Focus.phase === "work" ? K.Theme.accent.primary : K.Theme.state.success
    onClicked: S.Focus.stop()
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.components as C

C.Pill {
    icon: "kotilo"
    iconColor: K.Theme.text.primary
    tooltip: "Settings"
    onClicked: K.Shell.toggleSettings()
}

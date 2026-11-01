// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.components as C

C.Pill {
    icon: "kotilo"
    onClicked: K.Shell.toggleControlCenter()
}

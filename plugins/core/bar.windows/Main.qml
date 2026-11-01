// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell.Wayland
import qs.Shell as K
import qs.components as C

C.Pill {
    id: pill
    icon: "windows"
    text: String(ToplevelManager.toplevels.values.length)
    tooltip: "Windows"
    onClicked: K.Shell.openPopup(pill.plugin, "Popup.qml", pill)
}

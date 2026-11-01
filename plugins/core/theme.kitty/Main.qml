// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.components as C

C.ThemeTarget {
    fileName: "kitty.conf"
    reloadCommand: ["pkill", "-USR1", "-x", "kitty"]
}

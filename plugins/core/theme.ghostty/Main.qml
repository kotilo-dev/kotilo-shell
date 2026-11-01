// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.components as C

C.ThemeTarget {
    fileName: "ghostty.conf"
    reloadCommand: ["pkill", "-USR2", "-x", "ghostty"]
}

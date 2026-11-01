// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.services as S
import qs.components as C

C.Pill {
    visible: S.Containers.count > 0
    icon: "container"
    text: String(S.Containers.count)
}

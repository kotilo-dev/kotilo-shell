// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Card {
    title: "Focus"

    C.Label {
        font.pixelSize: K.Theme.font.size + 6
        text: S.Focus.completed === 1 ? "1 session" : S.Focus.completed + " sessions"
    }
    C.Label {
        secondary: true
        font.pixelSize: K.Theme.font.size - 2
        text: S.Focus.active ? "Focus Mode is on" : "Since the shell started"
    }
}

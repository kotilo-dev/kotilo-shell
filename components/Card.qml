// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../Shell" as K

// Dashboard card (ADR-0015): a title over whatever the plugin puts inside.
Surface {
    id: card
    property var plugin: null
    property string slot: ""
    property string title: ""
    property bool centered: false               // content in the middle of a taller card
    default property alias content: body.data
    level: 1
    radius: K.Theme.radius.lg
    implicitHeight: column.implicitHeight + 2 * K.Theme.space.md

    Column {
        id: column
        x: K.Theme.space.md
        y: card.centered ? (card.height - implicitHeight) / 2 : K.Theme.space.md
        width: card.width - 2 * K.Theme.space.md
        spacing: K.Theme.space.sm

        Label { visible: card.title.length > 0; secondary: true; textFormat: Text.PlainText; font.pixelSize: K.Theme.font.size - 2; text: card.title }
        Column { id: body; width: parent.width; spacing: K.Theme.space.xs }
    }
}

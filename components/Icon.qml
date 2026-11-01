// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Effects
import "../Shell" as K

// Single-stroke SVG icon set under assets/icons/<name>.svg, tinted with `color`.
// Qt SVG renders currentColor as black, so MultiEffect lifts it to white, then colorizes.
Item {
    id: icon
    property string name: ""
    property int size: 14
    property color color: K.Theme.text.primary
    implicitWidth: size
    implicitHeight: size

    Image {
        anchors.fill: parent
        source: icon.name.length ? Qt.resolvedUrl("../assets/icons/" + icon.name + ".svg") : ""
        sourceSize: Qt.size(icon.size * 2, icon.size * 2)
        smooth: true
        visible: status === Image.Ready
        layer.enabled: true
        layer.effect: MultiEffect {
            brightness: 1.0
            colorization: 1.0
            colorizationColor: icon.color
        }
    }

    // Fallback glyph when the SVG is missing so layout never collapses.
    Rectangle {
        anchors.centerIn: parent
        width: icon.size * 0.6; height: width; radius: width / 2
        color: icon.color
        visible: icon.name.length === 0 || parent.children[0].status !== Image.Ready
    }
}

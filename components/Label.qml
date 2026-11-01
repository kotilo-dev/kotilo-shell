import QtQuick
import "../Shell" as K

Text {
    property bool mono: false
    property bool secondary: false
    color: secondary ? K.Theme.text.secondary : K.Theme.text.primary
    font.family: mono ? K.Theme.font.mono : K.Theme.font.ui
    font.pixelSize: K.Theme.font.size - (mono ? 1 : 0)
    font.weight: Font.Medium
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}

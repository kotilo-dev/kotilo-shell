import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Pill {
    property var plugin: null
    property string slot: ""
    icon: S.Audio.icon()
    text: S.Audio.ready ? (S.Audio.muted ? "muted" : S.Audio.percent + "%") : "—"
    fg: S.Audio.muted ? K.Theme.text.muted : K.Theme.text.primary
    onClicked: S.Audio.toggleMute()
    WheelHandler { onWheel: (e) => S.Audio.step(e.angleDelta.y > 0 ? 0.05 : -0.05) }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../Shell" as K

// Audio facade over Quickshell's Pipewire service (default sink volume/mute).
Singleton {
    id: audio
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property string error: ready ? "" : "no default sink"

    // Required: audio properties of a node stay unbound until it is tracked.
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    readonly property real volume: ready ? sink.audio.volume : 0        // 0..1
    readonly property bool muted: ready && sink.audio.muted
    readonly property int percent: Math.round(volume * 100)

    function setVolume(v) { if (ready) sink.audio.volume = Math.max(0, Math.min(1.5, v)); }
    function step(delta) { setVolume(volume + delta); }
    function toggleMute() { if (ready) sink.audio.muted = !sink.audio.muted; }

    function icon() {
        if (!ready || muted || percent === 0) return "volume-x";
        return percent < 50 ? "volume-1" : "volume-2";
    }
}

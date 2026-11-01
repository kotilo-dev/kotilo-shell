// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import "../Shell" as K

// Focus Mode: a Pomodoro cycle that quiets the desktop until it is switched off. It does not
// touch the saved do not disturb setting, so ending a session leaves that as it was.
Singleton {
    id: focus
    readonly property bool ready: true
    readonly property string error: ""

    property bool active: false
    property string phase: "work"               // work or break
    property real endsAt: 0
    property int remaining: 0                   // seconds
    property int completed: 0                   // work phases finished since the shell started
    property bool mutedByFocus: false

    readonly property real workMinutes: K.Settings.get("focus", "workMinutes", 25)
    readonly property real breakMinutes: K.Settings.get("focus", "breakMinutes", 5)
    readonly property bool compactBar: K.Settings.get("focus", "compactBar", true)
    readonly property bool quiet: active && phase === "work"
    readonly property string clock: pad(Math.floor(remaining / 60)) + ":" + pad(remaining % 60)

    function pad(n) { return (n < 10 ? "0" : "") + n; }

    function enter(next) {
        phase = next;
        endsAt = Date.now() + (next === "work" ? workMinutes : breakMinutes) * 60000;
        tick();
    }

    function tick() {
        remaining = Math.max(0, Math.ceil((endsAt - Date.now()) / 1000));
        if (remaining > 0) return;
        if (phase === "work") {
            completed++;
            K.Shell.notify({ summary: "Focus session done", body: "Time for a break" });
            enter("break");
        } else {
            K.Shell.notify({ summary: "Break over", body: "Back to focus" });
            enter("work");
        }
    }

    function start() {
        if (active) return;
        active = true;
        enter("work");
        // Only undo a mute this session made, so a sink muted beforehand stays muted.
        if (K.Settings.get("focus", "mute", false) && Audio.ready && !Audio.muted) {
            Audio.toggleMute();
            mutedByFocus = true;
        }
    }

    function stop() {
        if (!active) return;
        active = false;
        remaining = 0;
        if (mutedByFocus && Audio.muted) Audio.toggleMute();
        mutedByFocus = false;
    }

    function toggle() { if (active) stop(); else start(); }

    Timer {
        interval: 1000
        repeat: true
        running: focus.active
        onTriggered: focus.tick()
    }
}

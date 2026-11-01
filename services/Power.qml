// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../Shell" as K

// Power profile through power-profiles-daemon.
Singleton {
    id: power
    property bool ready: false
    readonly property string error: ready ? "" : "no power-profiles-daemon"
    readonly property int profile: PowerProfiles.profile

    Component.onCompleted: K.Shell.run(["sh", "-c", "command -v powerprofilesctl >/dev/null && powerprofilesctl get >/dev/null"])
        .then(r => power.ready = r.code === 0, () => power.ready = false)

    function label() {
        if (profile === PowerProfile.PowerSaver) return "Power saver";
        return profile === PowerProfile.Performance ? "Performance" : "Balanced";
    }

    function cycle() {
        if (!ready) return;
        const order = [PowerProfile.PowerSaver, PowerProfile.Balanced];
        if (PowerProfiles.hasPerformanceProfile) order.push(PowerProfile.Performance);
        PowerProfiles.profile = order[(order.indexOf(profile) + 1) % order.length];
    }
}

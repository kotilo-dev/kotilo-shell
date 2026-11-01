// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications as N
import "../Shell" as K

// The notification daemon, or a read-only count from another one (ADR-0002, ADR-0007).
// Never takes org.freedesktop.Notifications from another owner.
Singleton {
    id: notif

    property var backend: null                  // another daemon's CLI, used while it owns the name
    property int passiveCount: 0
    property bool checked: false
    property bool owning: false
    property real freeSince: 0                  // when the name was first seen free, in ms
    readonly property int graceMs: 5000

    readonly property bool enabled: K.Settings.get("notifications", "daemon", true)
    readonly property var server: serverLoader.item
    readonly property var history: server ? server.trackedNotifications.values : []
    property var popupQueue: []
    readonly property var popups: popupQueue.filter(n => history.includes(n))

    readonly property int count: owning ? history.length : passiveCount
    readonly property bool ready: owning || backend !== null
    readonly property string error: checked && !ready ? "no notification daemon available" : ""

    signal openRequested()

    readonly property var backends: ({
        "swaync-client": { count: ["swaync-client", "-c"], open: ["swaync-client", "-t"], parse: o => parseInt(o) },
        "dunstctl": { count: ["dunstctl", "count", "history"], open: ["dunstctl", "history-pop"], parse: o => parseInt(o) },
        "makoctl": { count: ["makoctl", "history"], open: ["makoctl", "restore"], parse: o => (o.match(/^Notification /gm) || []).length }
    })

    // $PPID is this shell, so "self" means the name survived a reload in this process.
    readonly property string ownerScript: 'o=$(dbus-send --session --print-reply=literal --dest=org.freedesktop.DBus /org/freedesktop/DBus '
        + 'org.freedesktop.DBus.GetConnectionUnixProcessID string:org.freedesktop.Notifications 2>/dev/null) || { echo free; exit; }; '
        + '[ "${o##* }" = "$PPID" ] && echo self || echo other'

    Component.onCompleted: {
        // Through sh: a Process for a missing binary logs a warning.
        K.Shell.run(["sh", "-c", "for c in " + Object.keys(backends).join(" ") + "; do command -v \"$c\" >/dev/null && { echo \"$c\"; exit; }; done"]).then(r => {
            backend = backends[r.stdout.trim()] || null;
            checked = true;
            refresh();
        }, e => { checked = true; K.Log.warn("daemon detection failed: " + e, "notifications"); });
    }

    readonly property bool settingsReady: K.Settings.ready
    onSettingsReadyChanged: claimCheck()

    function claimCheck() {
        if (!K.Settings.ready || !enabled || owning) return;
        K.Shell.run(["sh", "-c", ownerScript]).then(r => {
            const state = r.stdout.trim();
            const now = Date.now();
            if (state !== "free") freeSince = 0;
            else if (!freeSince) freeSince = now;
            if (state === "self" || (freeSince && now - freeSince >= graceMs)) {
                owning = true;
                K.Log.info("notification daemon active", "notifications");
                return;
            }
            claimTimer.interval = freeSince ? graceMs : 15000;
            claimTimer.restart();
        }, e => K.Log.warn("owner check failed: " + e, "notifications"));
    }

    Timer { id: claimTimer; onTriggered: notif.claimCheck() }
    onEnabledChanged: { if (enabled) claimCheck(); else owning = false; }

    LazyLoader {
        id: serverLoader
        active: notif.owning

        N.NotificationServer {
            keepOnReload: true
            persistenceSupported: true
            bodySupported: true
            bodyMarkupSupported: false          // bodies are always shown as plain text
            actionsSupported: true
            imageSupported: true
            onNotification: n => notif.receive(n)
        }
    }

    readonly property bool doNotDisturb: K.Settings.get("notifications", "doNotDisturb", false)
    function toggleDoNotDisturb() { K.Settings.set("notifications", "doNotDisturb", !doNotDisturb); }

    function rule(n) {
        const rules = K.Settings.get("notifications", "rules", {});
        return rules[n.appName] || {};
    }

    function receive(n) {
        n.tracked = true;
        const critical = n.urgency === N.NotificationUrgency.Critical;
        // Focus Mode's own messages must get through the quiet they start.
        const focusHeld = Focus.quiet && n.appName !== "Kotilo Shell";
        if (rule(n).popup === false || ((doNotDisturb || focusHeld) && !critical)) {
            if (n.transient) n.expire();
            return;
        }
        popupQueue = popupQueue.concat([n]);
    }

    // How long a popup stays, in ms. 0 keeps it until dismissed.
    function timeoutFor(n) {
        if (n.urgency === N.NotificationUrgency.Critical) return 0;
        if (n.expireTimeout > 0) return n.expireTimeout;
        return K.Settings.get("notifications", "timeout", 5000);
    }

    function hidePopup(n) {
        popupQueue = popupQueue.filter(p => p !== n);
        if (n.transient) n.expire();
    }

    function dismiss(n) { hidePopup(n); n.dismiss(); }
    function clear() { history.slice().forEach(n => n.dismiss()); popupQueue = []; }

    // Plugin and shell messages go out as ordinary notifications, to whichever daemon is running.
    Connections {
        target: K.Shell
        function onNotifyRequested(n) {
            K.Shell.run(["sh", "-c", 'command -v notify-send >/dev/null && exec notify-send -a "Kotilo Shell" -u "$1" -- "$2" "$3"', "sh",
                         n.urgency || "normal", n.summary || "", n.body || ""]).catch(() => {});
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: notif.backend !== null && !notif.owning
        onTriggered: notif.refresh()
    }

    function refresh() {
        if (!backend || owning) return;
        K.Shell.run(backend.count).then(r => {
            const n = backend.parse(r.stdout);
            passiveCount = r.code === 0 && n >= 0 ? n : 0;
        }, e => K.Log.debug("count failed: " + e, "notifications"));
    }

    function open() {
        if (owning) openRequested();
        else if (backend) K.Shell.run(backend.open);
    }
}

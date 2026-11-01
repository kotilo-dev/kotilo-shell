// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell

// Minimal structured logger. Quickshell already writes stdout/stderr to its own log;
// we add level + source tags so `scripts/dev.sh` can grep them.
Singleton {
    id: root
    property int level: Quickshell.env("KOTILO_LOG") === "debug" ? 0 : 1   // 0 debug, 1 info, 2 warn, 3 error

    function fmt(lvl, msg, src) { return "[kotilo][" + lvl + "]" + (src ? "[" + src + "]" : "") + " " + msg; }

    function debug(msg, src) { if (level <= 0) console.log(fmt("debug", msg, src)); }
    function info(msg, src)  { if (level <= 1) console.log(fmt("info", msg, src)); }
    function warn(msg, src)  { if (level <= 2) console.warn(fmt("warn", msg, src)); }
    function error(msg, src) { console.error(fmt("error", msg, src)); }
}

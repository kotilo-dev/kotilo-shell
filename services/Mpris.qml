// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris as Qs

// The media player to show: the one playing, else the first. Empty when nothing is running.
// The import is qualified because this file's name would shadow the module's singleton.
Singleton {
    id: mpris
    readonly property var players: Qs.Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players[0] || null
    readonly property bool ready: player !== null
    readonly property string error: ready ? "" : "no media player"

    function toggle() { if (ready && player.canTogglePlaying) player.togglePlaying(); }
    function next() { if (ready && player.canGoNext) player.next(); }
    function previous() { if (ready && player.canGoPrevious) player.previous(); }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import "../Shell" as K
import "devstatus.js" as Dev

// Status of one repository: pinned, or the most recently touched one (ADR-0010).
Singleton {
    id: git
    property string repo: ""
    property string branch: ""
    property int ahead: 0
    property int behind: 0
    property int dirty: 0

    readonly property bool ready: repo.length > 0 && branch.length > 0
    readonly property string error: ready ? "" : "no git repository"
    readonly property string name: repo.split("/").pop()
    readonly property string home: Quickshell.env("HOME")
    readonly property string pinned: expand(K.Settings.get("bar.git", "repo", ""))

    function expand(path) { return path.replace(/^~(?=\/|$)/, home); }

    function locate() {
        if (pinned.length) { repo = pinned; poll(); return; }
        const roots = K.Settings.get("palette.projects", "roots", ["~/dev", "~/src", "~/projects", "~/code"]).map(expand);
        K.Shell.run(["sh", "-c", 'find -L "$@" -maxdepth 4 -name .git -prune -printf "%T@ %h\\n" 2>/dev/null | sort -nr | head -n 1 | cut -d" " -f2-', "sh"].concat(roots))
            .then(r => { repo = r.stdout.trim(); poll(); }, e => K.Log.warn("repo search failed: " + e, "git"));
    }

    function poll() {
        if (!repo.length) { branch = ""; return; }
        K.Shell.run(["git", "--no-optional-locks", "-c", "core.fsmonitor=false", "-C", repo, "status", "--porcelain=v2", "--branch"]).then(r => {
            const s = r.code === 0 ? Dev.parseGit(r.stdout) : { branch: "", ahead: 0, behind: 0, dirty: 0 };
            branch = s.branch; ahead = s.ahead; behind = s.behind; dirty = s.dirty;
        }, e => K.Log.debug("status failed: " + e, "git"));
    }

    readonly property bool settingsReady: K.Settings.ready
    onSettingsReadyChanged: if (settingsReady) locate()
    onPinnedChanged: if (settingsReady) locate()

    Timer { interval: 10000; repeat: true; running: git.repo.length > 0; onTriggered: git.poll() }
    Timer { interval: 60000; repeat: true; running: git.settingsReady; onTriggered: git.locate() }
}

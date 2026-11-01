// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.services as S
import qs.components as C

C.Pill {
    function counts() {
        const parts = [];
        if (S.Git.dirty) parts.push("*" + S.Git.dirty);
        if (S.Git.ahead) parts.push("↑" + S.Git.ahead);
        if (S.Git.behind) parts.push("↓" + S.Git.behind);
        return parts.join(" ");
    }
    visible: S.Git.ready
    icon: "git-branch"
    text: (S.Git.name + " " + S.Git.branch + " " + counts()).trim()
    mono: true
    iconColor: S.Git.dirty ? K.Theme.state.warning : K.Theme.text.secondary
}

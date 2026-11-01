// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell.Io
import qs.services as S

Item {
    property var plugin: null
    property string slot: ""

    IpcHandler {
        target: "focus"
        function toggle(): void { S.Focus.toggle(); }
        function start(): void { S.Focus.start(); }
        function stop(): void { S.Focus.stop(); }
    }
}

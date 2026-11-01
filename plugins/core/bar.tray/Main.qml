// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Shell as K
import qs.services as S
import qs.components as C

Row {
    id: root
    property var plugin: null
    property string slot: ""
    spacing: K.Theme.space.xs

    Repeater {
        model: S.Tray.items
        delegate: Item {
            id: entry
            required property var modelData
            implicitWidth: 26
            implicitHeight: 26
            activeFocusOnTab: true
            Keys.onPressed: event => {
                const action = K.Shell.barKey(event, entry);
                if (action === "activate") entry.primary({ x: 0, y: entry.height });
                else if (action === "menu") entry.openMenu({ x: 0, y: entry.height });
            }

            C.FocusRing { visible: entry.activeFocus }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: entry.modelData.icon
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: (e) => {
                    if (e.button === Qt.MiddleButton) entry.modelData.secondaryActivate();
                    else if (e.button === Qt.RightButton) entry.openMenu(e);
                    else entry.primary(e);
                }
                onWheel: (e) => entry.modelData.scroll(e.angleDelta.y, false)
            }

            function primary(e) {
                if (modelData.onlyMenu) openMenu(e);
                else modelData.activate();
            }

            function openMenu(e) {
                if (!modelData.hasMenu) return;
                const p = QsWindow.contentItem.mapFromItem(entry, e.x, e.y);
                modelData.display(QsWindow.window, p.x, p.y);
            }
        }
    }
}

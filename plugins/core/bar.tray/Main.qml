import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Shell as K
import qs.services as S

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

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: entry.modelData.icon
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: (e) => {
                    const item = entry.modelData;
                    if (e.button === Qt.MiddleButton) item.secondaryActivate();
                    else if (e.button === Qt.RightButton || item.onlyMenu) entry.openMenu(e);
                    else item.activate();
                }
                onWheel: (e) => entry.modelData.scroll(e.angleDelta.y, false)
            }

            function openMenu(e) {
                if (!modelData.hasMenu) return;
                const p = QsWindow.contentItem.mapFromItem(entry, e.x, e.y);
                modelData.display(QsWindow.window, p.x, p.y);
            }
        }
    }
}

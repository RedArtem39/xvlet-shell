import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.components
import qs.services

// The background apps' icons (StatusNotifierItem): a click activates, a
// right click opens their menu
Grid {
    id: root
    property bool vert: false
    columns: vert ? 1 : 32
    spacing: 2
    Repeater {
        model: SystemTray.items.values
        Item {
            id: it
            required property var modelData
            width: 34; height: 34
            Rectangle {
                anchors.fill: parent
                radius: ma.containsMouse ? 12 : 17
                color: ma.containsMouse ? Theme.alpha(Theme.fgSurface, .1) : "transparent"
                Behavior on radius { SpringAnim {} }
            }
            Image { anchors.centerIn: parent; width: 20; height: 20; source: it.modelData.icon; sourceSize: Qt.size(40, 40) }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: e => { if (e.button === Qt.RightButton && it.modelData.hasMenu) it.modelData.display(null, 0, 0); else it.modelData.activate(); }
            }
        }
    }
}

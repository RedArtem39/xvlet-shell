import QtQuick
import qs.components
import qs.services

// The launcher's button: a cookie that turns into a flower under the
// pointer, the sparkle turning back the other way; a circle while open
Item {
    id: root
    property bool vert: false

    implicitWidth: 40
    implicitHeight: 40

    MShape {
        id: s
        anchors.fill: parent
        shape: Ui.launcher ? Theme.shCircle : area.containsMouse ? Theme.shFlower : Theme.shCookie9
        color: Theme.primary
        rotation: Ui.launcher ? 0 : area.pressed ? 60 : area.containsMouse ? 40 : 0
        scale: area.pressed ? .85 : 1
        Behavior on rotation { SpringAnim {} }
        Behavior on scale { SpringAnim { ms: 350 } }
    }
    MIcon {
        anchors.centerIn: parent
        text: "auto_awesome"
        fill: true
        size: 22
        color: Theme.fgPrimary
        rotation: area.containsMouse && !Ui.launcher ? -40 : 0
        Behavior on rotation { SpringAnim {} }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Ui.openLauncher()
    }
}

import QtQuick
import qs.components
import qs.services

// The launcher's button: a cookie that turns into a flower under the
// pointer, xvlet's mark (wings of shards) beating its wings, the shards
// parting a little; a circle while open
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
    XvletMark {
        anchors.centerIn: parent
        width: 26; height: 26
        ink: Theme.fgPrimary
        ink2: Theme.mix(Theme.fgPrimary, Theme.primary, .35)
        ink3: Theme.mix(Theme.fgPrimary, Theme.primary, .6)
        flap: area.containsMouse && !Ui.launcher ? 14 : 0
        scatter: area.pressed ? .35 : area.containsMouse ? .12 : 0
        Behavior on flap { SpringAnim { ms: 500 } }
        Behavior on scatter { SpringAnim { ms: 450 } }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Ui.openLauncher()
    }
}

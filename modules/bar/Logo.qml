import QtQuick
import qs.components
import qs.services

// The launcher's button: a cookie that turns into a flower under the
// pointer, the sparkle turning back the other way
Item {
    id: root
    signal clicked

    implicitWidth: 40
    implicitHeight: 40

    MShape {
        id: s
        anchors.fill: parent
        shape: area.containsMouse ? Theme.shFlower : Theme.shCookie9
        color: Theme.primary
        rotation: area.pressed ? 60 : area.containsMouse ? 40 : 0
        scale: area.pressed ? .85 : 1
        Behavior on rotation { NumberAnimation { duration: 450; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
        Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
    }
    MIcon {
        anchors.centerIn: parent
        text: "auto_awesome"
        fill: true
        size: 22
        color: Theme.onPrimary
        rotation: area.containsMouse ? -40 : 0
        Behavior on rotation { NumberAnimation { duration: 450; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}

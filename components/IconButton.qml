import QtQuick
import qs.services

// A round icon button (.ib): its corners tighten under the pointer, it
// shrinks while pressed; `on` gives it the secondary container; `badge` a dot
Item {
    id: root
    property string icon: ""
    property bool fill: false
    property bool on: false
    property bool badge: false
    property real size: 40
    property real iconSize: 22
    property color tint: on ? Theme.fgSecondaryContainer : Theme.fgSurface
    signal clicked
    signal rightClicked

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: area.containsMouse || root.on ? 14 : root.size / 2
        scale: area.pressed ? .88 : 1
        color: root.on ? Theme.secondaryContainer : area.containsMouse ? Theme.alpha(Theme.fgSurface, .1) : "transparent"
        Behavior on radius { SpringAnim { ms: 350 } }
        Behavior on scale { SpringAnim { ms: 350 } }
        Behavior on color { ColorAnim { ms: 200 } }
    }
    MIcon {
        anchors.centerIn: parent
        text: root.icon
        fill: root.fill || root.on
        size: root.iconSize
        color: root.tint
        scale: bg.scale
    }
    Rectangle {
        width: 9; height: 9; radius: 4.5
        x: parent.width - 15; y: 6
        color: Theme.error
        scale: root.badge ? 1 : 0
        Behavior on scale { SpringAnim {} }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => { Sfx.ui("icon"); e.button === Qt.RightButton ? root.rightClicked() : root.clicked(); }
    }
}

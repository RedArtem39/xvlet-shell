import QtQuick
import qs.services

// M3 Expressive's slider: a thick track, the active part in primary up to
// a narrow handle; the icon sits inside the track's start. value 0..1.
Item {
    id: root
    property real value: 0
    property string icon: ""
    property bool showValue: true
    signal moved(real v)

    implicitHeight: 44
    implicitWidth: 240
    opacity: enabled ? 1 : .38

    readonly property real handleX: 6 + (width - 12) * Math.max(0, Math.min(1, value))

    Rectangle {
        // the inactive track
        x: root.handleX + 6; width: Math.max(0, root.width - x)
        height: 16; anchors.verticalCenter: parent.verticalCenter
        radius: 8; color: Theme.secondaryContainer
    }
    Rectangle {
        // the active part
        width: Math.max(16, root.handleX - 6)
        height: 44; anchors.verticalCenter: parent.verticalCenter
        radius: 14; color: Theme.primary
        Behavior on width { enabled: !area.pressed; SmoothAnim { ms: 200 } }
    }
    Rectangle {
        // the handle
        x: root.handleX - 2; width: area.pressed ? 3 : 4
        height: 52; anchors.verticalCenter: parent.verticalCenter
        radius: 2; color: Theme.primary
    }
    MIcon {
        x: 12; anchors.verticalCenter: parent.verticalCenter
        text: root.icon; fill: true; size: 20
        color: root.handleX > 44 ? Theme.fgPrimary : Theme.fgSecondaryContainer
        visible: root.icon !== ""
    }
    Text {
        anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
        visible: root.showValue && root.handleX < root.width - 50
        text: Math.round(root.value * 100)
        font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Bold
        color: Theme.fgSecondaryContainer
    }
    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.enabled
        function at(x) { root.moved(Math.max(0, Math.min(1, (x - 6) / (root.width - 12)))); }
        onPressed: e => at(e.x)
        onPositionChanged: e => { if (pressed) at(e.x); }
    }
    WheelHandler { enabled: root.enabled; onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? .05 : -.05)))) }
}

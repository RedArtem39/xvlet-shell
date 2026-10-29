import QtQuick
import qs.components
import qs.services

// The network, the sound and the battery in one pill: quick settings open
// from it, the wheel turns the volume. What the machine lacks is not drawn
// (the battery), or drawn crossed out (no way to the network).
Rectangle {
    id: root
    property bool vert: false
    readonly property bool on: Ui.pop === "qs"

    implicitWidth: vert ? 40 : row.implicitWidth + 28
    implicitHeight: vert ? col.implicitHeight + 20 : 40
    radius: on || area.containsMouse ? 14 : 20
    color: on ? Theme.secondaryContainer : area.containsMouse ? Theme.alpha(Theme.fgSurface, .1) : "transparent"
    Behavior on radius { SpringAnim { ms: 400 } }
    Behavior on color { ColorAnim { ms: 250 } }
    readonly property color ink: on ? Theme.fgSecondaryContainer : Theme.fgSurface

    Row {
        id: row
        visible: !root.vert
        anchors.centerIn: parent
        spacing: 8
        MIcon { text: Net.icon; fill: true; size: 20; color: Net.online ? root.ink : Theme.fgSurfaceVar }
        MIcon { text: Audio.icon; fill: true; size: 20; color: root.ink; visible: Audio.present }
        Row {
            visible: Power.present
            spacing: 4
            MIcon { text: Power.icon; fill: true; size: 20; color: root.ink }
            Label { text: Power.capacity + "%"; size: 13; color: root.ink; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    Column {
        id: col
        visible: root.vert
        anchors.centerIn: parent
        spacing: 6
        MIcon { text: Net.icon; fill: true; size: 20; color: root.ink; anchors.horizontalCenter: parent.horizontalCenter }
        MIcon { text: Audio.icon; fill: true; size: 20; color: root.ink; visible: Audio.present; anchors.horizontalCenter: parent.horizontalCenter }
        MIcon { text: Power.icon; fill: true; size: 20; color: root.ink; visible: Power.present; anchors.horizontalCenter: parent.horizontalCenter }
        Label { text: Power.capacity; size: 11; w: Font.Bold; color: root.ink; visible: Power.present; anchors.horizontalCenter: parent.horizontalCenter }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: { const p = root.mapToItem(null, root.width / 2, root.height / 2); Ui.toggle("qs", root.vert ? p.y : p.x); }
    }
    WheelHandler { onWheel: e => Audio.step(e.angleDelta.y > 0 ? .05 : -.05) }
}

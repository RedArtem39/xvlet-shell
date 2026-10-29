import QtQuick
import qs.components
import qs.services

// The processor and memory, as two small bars (the dashboard's system tab
// opens from it); on a side bar the processor's percentage
Rectangle {
    id: root
    property bool vert: false
    implicitWidth: vert ? 40 : row.implicitWidth + 24
    implicitHeight: vert ? 54 : 40
    radius: area.containsMouse ? 14 : 20
    color: area.containsMouse ? Theme.alpha(Theme.fgSurface, .1) : "transparent"
    Behavior on radius { SpringAnim {} }

    component Meter: Row {
        id: m
        property string icon
        property real v
        spacing: 6
        MIcon { text: m.icon; size: 18; anchors.verticalCenter: parent.verticalCenter }
        Rectangle {
            width: 36; height: 8; radius: 4; color: Theme.surfaceHighest
            anchors.verticalCenter: parent.verticalCenter
            Rectangle { width: parent.width * m.v; height: parent.height; radius: 4; color: Theme.primary; Behavior on width { SmoothAnim {} } }
        }
    }
    Row {
        id: row
        visible: !root.vert
        anchors.centerIn: parent
        spacing: 12
        Meter { icon: "memory"; v: Sys.cpu }
        Meter { icon: "storage"; v: Sys.ram }
    }
    Column {
        visible: root.vert
        anchors.centerIn: parent
        MIcon { text: "memory"; size: 18; anchors.horizontalCenter: parent.horizontalCenter }
        Label { text: Math.round(Sys.cpu * 100) + "%"; size: 11; w: Font.Bold; anchors.horizontalCenter: parent.horizontalCenter }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: { const p = root.mapToItem(null, root.width / 2, root.height / 2); Ui.toggle("dash", root.vert ? p.y : p.x); Ui.dashTab = "pf"; }
    }
}

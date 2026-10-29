import QtQuick
import qs.components
import qs.services

// The temperature (the dashboard's overview opens from it); no data: the
// crossed-out cloud and "нет"
Rectangle {
    id: root
    property bool vert: false
    implicitWidth: vert ? 40 : row.implicitWidth + 24
    implicitHeight: vert ? 54 : 40
    radius: area.containsMouse ? 14 : 20
    color: area.containsMouse ? Theme.alpha(Theme.fgSurface, .1) : "transparent"
    Behavior on radius { SpringAnim {} }
    Row {
        id: row
        visible: !root.vert
        anchors.centerIn: parent
        spacing: 6
        MIcon { text: Weather.icon; fill: true; size: 20; color: Weather.ok ? Theme.fgSurface : Theme.fgSurfaceVar }
        Label { text: Weather.ok ? Weather.sign(Weather.temp) : "нет"; size: 13; dim: !Weather.ok; anchors.verticalCenter: parent.verticalCenter }
    }
    Column {
        visible: root.vert
        anchors.centerIn: parent
        MIcon { text: Weather.icon; fill: true; size: 20; anchors.horizontalCenter: parent.horizontalCenter }
        Label { text: Weather.ok ? Weather.temp + "°" : "—"; size: 11; w: Font.Bold; anchors.horizontalCenter: parent.horizontalCenter }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: { const p = root.mapToItem(null, root.width / 2, root.height / 2); Ui.toggle("dash", root.vert ? p.y : p.x); Ui.dashTab = "ov"; }
    }
}

import QtQuick
import qs.components
import qs.services

// What plays: the cover (a cookie, turning while it plays), the title and
// the artist, little bars that dance; the dashboard's media tab opens from
// it. Nothing: "Ничего не играет". On a side bar only the cover.
Rectangle {
    id: root
    property bool vert: false
    implicitWidth: vert ? 40 : Math.min(480, Math.max(300, row.implicitWidth + 14))
    implicitHeight: 40
    radius: area.containsMouse ? 14 : 20
    color: area.containsMouse ? Theme.alpha(Theme.fgSurface, .1) : "transparent"
    Behavior on radius { SpringAnim {} }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        Item {
            width: 40; height: 40
            MShape {
                anchors.fill: parent
                shape: Theme.shCookie9
                color: Theme.tertiaryContainer
                RotationAnimation on rotation { from: 0; to: 360; duration: 8000; loops: Animation.Infinite; running: Media.playing && !Theme.still }
            }
            MIcon { anchors.centerIn: parent; text: "music_note"; fill: true; size: 20; color: Theme.fgTertiaryContainer }
        }
        Column {
            visible: !root.vert
            width: Math.min(300, Math.max(t1.implicitWidth, t2.implicitWidth))
            anchors.verticalCenter: parent.verticalCenter
            Label { id: t1; text: Media.title; size: 14; width: parent.width }
            Label { id: t2; text: Media.artist; size: 12; w: Font.Medium; dim: true; width: parent.width; visible: text !== "" }
        }
        Row {
            visible: !root.vert && Media.present
            spacing: 3
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: 4
                Rectangle {
                    id: eq
                    required property int index
                    width: 4; radius: 2; color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                    property real h: 6
                    height: h
                    SequentialAnimation on h {
                        running: Media.playing && !Theme.still
                        loops: Animation.Infinite
                        PauseAnimation { duration: eq.index * 140 }
                        NumberAnimation { to: 18; duration: 450; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 6; duration: 450; easing.type: Easing.InOutQuad }
                    }
                }
            }
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: { const p = root.mapToItem(null, root.width / 2, root.height / 2); Ui.toggle("dash", root.vert ? p.y : p.x); Ui.dashTab = "md"; }
    }
}

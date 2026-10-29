import QtQuick
import Quickshell
import qs.services

// The time and the short date on primary-container; the corners tighten
// under the pointer
Rectangle {
    id: root
    signal clicked

    SystemClock { id: clock; precision: SystemClock.Minutes }

    implicitWidth: row.implicitWidth + 32
    implicitHeight: 40
    radius: area.containsMouse ? 14 : 20
    color: Theme.primaryContainer
    Behavior on radius { NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10
        Text {
            text: Qt.formatTime(clock.date, "hh:mm")
            font.family: Theme.font
            font.pixelSize: 16
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
            color: Theme.onPrimaryContainer
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: clock.date.toLocaleDateString(Qt.locale("ru_RU"), "ddd, d MMM").replace(".", "")
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.Medium
            color: Theme.onPrimaryContainer
            opacity: .8
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}

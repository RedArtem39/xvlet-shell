import QtQuick
import Quickshell
import qs.components
import qs.services

// The time (and the short date) on primary-container: the dashboard opens
// from it. On a side bar the hours over the minutes.
Rectangle {
    id: root
    property bool vert: false

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property bool on: Ui.pop === "dash"

    implicitWidth: vert ? 40 : row.implicitWidth + 32
    implicitHeight: vert ? col.implicitHeight + 16 : 40
    radius: on ? 12 : area.containsMouse ? 14 : 20
    color: on ? Theme.primary : Theme.primaryContainer
    Behavior on radius { SpringAnim { ms: 400 } }
    Behavior on color { ColorAnim { ms: 300 } }
    readonly property color ink: on ? Theme.fgPrimary : Theme.fgPrimaryContainer

    Row {
        id: row
        visible: !root.vert
        anchors.centerIn: parent
        spacing: 10
        Label { text: Qt.formatTime(clock.date, "hh:mm"); size: 16; w: Font.Bold; color: root.ink; font.features: { "tnum": 1 } }
        Label {
            visible: Config.data.bar.clock === "date"
            text: clock.date.toLocaleDateString(Qt.locale("ru_RU"), "ddd, d MMM").replace(".", "")
            size: 13; w: Font.Medium; color: root.ink; opacity: .8
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    Column {
        id: col
        visible: root.vert
        anchors.centerIn: parent
        Label { text: Qt.formatTime(clock.date, "hh"); size: 15; w: Font.Bold; color: root.ink; anchors.horizontalCenter: parent.horizontalCenter }
        Label { text: Qt.formatTime(clock.date, "mm"); size: 15; w: Font.Bold; color: root.ink; anchors.horizontalCenter: parent.horizontalCenter }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: { const p = root.mapToItem(null, root.width / 2, root.height / 2); Ui.toggle("dash", root.vert ? p.y : p.x); Ui.dashTab = "ov"; }
    }
}

import QtQuick
import qs.services

// One of the bar's three zones (start, centre, end): an island of glass
// holding its modules in a row
Rectangle {
    default property alias content: row.data
    property real barHeight: 52

    implicitWidth: row.implicitWidth + 12
    implicitHeight: barHeight
    radius: barHeight / 2
    color: Theme.glass
    visible: row.children.length > 0
    Behavior on color { ColorAnimation { duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.smooth } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2
    }
}

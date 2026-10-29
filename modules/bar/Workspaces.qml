import QtQuick
import Quickshell.Hyprland
import qs.services

// Six workspaces: dots, the occupied ones bigger, the current a pill with
// its number; a trail slides under the current one. The wheel steps
// through them. (Zerp answers as Hyprland does.)
Item {
    id: root
    property int count: 6
    readonly property int current: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property var occupied: {
        const s = {};
        for (const w of Hyprland.workspaces.values) if (w.toplevels && w.toplevels.values.length) s[w.id] = true;
        return s;
    }

    implicitWidth: row.implicitWidth + 14
    implicitHeight: 40

    Rectangle {
        id: trail
        readonly property Item cur: row.children[Math.max(0, Math.min(root.count - 1, root.current - 1))] || null
        x: cur ? row.x + cur.x : 0
        y: cur ? row.y + cur.y : 0
        width: cur ? cur.width : 0
        height: cur ? cur.height : 0
        radius: 14
        color: Theme.primary
        Behavior on x { NumberAnimation { duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        x: 6
        spacing: 4
        Repeater {
            model: root.count
            Item {
                id: wd
                required property int index
                readonly property int n: index + 1
                readonly property bool cur: n === root.current
                readonly property bool occ: !!root.occupied[n]
                width: cur ? 52 : 28
                height: 28
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }

                Rectangle {
                    anchors.centerIn: parent
                    width: wd.cur ? 0 : wd.occ ? 10 : 8
                    height: width
                    radius: width / 2
                    color: hov.containsMouse ? Theme.primary : wd.occ ? Theme.onSurfaceVar : Theme.outline
                    scale: hov.containsMouse && !wd.cur ? 1.5 : 1
                    Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
                    Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
                }
                Text {
                    anchors.centerIn: parent
                    text: wd.n
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: Theme.onPrimary
                    opacity: wd.cur ? 1 : 0
                    scale: wd.cur ? 1 : .4
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                    Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }
                }
                MouseArea {
                    id: hov
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Hyprland.dispatch("workspace " + wd.n)
                }
            }
        }
    }
    WheelHandler {
        onWheel: e => Hyprland.dispatch("workspace " + Math.max(1, Math.min(root.count, root.current + (e.angleDelta.y < 0 ? 1 : -1))))
    }
}

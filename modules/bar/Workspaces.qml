import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.services

// Six workspaces: dots, the occupied ones bigger, the current a pill with
// its number (faces: pill, numbers, dots); a trail slides under the
// current one. The wheel steps through them. (Zerp answers as Hyprland.)
Item {
    id: root
    property bool vert: false
    property int count: 6
    readonly property string face: Config.data.bar.ws
    readonly property int current: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property var occupied: {
        const s = {};
        for (const w of Hyprland.workspaces.values) if (w.toplevels && w.toplevels.values.length) s[w.id] = true;
        return s;
    }
    readonly property real curLen: face === "pill" ? 52 : 28

    implicitWidth: vert ? 40 : box.implicitWidth + 14
    implicitHeight: vert ? box.implicitHeight + 14 : 40

    Rectangle {
        id: trail
        readonly property Item cur: box.children[Math.max(0, Math.min(root.count - 1, root.current - 1))] || null
        x: cur ? box.x + cur.x : 0
        y: cur ? box.y + cur.y : 0
        width: cur ? cur.width : 0
        height: cur ? cur.height : 0
        radius: 14
        color: Theme.primary
        Behavior on x { SpringAnim { ms: 500 } }
        Behavior on y { SpringAnim { ms: 500 } }
        Behavior on width { SpringAnim { ms: 500 } }
        Behavior on height { SpringAnim { ms: 500 } }
        Behavior on color { ColorAnim {} }
    }

    Grid {
        id: box
        anchors.centerIn: parent
        columns: root.vert ? 1 : root.count
        spacing: 4
        Repeater {
            model: root.count
            Item {
                id: wd
                required property int index
                readonly property int n: index + 1
                readonly property bool cur: n === root.current
                readonly property bool occ: !!root.occupied[n]
                width: !root.vert && cur ? root.curLen : 28
                height: root.vert && cur ? root.curLen : 28
                Behavior on width { SpringAnim { ms: 500 } }
                Behavior on height { SpringAnim { ms: 500 } }

                Rectangle {
                    anchors.centerIn: parent
                    visible: root.face !== "numbers"
                    width: wd.cur ? 0 : wd.occ ? 10 : 8
                    height: width
                    radius: width / 2
                    color: hov.containsMouse ? Theme.primary : wd.occ ? Theme.fgSurfaceVar : Theme.outline
                    scale: hov.containsMouse && !wd.cur ? 1.5 : 1
                    Behavior on width { SpringAnim {} }
                    Behavior on scale { SpringAnim {} }
                }
                Label {
                    anchors.centerIn: parent
                    text: wd.n
                    size: 13
                    w: Font.Bold
                    color: wd.cur ? Theme.fgPrimary : wd.occ ? Theme.fgSurface : Theme.fgSurfaceVar
                    opacity: root.face === "numbers" || (wd.cur && root.face === "pill") ? 1 : 0
                    scale: opacity ? 1 : .4
                    Behavior on opacity { NumberAnimation { duration: Theme.ms(250) } }
                    Behavior on scale { SpringAnim {} }
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

import QtQuick
import qs.components
import qs.services

// A popout's body (components/EdgeSheet.qml), two ways:
//   free      the surface, the large radius; it grows out of the bar's side
//             with the spring and fades
//   attached  (bar.attach) against the bar's inner side, concave corners
//             where it meets it, rolled out from under it
// It takes its own clicks (a click inside does not close it).
Item {
    id: root
    property bool shown: false
    property string origin: "top"
    property real pad: 18
    property bool attached: Config.data.bar.attach === true
    default property alias content: body.content

    visible: attached ? body.out : opacity > 0.01
    opacity: attached || shown ? 1 : 0
    scale: attached || shown ? 1 : .94
    transformOrigin: origin === "top" ? Item.Top : origin === "bottom" ? Item.Bottom : origin === "left" ? Item.Left : Item.Right
    Behavior on opacity { enabled: !root.attached; SmoothAnim { ms: 220 } }
    Behavior on scale { enabled: !root.attached; SpringAnim { ms: 500 } }

    transform: Translate {
        x: root.shown || root.attached ? 0 : root.origin === "left" ? -14 : root.origin === "right" ? 14 : 0
        y: root.shown || root.attached ? 0 : root.origin === "top" ? -14 : root.origin === "bottom" ? 14 : 0
        Behavior on x { enabled: !root.attached; SpringAnim { ms: 500 } }
        Behavior on y { enabled: !root.attached; SpringAnim { ms: 500 } }
    }
    EdgeSheet {
        id: body
        anchors.fill: parent
        side: root.origin
        attached: root.attached
        shown: root.shown
        pad: root.pad
    }
}

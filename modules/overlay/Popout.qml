import QtQuick
import QtQuick.Effects
import qs.components
import qs.services

// A popout's body: the surface, the large radius; it grows out of the bar's
// side with the spring and fades, and takes its own clicks (a click inside
// does not close it)
Item {
    id: root
    property bool shown: false
    property string origin: "top"
    property real pad: 18
    default property alias content: holder.data

    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    scale: shown ? 1 : .94
    transformOrigin: origin === "top" ? Item.Top : origin === "bottom" ? Item.Bottom : origin === "left" ? Item.Left : Item.Right
    Behavior on opacity { SmoothAnim { ms: 220 } }
    Behavior on scale { SpringAnim { ms: 500 } }

    transform: Translate {
        x: root.shown ? 0 : root.origin === "left" ? -14 : root.origin === "right" ? 14 : 0
        y: root.shown ? 0 : root.origin === "top" ? -14 : root.origin === "bottom" ? 14 : 0
        Behavior on x { SpringAnim { ms: 500 } }
        Behavior on y { SpringAnim { ms: 500 } }
    }
    RectangularShadow { anchors.fill: parent; radius: Theme.r; blur: 80; spread: -24; offset.y: 24; color: Theme.shadow }
    Rectangle {
        anchors.fill: parent
        radius: Theme.r
        color: Theme.surfaceLow
        border.width: 1; border.color: Theme.alpha(Theme.fgSurface, .06)
        Behavior on color { ColorAnim { ms: 900 } }
    }
    MouseArea { anchors.fill: parent; onWheel: w => w.accepted = true }
    Item {
        id: holder
        anchors.fill: parent
        anchors.margins: root.pad
    }
}

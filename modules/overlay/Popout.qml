import QtQuick
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
    scale: shown ? 1 : .92
    transformOrigin: origin === "top" ? Item.Top : origin === "bottom" ? Item.Bottom : origin === "left" ? Item.Left : Item.Right
    Behavior on opacity { SmoothAnim { ms: 220 } }
    Behavior on scale { SpringAnim { ms: 420 } }

    Rectangle {
        anchors.fill: parent
        radius: Theme.r
        color: Theme.surfaceLow
        Behavior on color { ColorAnim {} }
        Rectangle {
            // a soft shadow under it
            anchors.fill: parent; anchors.topMargin: 14; anchors.margins: -2
            z: -1; radius: parent.radius
            color: Theme.alpha(Theme.shadow, .35)
        }
    }
    MouseArea { anchors.fill: parent; onWheel: w => w.accepted = true }
    Item {
        id: holder
        anchors.fill: parent
        anchors.margins: root.pad
    }
}

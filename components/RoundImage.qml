import QtQuick
import qs.services

// A picture with rounded corners on a known background: four corner caps
// of the background's colour over it (no shader: it draws the same on
// any renderer). Children go over the picture.
Item {
    id: root
    property alias source: img.source
    property alias sourceSize: img.sourceSize
    property real radius: Theme.rm
    property color bg: Theme.surfaceMid
    default property alias content: over.data

    Rectangle { anchors.fill: parent; radius: root.radius; color: Theme.surfaceHighest }
    Image {
        id: img
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    Fillet { anchors.left: parent.left; anchors.top: parent.top; size: root.radius; hole: "br"; color: root.bg }
    Fillet { anchors.right: parent.right; anchors.top: parent.top; size: root.radius; hole: "bl"; color: root.bg }
    Fillet { anchors.left: parent.left; anchors.bottom: parent.bottom; size: root.radius; hole: "tr"; color: root.bg }
    Fillet { anchors.right: parent.right; anchors.bottom: parent.bottom; size: root.radius; hole: "tl"; color: root.bg }
    Item { id: over; anchors.fill: parent }
}

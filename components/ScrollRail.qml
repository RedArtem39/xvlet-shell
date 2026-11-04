import QtQuick
import qs.services

// A scrollbar for a Flickable (a mouse without a wheel, a touchpad): a
// thin rail at its right edge, wider under the pointer; the thumb dragged,
// the rail clicked a page up or down. Hidden when everything fits.
//   ScrollRail { flick: fl }   -- placed over the Flickable, not in it
Item {
    id: root
    required property Flickable flick
    readonly property real span: Math.max(1, flick.contentHeight - flick.height)
    readonly property bool needed: flick.contentHeight > flick.height + 1

    x: flick.x + flick.width - width - 4
    y: flick.y + 6
    width: 14; height: flick.height - 12
    visible: needed
    opacity: hov.hovered || drag.active || flick.moving || shown.running ? 1 : .45
    Behavior on opacity { SmoothAnim { ms: 250 } }
    // shown a moment after the page moves
    Timer { id: shown; interval: 900; running: false }
    Connections { target: root.flick; function onContentYChanged() { shown.restart(); } }

    HoverHandler { id: hov }

    // the rail: a page up or down where clicked
    MouseArea {
        anchors.fill: parent
        onClicked: m => {
            const page = root.flick.height * .9;
            const to = m.y < thumb.y ? root.flick.contentY - page : root.flick.contentY + page;
            root.flick.contentY = Math.max(0, Math.min(root.span, to));
        }
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: hov.hovered || drag.active ? 8 : 4; height: parent.height
        radius: width / 2
        color: Theme.surfaceHighest
        opacity: hov.hovered || drag.active ? .8 : 0
        Behavior on width { SpringAnim { ms: 300 } }
        Behavior on opacity { SmoothAnim { ms: 200 } }
    }
    Rectangle {
        id: thumb
        readonly property real len: Math.max(36, root.height * root.flick.height / Math.max(1, root.flick.contentHeight))
        anchors.horizontalCenter: parent.horizontalCenter
        width: hov.hovered || drag.active ? 8 : 4; height: len
        y: (root.height - len) * Math.max(0, Math.min(1, root.flick.contentY / root.span))
        radius: width / 2
        color: drag.active ? Theme.primary : Theme.outline
        Behavior on width { SpringAnim { ms: 300 } }
        Behavior on color { ColorAnimation { duration: 150 } }
        DragHandler {
            id: drag
            target: thumb
            xAxis.enabled: false
            yAxis.minimum: 0; yAxis.maximum: root.height - thumb.len
            onActiveChanged: if (!active) thumb.y = Qt.binding(() => (root.height - thumb.len) * Math.max(0, Math.min(1, root.flick.contentY / root.span)))
        }
        onYChanged: if (drag.active) root.flick.contentY = root.span * y / Math.max(1, root.height - len)
    }
}

import QtQuick
import QtQuick.Effects
import qs.services

// A sheet's body, two ways (the prototype's .pop and .pop.att):
//   free      the popout's own: the low surface, round all round, a shadow
//             -- its coming and going is the parent's (a fade, a spring)
//   attached  against an edge (the bar's inner side, or the screen's):
//             the bar's surface, square on that side, concave corners
//             where it meets it, rolled out from behind it -- clipped at
//             the edge, so it unrolls instead of popping up
// The content goes inside, `pad` in from its sides.
Item {
    id: root
    property string side: "top"          // the edge it is against (attached)
    property bool attached: false
    property bool shown: false
    property real pad: 18
    property real r: Theme.r
    default property alias content: holder.data

    readonly property bool horiz: side === "top" || side === "bottom"
    // how far out it is: 0 behind the edge, 1 all out
    property real reveal: shown ? 1 : 0
    Behavior on reveal { SmoothAnim { ms: 450 } }
    readonly property bool out: !attached || reveal > 0.001

    Item {
        id: clipper
        // (attached: room for the fillets either side of it, along the edge)
        x: root.attached && root.horiz ? -root.r : 0
        y: root.attached && !root.horiz ? -root.r : 0
        width: root.width + (root.attached && root.horiz ? root.r * 2 : 0)
        height: root.height + (root.attached && !root.horiz ? root.r * 2 : 0)
        clip: root.attached

        Item {
            id: sheet
            x: root.attached && root.horiz ? root.r : 0
            y: root.attached && !root.horiz ? root.r : 0
            width: root.width; height: root.height
            transform: Translate {
                readonly property real k: root.attached ? 1 - root.reveal : 0
                x: root.side === "left" ? -k * sheet.width : root.side === "right" ? k * sheet.width : 0
                y: root.side === "top" ? -k * sheet.height : root.side === "bottom" ? k * sheet.height : 0
            }

            RectangularShadow {
                visible: !root.attached
                anchors.fill: parent; radius: root.r; blur: 80; spread: -24; offset.y: 24; color: Theme.shadow
            }
            Rectangle {
                anchors.fill: parent
                readonly property string s: root.attached ? root.side : ""
                color: root.attached ? Theme.surface : Theme.surfaceLow
                border.width: root.attached ? 0 : 1; border.color: Theme.edge
                topLeftRadius: s === "top" || s === "left" ? 0 : root.r
                topRightRadius: s === "top" || s === "right" ? 0 : root.r
                bottomLeftRadius: s === "bottom" || s === "left" ? 0 : root.r
                bottomRightRadius: s === "bottom" || s === "right" ? 0 : root.r
                Behavior on color { ColorAnim { ms: 900 } }
            }
            // the concave corners where it meets the edge
            Fillet {
                visible: root.attached; size: root.r; color: Theme.surface
                x: root.horiz ? -size : root.side === "left" ? 0 : sheet.width - size
                y: root.horiz ? (root.side === "top" ? 0 : sheet.height - size) : -size
                hole: ({ top: "bl", bottom: "tl", left: "tr", right: "tl" })[root.side]
            }
            Fillet {
                visible: root.attached; size: root.r; color: Theme.surface
                x: root.horiz ? sheet.width : root.side === "left" ? 0 : sheet.width - size
                y: root.horiz ? (root.side === "top" ? 0 : sheet.height - size) : sheet.height
                hole: ({ top: "br", bottom: "tr", left: "br", right: "bl" })[root.side]
            }
            MouseArea { anchors.fill: parent; onWheel: w => w.accepted = true }
            Item {
                id: holder
                anchors.fill: parent
                anchors.margins: root.pad
            }
        }
    }
}

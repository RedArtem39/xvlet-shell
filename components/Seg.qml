import QtQuick
import qs.services

// A connected button group (the prototype's .seg): filled buttons 2 px
// apart, the outer ends round, the inner corners small; the chosen one in
// the secondary container, fully round. model [{ k, n, i }]
Row {
    id: root
    property var model: []
    property var value
    signal picked(var k)

    spacing: 2
    height: 40

    Repeater {
        model: root.model
        Item {
            id: seg
            required property var modelData
            required property int index
            readonly property bool on: root.value === modelData.k
            readonly property bool first: index === 0
            readonly property bool last: index === root.model.length - 1
            readonly property real rl: on || first ? 20 : 8
            readonly property real rr: on || last ? 20 : 8
            width: row.implicitWidth + 32
            height: root.height

            Rectangle {
                anchors.fill: parent
                topLeftRadius: seg.rl; bottomLeftRadius: seg.rl
                topRightRadius: seg.rr; bottomRightRadius: seg.rr
                color: seg.on ? Theme.secondaryContainer : ma.containsMouse ? Theme.surfaceHighest : Theme.surfaceHigh
                Behavior on color { ColorAnim { ms: 250 } }
                Behavior on topLeftRadius { SpringAnim { ms: 400 } }
                Behavior on bottomLeftRadius { SpringAnim { ms: 400 } }
                Behavior on topRightRadius { SpringAnim { ms: 400 } }
                Behavior on bottomRightRadius { SpringAnim { ms: 400 } }
            }
            Row {
                id: row
                anchors.centerIn: parent
                spacing: 6
                MIcon {
                    visible: !!seg.modelData.i
                    text: seg.modelData.i || ""
                    size: 18
                    color: lbl.color
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    id: lbl
                    text: seg.modelData.n
                    size: 13.5; w: 650
                    color: seg.on ? Theme.fgSecondaryContainer : Theme.fgSurfaceVar
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: { Sfx.ui("switch"); root.picked(seg.modelData.k); } }
        }
    }
}

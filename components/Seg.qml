import QtQuick
import qs.services

// Segmented buttons: model [{ k, n, i }], the chosen one in the secondary
// container with a check
Rectangle {
    id: root
    property var model: []
    property var value
    signal picked(var k)

    implicitHeight: 40
    implicitWidth: row.implicitWidth
    radius: 20
    color: "transparent"
    border.width: 1.5
    border.color: Theme.outline
    clip: true

    Row {
        id: row
        anchors.fill: parent
        Repeater {
            model: root.model
            Rectangle {
                id: seg
                required property var modelData
                required property int index
                readonly property bool on: root.value === modelData.k
                width: Math.max(64, lbl.implicitWidth + (on || modelData.i ? 46 : 28))
                height: root.height
                color: on ? Theme.secondaryContainer : ma.containsMouse ? Theme.alpha(Theme.fgSurface, .08) : "transparent"
                Behavior on color { ColorAnim { ms: 200 } }
                Rectangle { visible: seg.index > 0; width: 1.5; height: parent.height; color: Theme.outline }
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    MIcon {
                        visible: seg.on || !!seg.modelData.i
                        text: seg.on ? "check" : (seg.modelData.i || "")
                        size: 18
                        color: seg.on ? Theme.fgSecondaryContainer : Theme.fgSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        id: lbl
                        text: seg.modelData.n
                        font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold
                        color: seg.on ? Theme.fgSecondaryContainer : Theme.fgSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: root.picked(seg.modelData.k) }
            }
        }
    }
}

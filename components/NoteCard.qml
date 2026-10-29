import QtQuick
import qs.services

// A toast (the prototype's .toast): the app's icon on a primary container,
// the summary, the body, its actions (the first one primary). A click on
// the card closes it.
Rectangle {
    id: root
    property var n
    property bool toast: true

    implicitHeight: Math.max(48, col.implicitHeight) + 32
    radius: 28
    color: Theme.surfaceMid
    clip: true

    MouseArea { anchors.fill: parent; onClicked: if (root.n) Notifs.dropToast(root.n) }
    Rectangle {
        x: 16; y: 16
        width: 48; height: 48; radius: 18
        color: Theme.primaryContainer
        Image {
            id: pic
            anchors.fill: parent; anchors.margins: 8
            source: root.n && root.n.image ? root.n.image : (root.n && root.n.appIcon ? "image://icon/" + root.n.appIcon : "")
            visible: status === Image.Ready
            fillMode: Image.PreserveAspectFit
        }
        MIcon { anchors.centerIn: parent; text: Notifs.symbol(root.n || {}); size: 24; color: Theme.fgPrimaryContainer; visible: !pic.visible }
    }
    Column {
        id: col
        x: 16 + 48 + 14; y: 16
        width: parent.width - x - 16
        Label { text: root.n ? root.n.summary : ""; size: 15; w: 700; width: parent.width }
        Label { text: root.n ? root.n.body : ""; size: 13.5; w: 500; dim: true; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 3; lineHeight: 1.1; topPadding: 3; visible: text !== "" }
        Row {
            visible: root.n && root.n.actions && root.n.actions.length > 0
            spacing: 6
            topPadding: 12
            Repeater {
                model: root.n ? root.n.actions : []
                Rectangle {
                    id: act
                    required property var modelData
                    required property int index
                    width: al.implicitWidth + 32; height: 36; radius: am.containsMouse ? 12 : 18
                    color: index === 0 ? Theme.primary : Theme.surfaceHighest
                    Behavior on radius { SpringAnim { ms: 350 } }
                    Label { id: al; anchors.centerIn: parent; text: act.modelData.text; size: 13; w: 650; color: act.index === 0 ? Theme.fgPrimary : Theme.fgSurface }
                    MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; onClicked: { act.modelData.invoke(); Notifs.dropToast(root.n); } }
                }
            }
        }
    }
}

import QtQuick
import qs.services

// A notification: its app's icon (or image) in a circle, the summary, the
// body, its actions; a click on the cross (or the card) dismisses it
Rectangle {
    id: root
    property var n
    property bool toast: false

    implicitHeight: col.implicitHeight + 24
    radius: Theme.rs
    color: toast ? Theme.surfaceMid : Theme.surfaceHigh

    Row {
        x: 12; y: 12
        width: parent.width - 24
        spacing: 12
        Rectangle {
            width: 44; height: 44; radius: 22
            color: Theme.secondaryContainer
            Image { anchors.fill: parent; anchors.margins: 6; source: root.n && root.n.image ? root.n.image : (root.n && root.n.appIcon ? "image://icon/" + root.n.appIcon : ""); visible: status === Image.Ready; fillMode: Image.PreserveAspectFit }
            MIcon { anchors.centerIn: parent; text: Notifs.symbol(root.n || {}); fill: true; size: 22; color: Theme.fgSecondaryContainer; visible: !parent.children[0].visible }
        }
        Column {
            id: col
            width: parent.width - 44 - 12 - 28
            spacing: 3
            Label { text: root.n ? root.n.summary : ""; size: 14; w: Font.Bold; width: parent.width }
            Label { text: root.n ? root.n.body : ""; size: 13; w: Font.Normal; dim: true; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 3; visible: text !== "" }
            Row {
                visible: root.n && root.n.actions && root.n.actions.length > 0
                spacing: 6
                topPadding: 6
                Repeater {
                    model: root.n ? root.n.actions : []
                    Rectangle {
                        id: act
                        required property var modelData
                        required property int index
                        width: al.implicitWidth + 28; height: 34; radius: am.containsMouse ? 12 : 17
                        color: index === 0 ? Theme.primary : Theme.surfaceHighest
                        Behavior on radius { SpringAnim {} }
                        Label { id: al; anchors.centerIn: parent; text: act.modelData.text; size: 13; color: act.index === 0 ? Theme.fgPrimary : Theme.fgSurface }
                        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; onClicked: act.modelData.invoke() }
                    }
                }
            }
        }
    }
    IconButton {
        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 6
        icon: "close"; size: 28; iconSize: 16
        onClicked: if (root.n) Notifs.dismiss(root.n)
    }
}

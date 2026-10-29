import QtQuick
import qs.services

// M3's switch: the handle grows and slides when on
Item {
    id: root
    property bool checked: false
    signal toggled(bool v)

    implicitWidth: 52
    implicitHeight: 32
    opacity: enabled ? 1 : .38

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: root.checked ? Theme.primary : Theme.surfaceHighest
        border.width: root.checked ? 0 : 2
        border.color: Theme.outline
        Behavior on color { ColorAnim { ms: 250 } }
    }
    Rectangle {
        property real s: root.checked ? 24 : area.pressed ? 28 : 16
        width: s; height: s; radius: s / 2
        x: root.checked ? root.width - s - 4 : 8 - (s - 16) / 2
        y: (root.height - s) / 2
        color: root.checked ? Theme.fgPrimary : Theme.outline
        Behavior on x { SpringAnim { ms: 350 } }
        Behavior on s { SpringAnim { ms: 350 } }
        Behavior on color { ColorAnim { ms: 250 } }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.enabled
        onClicked: { root.checked = !root.checked; root.toggled(root.checked); }
    }
}

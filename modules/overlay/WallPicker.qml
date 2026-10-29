import QtQuick
import qs.components
import qs.services

// The wallpaper picker: a carousel -- the chosen one big in the middle,
// its neighbours smaller; the arrows and the wheel move, Enter or a click
// on the middle one puts it on (it comes over the old one out of the
// middle of the screen).
Item {
    id: root
    property bool shown: false

    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    Behavior on opacity { SmoothAnim { ms: 250 } }
    onShownChanged: if (shown) { track.currentIndex = Math.max(0, Walls.list.indexOf(Config.data.wall.path)); track.forceActiveFocus(); }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 300
        text: "Обои"; size: 30; w: Font.Bold; color: "white"
    }
    ListView {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 420
        orientation: ListView.Horizontal
        spacing: 24
        model: Walls.list
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - 640) / 2
        preferredHighlightEnd: (width + 640) / 2
        highlightMoveDuration: Theme.ms(450)
        focus: root.shown
        Keys.onReturnPressed: Walls.set(model[currentIndex])
        Keys.onEscapePressed: Ui.wallpick = false
        delegate: Item {
            id: w
            required property string modelData
            required property int index
            readonly property bool cur: ListView.isCurrentItem
            readonly property bool on: Config.data.wall.path === modelData
            width: 640; height: 420
            Rectangle {
                anchors.centerIn: parent
                width: w.cur ? 640 : 520; height: w.cur ? 380 : 300
                radius: w.cur ? Theme.r : 48
                color: Theme.surfaceHigh
                clip: true
                Behavior on width { SpringAnim {} }
                Behavior on height { SpringAnim {} }
                Behavior on radius { SpringAnim {} }
                border.width: w.on ? 4 : 0
                border.color: Theme.primary
                Image {
                    anchors.fill: parent; anchors.margins: parent.border.width
                    source: "file://" + w.modelData
                    sourceSize: Qt.size(640, 380)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Rectangle {
                    visible: w.on
                    anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                    width: 36; height: 36; radius: 18; color: Theme.primary
                    MIcon { anchors.centerIn: parent; text: "check"; size: 22; color: Theme.fgPrimary }
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: { if (w.cur) Walls.set(w.modelData); else track.currentIndex = w.index; }
            }
        }
        WheelHandler { onWheel: e => track.currentIndex = Math.max(0, Math.min(track.count - 1, track.currentIndex + (e.angleDelta.y < 0 ? 1 : -1))) }
    }
    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 + 230
        text: Walls.list.length ? (Walls.list[track.currentIndex] || "").split("/").pop() : "Обоев нет: положите картинки в ~/Pictures/Wallpapers"
        size: 14; color: "white"; opacity: .8
    }
}

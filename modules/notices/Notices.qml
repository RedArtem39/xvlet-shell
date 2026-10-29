import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

// What appears by itself: the toasts (a corner of the work area, from the
// settings; each for some seconds, paused under the pointer) and the OSD
// (the volume, the brightness -- a pill at the bottom's middle). Only they
// take the pointer.
PanelWindow {
    id: root

    readonly property string corner: Config.data.notif.pos
    readonly property var bcfg: Config.data.bar
    readonly property real barThick: bcfg.style === "islands" ? bcfg.height + 10 : bcfg.height
    function inset(edge) { return bcfg.pos === edge ? barThick : 0; }

    WlrLayershell.namespace: "xvlet-notices"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: Region { item: toasts; Region { item: osd } }

    Column {
        id: toasts
        width: 400
        spacing: 8
        readonly property bool atBottom: root.corner[0] === "b"
        x: root.corner[1] === "l" ? 12 + root.inset("left") : root.corner[1] === "c" ? (root.width - width) / 2 : root.width - width - 12 - root.inset("right")
        y: atBottom ? root.height - height - 12 - root.inset("bottom") : 12 + root.inset("top")
        Repeater {
            model: Notifs.toasts
            NoteCard {
                id: tc
                required property var modelData
                n: modelData
                toast: true
                width: toasts.width
                opacity: 0
                Component.onCompleted: { opacity = 1; lifeAnim.start(); }
                Behavior on opacity { SmoothAnim { ms: 250 } }
                transform: Translate { id: tr; x: 40; Component.onCompleted: x = 0; Behavior on x { SpringAnim {} } }
                Rectangle {
                    // how long it stays: a line that runs out
                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 12
                    height: 3; radius: 1.5; color: Theme.primary; opacity: .6
                    width: (parent.width - 24) * tc.life
                }
                property real life: 1
                NumberAnimation on life { id: lifeAnim; running: false; from: 1; to: 0; duration: Config.data.notif.secs * 1000; paused: hov.hovered; onFinished: Notifs.dropToast(tc.modelData) }
                HoverHandler { id: hov }
            }
        }
    }

    // the OSD: the volume or the brightness
    Rectangle {
        id: osd
        readonly property bool vol: Ui.osd === "volume"
        readonly property real v: vol ? Audio.volume : Brightness.value
        width: 340; height: 60; radius: 30
        x: (root.width - width) / 2
        y: root.height - height - 90 - root.inset("bottom")
        color: Theme.surfaceMid
        opacity: Ui.osd !== "" ? 1 : 0
        scale: Ui.osd !== "" ? 1 : .9
        visible: opacity > 0.01
        Behavior on opacity { SmoothAnim { ms: 200 } }
        Behavior on scale { SpringAnim {} }
        Row {
            anchors.centerIn: parent; spacing: 14
            MIcon { text: osd.vol ? Audio.icon : "light_mode"; fill: true; size: 24; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                width: 200; height: 10; radius: 5; color: Theme.surfaceHighest; anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: parent.width * osd.v; height: parent.height; radius: 5; color: Theme.primary; Behavior on width { SmoothAnim { ms: 150 } } }
            }
            Label { text: Math.round(osd.v * 100); size: 15; w: Font.Bold; width: 34; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}

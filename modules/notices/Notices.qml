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
                scale: .9
                Behavior on opacity { SmoothAnim { ms: 300 } }
                Behavior on scale { SpringAnim { ms: 600 } }
                transform: Translate {
                    x: root.corner[1] === "c" ? 0 : root.corner[1] === "l" ? -tc.width * 1.1 : tc.width * 1.1
                    y: root.corner[1] === "c" ? -40 : 0
                    Component.onCompleted: { x = 0; y = 0; tc.scale = 1; }
                    Behavior on x { SpringAnim { ms: 600 } }
                    Behavior on y { SpringAnim { ms: 600 } }
                }
                Rectangle {
                    // how long it stays: a line that runs out
                    anchors.bottom: parent.bottom; anchors.left: parent.left
                    height: 3; color: Theme.primary; opacity: .6
                    width: parent.width * tc.life
                }
                property real life: 1
                NumberAnimation on life { id: lifeAnim; running: false; from: 1; to: 0; duration: Config.data.notif.secs * 1000; paused: hov.hovered; onFinished: Notifs.dropToast(tc.modelData) }
                HoverHandler { id: hov }
            }
        }
    }

    // the OSD (the prototype's .osd): a tall pill at the right edge, the
    // icon, the level filling from below, the number
    Rectangle {
        id: osd
        readonly property bool vol: Ui.osd === "volume"
        readonly property real v: vol ? Audio.volume : Brightness.value
        width: 64; height: 300; radius: 32
        x: root.width - width - 14 - root.inset("right") - 12
        y: (root.height - height) / 2
        color: Theme.surfaceMid
        opacity: Ui.osd !== "" ? 1 : 0
        scale: Ui.osd !== "" ? 1 : .9
        transform: Translate { x: Ui.osd !== "" ? 0 : 40; Behavior on x { SpringAnim { ms: 500 } } }
        visible: opacity > 0.01
        Behavior on opacity { SmoothAnim { ms: 250 } }
        Behavior on scale { SpringAnim { ms: 500 } }
        Column {
            anchors.fill: parent; anchors.margins: 8
            spacing: 8
            MIcon { anchors.horizontalCenter: parent.horizontalCenter; text: osd.vol ? Audio.icon : "light_mode"; fill: true; size: 24; color: Theme.fgSurfaceVar }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 48; height: parent.height - 24 - 18 - 16
                radius: 24; color: Theme.surfaceHighest
                clip: true
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: Math.max(24, parent.height * osd.v)
                    topLeftRadius: 8; topRightRadius: 8; bottomLeftRadius: 24; bottomRightRadius: 24
                    color: Theme.primary
                    Behavior on height { SpringAnim { ms: 350 } }
                }
            }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(osd.v * 100); size: 13; w: 750; font.features: { "tnum": 1 } }
        }
    }
}

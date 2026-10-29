import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

// The wallpaper, under everything (the background layer). A new one comes
// over the old: a circle out of where it was picked, a dissolve, a slanted
// wipe, a zoom out of blur (Settings: Переход).
PanelWindow {
    id: root

    readonly property string path: Config.data.wall.path
    readonly property string trans: Config.data.wall.trans
    property string shown: ""
    property real tx: width / 2
    property real ty: height / 2

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "xvlet-wallpaper"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.surface

    Image {
        id: base
        anchors.fill: parent
        source: root.shown ? "file://" + root.shown : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(root.width, root.height)
    }
    Item {
        id: top
        anchors.fill: parent
        visible: false
        property real k: 0
        Image {
            id: next
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(root.width, root.height)
            scale: root.trans === "zoom" ? 1.25 - .25 * top.k : 1
            onStatusChanged: if (status === Image.Ready && top.visible) run.restart()
        }
        layer.enabled: visible && (root.trans === "circle" || root.trans === "wipe")
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskItem
            maskThresholdMin: .5
            maskSpreadAtMin: .2
        }
        opacity: root.trans === "fade" || root.trans === "zoom" ? k : 1
    }
    Item {
        id: maskItem
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            visible: root.trans === "circle"
            readonly property real d: Math.hypot(root.width, root.height) * 2.2 * top.k
            width: d; height: d; radius: d / 2
            x: root.tx - d / 2; y: root.ty - d / 2
        }
        Rectangle {
            visible: root.trans === "wipe"
            width: root.width * 1.6 * top.k; height: root.height * 1.6
            x: -root.width * .3; y: -root.height * .3
            rotation: -12
        }
    }
    NumberAnimation {
        id: run
        target: top; property: "k"; from: 0; to: 1
        duration: Theme.still ? 1 : root.trans === "fade" ? 1000 : 1100
        easing.type: Easing.BezierSpline; easing.bezierCurve: [.55, 0, .25, 1, 1, 1]
        onFinished: { root.shown = root.path; top.visible = false; top.k = 0; }
    }
    onPathChanged: {
        if (!shown) { shown = path; return; }
        if (path === shown) return;
        top.k = 0; top.visible = true;
        next.source = "file://" + path;
        if (next.status === Image.Ready) run.restart();
    }
    Component.onCompleted: shown = path
    // where the new one was picked (the circle comes out of it)
    function from(x, y) { tx = x; ty = y; }
}

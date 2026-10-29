import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

// Exo's frame: a bar flush with the edge (and a dock that is a strip) are
// the frame; what they leave of the screen gets rounded corners. Four
// concave corners of the surface over the work area's corners -- above the
// windows, taking no input.
PanelWindow {
    id: root

    readonly property var bcfg: Config.data.bar
    readonly property var dcfg: Config.data.dock
    readonly property bool flush: bcfg.style === "flush"
    readonly property bool strip: dcfg.on && dcfg.style === "strip" && dcfg.pos !== bcfg.pos
    visible: (flush || strip) && Config.data.theme.shellCorners
    WlrLayershell.namespace: "xvlet-frame"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: Region {}

    function inset(edge) {
        let v = 0;
        if (flush && bcfg.pos === edge) v += bcfg.height;
        if (strip && dcfg.pos === edge) v += dcfg.size + 12;
        return v;
    }
    readonly property real t: inset("top")
    readonly property real b: inset("bottom")
    readonly property real l: inset("left")
    readonly property real r: inset("right")
    readonly property real rad: Theme.r

    Corner { x: root.l; y: root.t; cx: 1; cy: 1 }
    Corner { x: root.width - root.r - root.rad; y: root.t; cx: 0; cy: 1 }
    Corner { x: root.l; y: root.height - root.b - root.rad; cx: 1; cy: 0 }
    Corner { x: root.width - root.r - root.rad; y: root.height - root.b - root.rad; cx: 0; cy: 0 }

    component Corner: Canvas {
        required property int cx      // the circle's centre: 1 = the far side of the square
        required property int cy
        width: root.rad; height: root.rad
        property color c: Theme.surface
        onCChanged: requestPaint()
        onWidthChanged: requestPaint()
        Behavior on x { SpringAnim { ms: 500 } }
        Behavior on y { SpringAnim { ms: 500 } }
        onPaint: {
            const g = getContext("2d"), F = width; g.reset();
            g.fillStyle = c; g.fillRect(0, 0, F, F);
            g.globalCompositeOperation = "destination-out";
            g.beginPath(); g.arc(cx * F, cy * F, F, 0, Math.PI * 2); g.fill();
        }
    }
}

import QtQuick
import qs.services

// M3 Expressive's wavy progress (the media's): a 44 px wave up to the
// thumb, a flat track after it; flat while paused or dragged. Press or drag
// it to seek: seek(frac).
Canvas {
    id: root
    property real value: 0
    property bool waving: true
    property color fg: Theme.primary
    property color track: Theme.surfaceHighest
    property real amp: 0
    property real phase: 0
    property bool dragging: false
    signal seek(real frac)

    implicitHeight: 28
    Behavior on amp { NumberAnimation { duration: Theme.ms(500) } }
    Binding on amp { value: root.waving && !root.dragging ? 3 : 0 }
    NumberAnimation on phase { from: 0; to: Math.PI * 2; duration: 1300; loops: Animation.Infinite; running: root.visible && root.waving && !Theme.still }
    onPhaseChanged: requestPaint()
    onValueChanged: requestPaint()
    onAmpChanged: requestPaint()
    onDraggingChanged: requestPaint()

    onPaint: {
        const g = getContext("2d"), W = width, H = height, m = H / 2, P = 6;
        const x1 = P + (W - P * 2) * Math.max(0, Math.min(1, value));
        g.reset(); g.lineCap = "round"; g.lineWidth = 4;
        g.strokeStyle = track; g.beginPath(); g.moveTo(Math.min(W - P, x1 + 11), m); g.lineTo(W - P, m); g.stroke();
        g.strokeStyle = fg; g.beginPath();
        for (let x = P; x <= x1 - 7; x += 1) {
            const y = m + Math.sin((x - P) / 44 * Math.PI * 2 - phase) * amp;
            x === P ? g.moveTo(x, y) : g.lineTo(x, y);
        }
        g.stroke();
        const th = dragging ? H - 2 : H * .72, tw = dragging ? 6 : 4;
        g.fillStyle = fg; g.beginPath(); g.roundedRect(x1 - tw / 2, m - th / 2, tw, th, tw / 2, tw / 2); g.fill();
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function at(x) { root.seek(Math.max(0, Math.min(1, (x - 6) / (root.width - 12)))); }
        onPressed: e => { root.dragging = true; at(e.x); }
        onPositionChanged: e => { if (pressed) at(e.x); }
        onReleased: root.dragging = false
    }
}

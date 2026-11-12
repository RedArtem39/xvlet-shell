import QtQuick
import qs.services

// The media's progress line, Resonance's (src/app.js drawBar): a 4 px wave
// -- 4.5 px up and down, 26 px long -- up to a 6 x 26 px thumb, a flat
// track after it. The wave fades in and out with the playing (and while
// dragged), it moves every frame. Press or drag it to seek: seek(frac).
Canvas {
    id: root
    property real value: 0
    property bool waving: true
    property color fg: Theme.primary
    property color track: Theme.surfaceHighest
    property real amp: 0
    property real t: 0                  // seconds (the wave's phase)
    property bool dragging: false
    signal seek(real frac)

    implicitHeight: 32
    renderStrategy: Canvas.Cooperative
    // the wave's height eases to 0 when paused or dragged (Resonance: * .08 a frame)
    FrameAnimation {
        running: root.visible && !Theme.still && (root.waving || root.amp > .001)
        onTriggered: {
            const target = root.waving && !root.dragging ? 1 : 0;
            root.amp += (target - root.amp) * Math.min(1, frameTime * 4.8);
            root.t += frameTime;
            root.requestPaint();
        }
    }
    onValueChanged: requestPaint()
    onDraggingChanged: requestPaint()
    onFgChanged: requestPaint()
    onTrackChanged: requestPaint()

    onPaint: {
        const g = getContext("2d"), w = width, h = height, mid = h / 2;
        const px = 4 + (w - 8) * Math.max(0, Math.min(1, value));
        g.reset();
        g.lineCap = "round"; g.lineJoin = "round"; g.lineWidth = 4;
        if (px + 8 < w - 4) { g.strokeStyle = track; g.beginPath(); g.moveTo(px + 8, mid); g.lineTo(w - 4, mid); g.stroke(); }
        g.strokeStyle = fg; g.beginPath();
        const A = 4.5 * amp, phase = t * 1000 / 260;
        for (let x = 4; x <= Math.max(4, px - 6); x += 2) {
            const y = mid + Math.sin((x / 26) * Math.PI * 2 - phase) * A;
            x === 4 ? g.moveTo(x, y) : g.lineTo(x, y);
        }
        g.stroke();
        g.fillStyle = fg; g.beginPath(); g.roundedRect(px - 3, mid - 13, 6, 26, 3, 3); g.fill();
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function at(x) { root.seek(Math.max(0, Math.min(1, (x - 4) / (root.width - 8)))); }
        onPressed: e => { root.dragging = true; at(e.x); }
        onPositionChanged: e => { if (pressed) at(e.x); }
        onReleased: root.dragging = false
    }
}

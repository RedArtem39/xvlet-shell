import QtQuick
import qs.services

// The ring round the big cover, Resonance's (src/app.js drawRing): a thin
// track all round, the progress from the top waving with 30 lobes (an
// integer: it closes on a full circle), tapering at its ends, a dot at its
// end. Flat while paused. Drag along the ring to seek: seek(frac).
Canvas {
    id: root
    property real value: 0
    property bool waving: true
    property color fg: Theme.primary
    property color track: Theme.surfaceHighest
    property real amp: 0
    property real t: 0
    property bool dragging: false
    signal seek(real frac)

    renderStrategy: Canvas.Cooperative
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
    onWidthChanged: requestPaint()
    onFgChanged: requestPaint()
    onTrackChanged: requestPaint()

    onPaint: {
        const size = Math.min(width, height);
        if (!size) return;
        const g = getContext("2d"), c = size / 2, R = size * .462, p = Math.max(0, Math.min(1, value));
        g.reset();
        g.lineCap = "round"; g.lineJoin = "round"; g.lineWidth = Math.max(3, size * .012);
        g.strokeStyle = track; g.beginPath(); g.arc(c, c, R, 0, Math.PI * 2); g.stroke();
        if (p <= .001) return;
        const A = size * .011 * amp, phase = t * 1000 / 380, a0 = -Math.PI / 2, span = Math.PI * 2 * p;
        g.strokeStyle = fg; g.beginPath();
        const steps = Math.max(8, Math.ceil(span * 60));
        for (let i = 0; i <= steps; i++) {
            const th = a0 + span * i / steps;
            const r = R + Math.sin((th - a0) * 30 - phase) * A * Math.min(1, i / 12, (steps - i) / 12 + .25);
            const x = c + Math.cos(th) * r, y = c + Math.sin(th) * r;
            i ? g.lineTo(x, y) : g.moveTo(x, y);
        }
        g.stroke();
        const te = a0 + span;
        g.fillStyle = fg; g.beginPath(); g.arc(c + Math.cos(te) * R, c + Math.sin(te) * R, g.lineWidth * 1.9, 0, Math.PI * 2); g.fill();
    }
    // seeking: only on the ring itself
    MouseArea {
        anchors.fill: parent
        function near(e) { const d = Math.hypot(e.x - width / 2, e.y - height / 2); return Math.abs(d - width * .462) < width * .07; }
        function at(e) { let a = Math.atan2(e.y - height / 2, e.x - width / 2) + Math.PI / 2; if (a < 0) a += Math.PI * 2; root.seek(a / (Math.PI * 2)); }
        hoverEnabled: true
        cursorShape: root.dragging || containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: e => { if (!near(e)) { e.accepted = false; return; } root.dragging = true; at(e); }
        onPositionChanged: e => { if (root.dragging) at(e); }
        onReleased: root.dragging = false
    }
}

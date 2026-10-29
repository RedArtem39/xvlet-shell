import QtQuick
import qs.services

// A gauge (the dashboard's, as the prototype's ring()): an open arc whose
// filled part waves, the value written in the middle
Canvas {
    id: root
    property real value: 0
    property string label: Math.round(value * 100) + "%"
    property color fg: Theme.primary
    property color track: Theme.surfaceHighest
    property color ink: Theme.fgSurface
    property real phase: 0
    property real shown: 0

    implicitWidth: 150
    implicitHeight: 150
    onShownChanged: requestPaint()
    onPhaseChanged: requestPaint()
    Behavior on shown { NumberAnimation { duration: Theme.ms(800); easing.type: Easing.OutQuint } }
    Binding on shown { value: root.value }
    NumberAnimation on phase { from: 0; to: Math.PI * 2; duration: 2200; loops: Animation.Infinite; running: root.visible && !Theme.still }

    onPaint: {
        const g = getContext("2d"), W = Math.min(width, height), c = W / 2, R = W * .37;
        g.reset();
        g.lineCap = "round"; g.lineWidth = W * .053;
        const a0 = Math.PI * .75, span = Math.PI * 1.5, a1 = a0 + span * Math.max(0, Math.min(1, shown));
        g.strokeStyle = track; g.beginPath(); g.arc(c, c, R, Math.min(a1 + .22, a0 + span), a0 + span); g.stroke();
        g.strokeStyle = fg; g.beginPath();
        let i = 0;
        for (let a = a0; a <= a1; a += .02, i++) {
            const r = R + Math.sin((a - a0) * 14 - phase * 3) * W * .017;
            const x = c + Math.cos(a) * r, y = c + Math.sin(a) * r;
            i ? g.lineTo(x, y) : g.moveTo(x, y);
        }
        g.stroke();
        g.fillStyle = ink;
        g.font = "700 " + Math.round(W * .18) + "px '" + Theme.font + "'";
        g.textAlign = "center"; g.textBaseline = "middle";
        g.fillText(label, c, c + 2);
    }
}

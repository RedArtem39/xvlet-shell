import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

// The bar's own visualizer (the prototype's #barviz, Serpantinum's
// Visualizer): the sound's spectrum growing from the bar's inner edge into
// the screen, under the windows -- bars with a rounded free end, or one
// filled wave; low frequencies in the middle, mirrored to both sides,
// fainter towards the ends. The levels: cava (CavaSource.qml); without it,
// drawn ones while something plays.
PanelWindow {
    id: root

    readonly property var bcfg: Config.data.bar
    readonly property string pos: bcfg.pos
    readonly property bool along: pos === "top" || pos === "bottom"
    readonly property real barThick: (bcfg.style === "islands" || bcfg.style === "solid") ? bcfg.height + 10 : bcfg.height
    readonly property real tall: bcfg.vizH || 70
    readonly property bool wave: bcfg.vizStyle === "wave"
    // (never into a corner: the frame's rounded ones, or a gap)
    readonly property bool framed: bcfg.style === "flush" && Config.data.theme.shellCorners
    readonly property real endGap: framed ? Theme.r : 12

    visible: bcfg.viz === true
    WlrLayershell.namespace: "xvlet-barviz"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors { top: pos === "top" || !along; bottom: pos === "bottom" || !along; left: pos === "left" || along; right: pos === "right" || along }
    margins {
        top: pos === "top" ? barThick : !along ? endGap : 0
        bottom: pos === "bottom" ? barThick : !along ? endGap : 0
        left: pos === "left" ? barThick : along ? endGap : 0
        right: pos === "right" ? barThick : along ? endGap : 0
    }
    implicitHeight: along ? tall : 0
    implicitWidth: along ? 0 : tall
    color: "transparent"
    mask: Region {}

    // ---- the levels ----
    readonly property int nsrc: 32
    Loader {
        id: src
        active: root.visible
        source: "CavaSource.qml"
        onStatusChanged: if (status === Loader.Error) console.warn("bar visualizer: no cava (Caelestia.Services) -- drawn levels instead")
    }
    readonly property bool live: src.status === Loader.Ready && src.item
    // the prototype's stand-in for cava: a kick on every beat, a bass line,
    // moving mids, hi-hats between the beats
    function drawnSource(t) {
        const out = [], beat = t * 2, ph = beat - Math.floor(beat), kick = Math.exp(-ph * 7), hat = Math.exp(-((ph + .5) % 1) * 18);
        for (let i = 0; i < nsrc; i++) {
            const f = i / (nsrc - 1);
            const v = kick * Math.exp(-f * 9) * .95
                + (.45 + .2 * Math.sin(t * 1.3 + i * .7)) * Math.exp(-Math.pow((f - .18) / .16, 2))
                + (.3 + .18 * Math.sin(t * 2.9 + i * 1.9) + .12 * Math.sin(t * 5.1 - i * 1.1)) * Math.exp(-Math.pow((f - .45) / .22, 2))
                + hat * .45 * Math.exp(-Math.pow((f - .82) / .1, 2)) + .05 * Math.abs(Math.sin(t * 9.7 + i * 2.3));
            out.push(Media.playing ? Math.max(0, Math.min(1, v)) : 0);
        }
        return out;
    }
    function edgeOf(i, n) { const e = Math.min(1, Math.sin(i / (n - 1) * Math.PI) * 2); return e * e * (3 - 2 * e); }

    property var cur: []
    property var map: []
    property int n: 0
    // anything to show: sound, or the bars still falling
    property bool moving: false

    Timer {
        interval: 33; repeat: true
        running: root.visible && !Theme.still && (Media.playing || root.moving || root.live)
        onTriggered: {
            const L = root.along ? cv.width : cv.height;
            const nn = root.wave ? 64 : Math.max(4, Math.min(128, Math.floor((L + 8) / 20)));
            if (nn !== root.n) {
                // where each drawn level reads the source: low in the middle, mirrored
                const half = (nn - 1) / 2, m = [];
                for (let i = 0; i < nn; i++) {
                    const norm = half > 0 ? Math.abs(i - half) / half : 0, p = Math.pow(norm, 1.25) * (root.nsrc - 1), i0 = Math.floor(p);
                    m.push([i0, Math.min(root.nsrc - 1, i0 + 1), p - i0]);
                }
                root.map = m; root.n = nn; root.cur = new Array(nn).fill(0);
            }
            const s = root.live ? (src.item.values || []) : root.drawnSource(Date.now() / 1000);
            let target = root.map.map(([a, b, f]) => {
                const raw = (s[a] || 0) + ((s[b] || 0) - (s[a] || 0)) * f;
                return raw < .03 ? 0 : Math.min(1, Math.pow((raw - .03) / .97, 1.15));
            });
            if (root.wave) target = target.map((x, i) => ((target[i - 1] !== undefined ? target[i - 1] : x) * .25 + x * .5 + (target[i + 1] !== undefined ? target[i + 1] : x) * .25) * root.edgeOf(i, nn));
            const rise = root.wave ? .25 : .6, fall = root.wave ? .12 : .22, c = root.cur.slice();
            let any = false;
            for (let i = 0; i < nn; i++) { c[i] += (target[i] - c[i]) * (target[i] > c[i] ? rise : fall); if (c[i] > .005) any = true; }
            const was = root.moving;
            root.cur = c;
            root.moving = any;
            // (silence, and the bars already down: nothing to draw again)
            if (any || was || !cv.painted) { cv.painted = true; cv.requestPaint(); }
        }
    }

    Canvas {
        id: cv
        anchors.fill: parent
        opacity: .85
        property color pri: Theme.primary
        property bool painted: false
        onPriChanged: requestPaint()
        onPaint: {
            const g = getContext("2d"), W = width, H = height;
            g.reset();
            const cur = root.cur, n = cur.length;
            if (!n) return;
            // local (along, across) onto the canvas, the base at the bar
            const L = root.along ? W : H, T = root.along ? H : W;
            if (root.pos === "bottom") g.setTransform(1, 0, 0, 1, 0, 0);
            else if (root.pos === "top") g.setTransform(1, 0, 0, -1, 0, H);
            else if (root.pos === "left") g.setTransform(0, 1, -1, 0, W, 0);
            else g.setTransform(0, 1, 1, 0, 0, 0);
            g.fillStyle = pri;
            if (!root.wave) {
                const sp = 4, th = (L - (n - 1) * sp) / n, maxL = T * .96, minL = 3;
                for (let i = 0; i < n; i++) {
                    const e = root.edgeOf(i, n), lv = cur[i] * e, len = Math.max(minL, lv * maxL), r = Math.min(th * .35, len / 2), x = i * (th + sp);
                    g.globalAlpha = (.3 + lv * .7) * e;
                    g.beginPath();
                    // a bar from the base (y = T), its free end rounded
                    g.moveTo(x, T); g.lineTo(x, T - len + r);
                    g.arcTo(x, T - len, x + r, T - len, r); g.lineTo(x + th - r, T - len);
                    g.arcTo(x + th, T - len, x + th, T - len + r, r); g.lineTo(x + th, T);
                    g.closePath(); g.fill();
                }
                g.globalAlpha = 1;
            } else {
                const maxL = T * .92, step = L / (n - 1), y = i => T - cur[i] * maxL;
                g.beginPath(); g.moveTo(0, T); g.lineTo(0, y(0)); g.lineTo(step / 2, (y(0) + y(1)) / 2);
                for (let i = 1; i < n - 1; i++) g.quadraticCurveTo(i * step, y(i), (i + .5) * step, (y(i) + y(i + 1)) / 2);
                g.lineTo(L, y(n - 1)); g.lineTo(L, T); g.closePath(); g.fill();
            }
        }
    }
}

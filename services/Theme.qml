pragma Singleton

import QtQuick
import Quickshell

// The look: Material 3 Expressive, as the prototype (design/shell in
// WynlandOS, kept there locally). Every colour is oklch(tone, chroma, hue);
// a scheme makes the four tonal palettes -- primary, secondary, tertiary,
// neutral -- from one seed hue, as M3's dynamic schemes do. Qt has no
// OKLCH: oklch() below turns it into sRGB.
Singleton {
    id: root

    // the seed (later: the wallpaper's own colours, saved themes)
    property real seedHue: 285
    property real seedChroma: 0.12
    property string scheme: "tonal"
    property bool dark: true

    readonly property var schemes: ({
        tonal:      h => [[h, .12], [h, .045], [h + 60, .09], [h, .03]],
        vibrant:    h => [[h, Math.max(.17, root.seedChroma)], [h + 15, .075], [h + 55, .12], [h, .04]],
        expressive: h => [[h - 120, .14], [h + 15, .08], [h + 90, .12], [h + 15, .03]],
        neutral:    h => [[h, .045], [h, .02], [h + 60, .035], [h, .01]],
        mono:       h => [[h, 0], [h, 0], [h, 0], [h, 0]],
        fruit:      h => [[h - 50, .14], [h - 50, .1], [h, .12], [h, .03]],
    })
    readonly property var pal: {
        const p = (schemes[scheme] || schemes.tonal)(seedHue);
        const m = x => ((x % 360) + 360) % 360;
        return { hp: m(p[0][0]), cp: p[0][1], hs: m(p[1][0]), cs: p[1][1], ht: m(p[2][0]), ct: p[2][1], hn: m(p[3][0]), cn: p[3][1] };
    }

    // ---- the roles (shell.css :root[data-theme]) ----
    readonly property color primary:              dark ? oklch(80, pal.cp, pal.hp) : oklch(45, pal.cp, pal.hp)
    readonly property color onPrimary:            dark ? oklch(25, pal.cp * .9, pal.hp) : oklch(100, 0, 0)
    readonly property color primaryContainer:     dark ? oklch(36, pal.cp * .9, pal.hp) : oklch(89, pal.cp * .6, pal.hp)
    readonly property color onPrimaryContainer:   dark ? oklch(91, pal.cp * .5, pal.hp) : oklch(24, pal.cp * .8, pal.hp)
    readonly property color secondaryContainer:   dark ? oklch(34, pal.cs, pal.hs) : oklch(90, pal.cs * .75, pal.hs)
    readonly property color onSecondaryContainer: dark ? oklch(90, pal.cs * .7, pal.hs) : oklch(26, pal.cs, pal.hs)
    readonly property color tertiary:             dark ? oklch(80, pal.ct, pal.ht) : oklch(48, pal.ct, pal.ht)
    readonly property color tertiaryContainer:    dark ? oklch(36, pal.ct * .9, pal.ht) : oklch(90, pal.ct * .65, pal.ht)
    readonly property color onTertiaryContainer:  dark ? oklch(91, pal.ct * .5, pal.ht) : oklch(26, pal.ct * .8, pal.ht)
    readonly property color surface:              dark ? oklch(16.5, pal.cn * .8, pal.hn) : oklch(97.5, pal.cn * .45, pal.hn)
    readonly property color surfaceLow:           dark ? oklch(19.5, pal.cn * .9, pal.hn) : oklch(95.5, pal.cn * .55, pal.hn)
    readonly property color surfaceMid:           dark ? oklch(22.5, pal.cn, pal.hn) : oklch(93.5, pal.cn * .7, pal.hn)
    readonly property color surfaceHigh:          dark ? oklch(26, pal.cn * 1.05, pal.hn) : oklch(91.5, pal.cn * .75, pal.hn)
    readonly property color surfaceHighest:       dark ? oklch(30, pal.cn * 1.1, pal.hn) : oklch(89, pal.cn * .8, pal.hn)
    readonly property color onSurface:            dark ? oklch(93, pal.cn * .35, pal.hn) : oklch(22, pal.cn * .5, pal.hn)
    readonly property color onSurfaceVar:         dark ? oklch(78, pal.cn * .8, pal.hn) : oklch(42, pal.cn * .85, pal.hn)
    readonly property color outline:              dark ? oklch(45, pal.cn * .9, pal.hn) : oklch(70, pal.cn * .7, pal.hn)
    readonly property color glass:                dark ? oklch(19, pal.cn * .9, pal.hn, .78) : oklch(96, pal.cn * .5, pal.hn, .8)
    readonly property color error:                dark ? oklch(72, .16, 25) : oklch(52, .18, 25)
    readonly property color shadow:               dark ? oklch(4, .05, pal.hn, .7) : oklch(30, .05, pal.hn, .35)

    // ---- shape, size, motion ----
    property real radiusScale: 1
    readonly property real r: 32 * radiusScale       // --R
    readonly property real rm: 24 * radiusScale      // --Rm
    readonly property real rs: 16 * radiusScale      // --Rs
    readonly property string font: "Roboto Flex"
    readonly property string icons: "Material Symbols Rounded"
    // cubic-bezier(.34, 1.56, .64, 1) and friends, for Easing.BezierSpline
    readonly property var spring: [.34, 1.56, .64, 1, 1, 1]
    readonly property var springSoft: [.3, 1.3, .6, 1, 1, 1]
    readonly property var smooth: [.2, 0, 0, 1, 1, 1]

    // oklch(L%, C, H[, alpha]) -> sRGB (out of gamut: clamped)
    function oklch(L, C, H, a) {
        const h = H * Math.PI / 180, l0 = L / 100, A = C * Math.cos(h), B = C * Math.sin(h);
        const l = Math.pow(l0 + .3963377774 * A + .2158037573 * B, 3);
        const m = Math.pow(l0 - .1055613458 * A - .0638541728 * B, 3);
        const s = Math.pow(l0 - .0894841775 * A - 1.291485548 * B, 3);
        const g = x => { x = Math.max(0, Math.min(1, x)); return x <= .0031308 ? 12.92 * x : 1.055 * Math.pow(x, 1 / 2.4) - .055; };
        return Qt.rgba(g(4.0767416621 * l - 3.3077115913 * m + .2309699292 * s),
                       g(-1.2684380046 * l + 2.6097574011 * m - .3413193965 * s),
                       g(-.0041960863 * l - .7034186147 * m + 1.707614701 * s), a === undefined ? 1 : a);
    }

    // M3 Expressive's shapes (core.js shape()): a polygon of 120 points, so
    // two shapes morph point by point. Points in 0..1 of the box.
    function shape(lobes, depth, rot, sharp) {
        const N = 120, pts = [];
        for (let i = 0; i < N; i++) {
            const t = i / N * Math.PI * 2;
            let w = Math.cos(lobes * (t + (rot || 0)));
            if (sharp && sharp !== 1) w = Math.sign(w) * Math.pow(Math.abs(w), sharp);
            const rr = (50 - depth + depth * w) / 100;
            pts.push(Qt.point(.5 + rr * Math.cos(t), .5 + rr * Math.sin(t)));
        }
        return pts;
    }
    readonly property var shCircle: shape(1, 0)
    readonly property var shCookie9: shape(9, 3.2)
    readonly property var shCookie12: shape(12, 2.4)
    readonly property var shCookie4: shape(4, 5, Math.PI / 4)
    readonly property var shFlower: shape(8, 7, 0, .6)
    readonly property var shSunny: shape(12, 4, 0, .5)
}

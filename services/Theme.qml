pragma Singleton

import QtQuick
import Quickshell
import qs.services
import "../lib/mcu.js" as Mcu

// The look: Material 3 Expressive. The colours are Material You's own:
// Google's material-color-utilities (lib/mcu.js) -- the wallpaper's colours
// scored as Android picks them (Score), a dynamic scheme from the seed
// (TonalSpot, Vibrant, Expressive... the 2025 spec, M3 Expressive's), every
// role from it. The seed: one of the wallpaper's (up to four), a chosen
// hue, or a saved theme. The old OKLCH formulas stay as the fallback (and
// for the few places that want a hue: pal, now.h). Qt has no OKLCH:
// oklch() turns it into sRGB.
Singleton {
    id: root

    readonly property var th: Config.data.theme

    // ---- the wallpaper's seeds ----
    ColorQuantizer {
        id: quant
        source: Config.data.wall.path ? "file://" + Config.data.wall.path : ""
        depth: 6
        rescaleSize: 192
    }
    // the prototype's wallSeeds(): a hue histogram (72 bins of 5 degrees)
    // weighted by chroma^1.5, smoothed, its peaks at least 35 degrees apart.
    // (Median cut gives buckets of about equal population: each of the 64
    // colours stands for as many pixels.)
    readonly property var wallSeeds: {
        const cs = quant.colors || [], pop = new Map();
        // (median cut: each of its colours stands for about as many pixels --
        // the population Score wants)
        for (const c of cs) {
            const a = Mcu.MCU.argbFromRgb(Math.round(c.r * 255), Math.round(c.g * 255), Math.round(c.b * 255));
            pop.set(a, (pop.get(a) || 0) + 1);
        }
        // (no fallback colour: a wallpaper without colours of its own -- black
        // and white -- gets a grey theme, not Material's purple out of nothing)
        let picks = [];
        try { picks = pop.size ? Mcu.MCU.Score.score(pop, { desired: 4, fallbackColorARGB: 0x00000000, filter: true }).filter(a => a !== 0) : []; } catch (e) { picks = []; }
        const out = picks.map(a => { const o = toOklch(((a >> 16) & 255) / 255, ((a >> 8) & 255) / 255, (a & 255) / 255); return { argb: a, h: Math.round(o[2]), c: Math.max(.03, Math.min(.2, o[1])) }; });
        return out.length ? out : [{ argb: 0xff808080, h: 0, c: 0, mono: true }];
    }

    // what is in force: a saved theme, the wallpaper's seed, or a chosen hue
    readonly property var now: {
        if (th.src === "saved" && th.saved && th.saved[th.active]) return th.saved[th.active];
        const seed = th.src === "custom" ? { h: th.custom, c: .14 } : (wallSeeds[th.seed] || wallSeeds[0]);
        // a colourless wallpaper: grey whatever the scheme (any other would
        // make up a hue)
        return { h: seed.h, c: seed.c, argb: seed.argb, scheme: seed.mono ? "mono" : th.scheme, mode: th.mode };
    }
    readonly property bool dark: now.mode !== "light"

    readonly property var schemes: ({
        tonal:      { n: "Тональная",     f: (h, c) => [[h, .12], [h, .045], [h + 60, .09], [h, .03]] },
        vibrant:    { n: "Яркая",         f: (h, c) => [[h, Math.max(.17, c)], [h + 15, .075], [h + 55, .12], [h, .04]] },
        expressive: { n: "Выразительная", f: (h, c) => [[h - 120, .14], [h + 15, .08], [h + 90, .12], [h + 15, .03]] },
        fidelity:   { n: "Верная",        f: (h, c) => [[h, c], [h, c * .35], [h + 55, c * .65], [h, Math.min(.04, c * .22)]] },
        neutral:    { n: "Нейтральная",   f: (h, c) => [[h, .045], [h, .02], [h + 60, .035], [h, .01]] },
        mono:       { n: "Монохром",      f: (h, c) => [[h, 0], [h, 0], [h, 0], [h, 0]] },
        fruit:      { n: "Фруктовая",     f: (h, c) => [[h - 50, .14], [h - 50, .1], [h, .12], [h, .03]] },
        rainbow:    { n: "Радуга",        f: (h, c) => [[h, .14], [h, .05], [h + 60, .09], [h, 0]] }
    })
    function paletteOf(t) {
        const p = (schemes[t.scheme] || schemes.tonal).f(t.h, t.c), m = x => ((x % 360) + 360) % 360;
        return { hp: m(p[0][0]), cp: p[0][1], hs: m(p[1][0]), cs: p[1][1], ht: m(p[2][0]), ct: p[2][1], hn: m(p[3][0]), cn: p[3][1] };
    }
    readonly property var pal: paletteOf(now)

    // ---- Material You's scheme (lib/mcu.js) ----
    // a theme {h, c, argb?, scheme, mode} -> its DynamicScheme (null: the
    // library failed -- the OKLCH formulas below then)
    function argbOf(col) { return Mcu.MCU.argbFromRgb(Math.round(col.r * 255), Math.round(col.g * 255), Math.round(col.b * 255)); }
    function schemeOf(t) {
        try {
            const M = Mcu.MCU;
            const kind = ({ tonal: M.SchemeTonalSpot, vibrant: M.SchemeVibrant, expressive: M.SchemeExpressive, fidelity: M.SchemeFidelity,
                            neutral: M.SchemeNeutral, mono: M.SchemeMonochrome, fruit: M.SchemeFruitSalad, rainbow: M.SchemeRainbow })[t.scheme] || M.SchemeTonalSpot;
            // (a hue with no colour of its own -- chosen, saved: as a vivid mid tone)
            const seed = t.argb !== undefined ? t.argb : argbOf(oklch(65, Math.max(.1, t.c || .14), t.h));
            return new kind(M.Hct.fromInt(seed), (t.mode || th.mode) !== "light", 0, "2025");
        } catch (e) { console.warn("theme: material-color-utilities failed: " + e); return null; }
    }
    readonly property var dyn: schemeOf(now)
    function argbColor(a, al) { return Qt.rgba(((a >> 16) & 255) / 255, ((a >> 8) & 255) / 255, (a & 255) / 255, al === undefined ? 1 : al); }
    // a role of the scheme, or the fallback
    function role(name, fb) { return dyn ? argbColor(dyn[name]) : fb; }

    // ---- apart from the wallpaper ----
    // Material You's surfaces are its neutral palette at fixed tones: over a
    // wallpaper of the same hue and about the same lightness the panels sink
    // into it. How light the wallpaper is (its colours' mean OKLab L), and
    // how far the surfaces are moved away from it: a dark theme over a dark
    // wallpaper lifts them some tones (a light one over a light wallpaper
    // lowers them) -- same hue and chroma, from the same palette -- and the
    // panels get a faint edge (Theme.edge).
    readonly property real wallL: {
        const cs = quant.colors || [];
        if (!cs.length) return .5;
        let s = 0;
        for (const c of cs) s += toOklch(c.r, c.g, c.b)[0];
        return s / cs.length;
    }
    readonly property real lift: th.src === "custom" && !Config.data.wall.path ? 0
                                 : dark ? Math.max(0, Math.min(1, (.45 - wallL) / .3)) : Math.max(0, Math.min(1, (wallL - .68) / .22))
    function surf(name, fb) {
        if (!dyn) return fb;
        try {
            const M = Mcu.MCU, t = M.Hct.fromInt(dyn[name]).tone;
            return argbColor(dyn.neutralPalette.tone(Math.max(0, Math.min(100, dark ? t + 9 * lift : t - 6 * lift))));
        } catch (e) { return argbColor(dyn[name]); }
    }
    readonly property color edge: alpha(dyn ? argbColor(dyn.outlineVariant) : outline, .18 + .37 * lift)

    // ---- the roles (shell.css :root[data-theme]) ----
    readonly property color primary:              role("primary", dark ? oklch(80, pal.cp, pal.hp) : oklch(45, pal.cp, pal.hp))
    readonly property color fgPrimary:            role("onPrimary", dark ? oklch(25, pal.cp * .9, pal.hp) : oklch(100, 0, 0))
    readonly property color primaryContainer:     role("primaryContainer", dark ? oklch(36, pal.cp * .9, pal.hp) : oklch(89, pal.cp * .6, pal.hp))
    readonly property color fgPrimaryContainer:   role("onPrimaryContainer", dark ? oklch(91, pal.cp * .5, pal.hp) : oklch(24, pal.cp * .8, pal.hp))
    readonly property color secondaryContainer:   role("secondaryContainer", dark ? oklch(34, pal.cs, pal.hs) : oklch(90, pal.cs * .75, pal.hs))
    readonly property color fgSecondaryContainer: role("onSecondaryContainer", dark ? oklch(90, pal.cs * .7, pal.hs) : oklch(26, pal.cs, pal.hs))
    readonly property color tertiary:             role("tertiary", dark ? oklch(80, pal.ct, pal.ht) : oklch(48, pal.ct, pal.ht))
    readonly property color tertiaryContainer:    role("tertiaryContainer", dark ? oklch(36, pal.ct * .9, pal.ht) : oklch(90, pal.ct * .65, pal.ht))
    readonly property color fgTertiaryContainer:  role("onTertiaryContainer", dark ? oklch(91, pal.ct * .5, pal.ht) : oklch(26, pal.ct * .8, pal.ht))
    readonly property color surface:              surf("surface", dark ? oklch(16.5, pal.cn * .8, pal.hn) : oklch(97.5, pal.cn * .45, pal.hn))
    readonly property color surfaceLow:           surf("surfaceContainerLow", dark ? oklch(19.5, pal.cn * .9, pal.hn) : oklch(95.5, pal.cn * .55, pal.hn))
    readonly property color surfaceMid:           surf("surfaceContainer", dark ? oklch(22.5, pal.cn, pal.hn) : oklch(93.5, pal.cn * .7, pal.hn))
    readonly property color surfaceHigh:          surf("surfaceContainerHigh", dark ? oklch(26, pal.cn * 1.05, pal.hn) : oklch(91.5, pal.cn * .75, pal.hn))
    readonly property color surfaceHighest:       surf("surfaceContainerHighest", dark ? oklch(30, pal.cn * 1.1, pal.hn) : oklch(89, pal.cn * .8, pal.hn))
    readonly property color fgSurface:            role("onSurface", dark ? oklch(93, pal.cn * .35, pal.hn) : oklch(22, pal.cn * .5, pal.hn))
    readonly property color fgSurfaceVar:         role("onSurfaceVariant", dark ? oklch(78, pal.cn * .8, pal.hn) : oklch(42, pal.cn * .85, pal.hn))
    readonly property color outline:              role("outlineVariant", dark ? oklch(45, pal.cn * .9, pal.hn) : oklch(70, pal.cn * .7, pal.hn))
    readonly property color glass:                dyn ? alpha(surfaceLow, (dark ? .82 : .84) + .1 * lift) : (dark ? oklch(19, pal.cn * .9, pal.hn, .82) : oklch(96, pal.cn * .5, pal.hn, .84))
    readonly property color scrim:                dark ? oklch(8, pal.cn * .7, pal.hn, .55) : oklch(30, pal.cn * .7, pal.hn, .35)
    readonly property color error:                role("error", dark ? oklch(72, .16, 25) : oklch(52, .18, 25))
    readonly property color errorContainer:       role("errorContainer", dark ? oklch(38, .12, 25) : oklch(90, .06, 25))
    readonly property color shadow:               dark ? oklch(4, .05, pal.hn, .7) : oklch(30, .05, pal.hn, .35)
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t); }

    // ---- shape, size, motion ----
    readonly property real radiusScale: th.radius || 1
    readonly property real r: 32 * radiusScale       // --R
    readonly property real rm: 24 * radiusScale      // --Rm
    readonly property real rs: 16 * radiusScale      // --Rs
    readonly property string font: th.font || "Roboto Flex"
    readonly property string icons: "Material Symbols Rounded"
    readonly property bool still: th.motion === "off"
    // cubic-bezier(.34, 1.56, .64, 1) and friends, for Easing.BezierSpline
    readonly property var spring: th.motion === "smooth" ? smooth : [.34, 1.56, .64, 1, 1, 1]
    readonly property var springSoft: th.motion === "smooth" ? smooth : [.3, 1.3, .6, 1, 1, 1]
    readonly property var smooth: [.2, 0, 0, 1, 1, 1]
    function ms(t) { return still ? 0 : t; }

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
    // sRGB (0..1) -> [L 0..1, C, H degrees]
    function toOklch(r, g, b) {
        const lin = c => c <= .04045 ? c / 12.92 : Math.pow((c + .055) / 1.055, 2.4);
        r = lin(r); g = lin(g); b = lin(b);
        const l = Math.cbrt(.4122214708 * r + .5363325363 * g + .0514459929 * b), m = Math.cbrt(.2119034982 * r + .6806995451 * g + .1073969566 * b), s = Math.cbrt(.0883024619 * r + .2817188376 * g + .6299787005 * b);
        const L = .2104542553 * l + .793617785 * m - .0040720468 * s, A = 1.9779984951 * l - 2.428592205 * m + .4505937099 * s, B = .0259040371 * l + .7827717662 * m - .808675766 * s;
        return [L, Math.hypot(A, B), (Math.atan2(B, A) * 180 / Math.PI + 360) % 360];
    }

    // M3 Expressive's shapes: a polygon of 120 points (two shapes morph
    // point by point). Points in 0..1 of the box.
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
    readonly property var shPlaying: shape(9, 3)      // the playing cover: Resonance's cookie (9 lobes, .06)
    readonly property var shCookie12: shape(12, 2.4)
    readonly property var shCookie4: shape(4, 5, Math.PI / 4)
    readonly property var shFlower: shape(8, 7, 0, .6)
    readonly property var shSunny: shape(12, 4, 0, .5)
}

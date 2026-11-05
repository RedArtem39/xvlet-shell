// The SMIL the login scenes use (tools/bake_scene.py writes each scene's
// Scene.qml against this): values over keyTimes with linear, spline,
// discrete or paced steps, repeating from a begin offset; transforms as
// 2D matrices; numbers interpolated inside path strings.
.pragma library

// where in its cycle (0..1) an animation is at time t (seconds)
function phase(t, a) {
    if (a.rc) {                                  // a finite repeatCount: held at its ends
        if (t < a.b) return 0;
        if (t - a.b >= a.d * a.rc) return 1;
    }
    const x = ((t - a.b) % a.d + a.d) % a.d;
    return x / a.d;
}

// a cubic-bezier easing (keySplines x1 y1 x2 y2) at x
function bez(s, x) {
    if (x <= 0 || x >= 1) return x;
    let lo = 0, hi = 1, u = x;
    for (let i = 0; i < 18; i++) {
        const cx = 3 * s[0] * u * (1 - u) * (1 - u) + 3 * s[2] * u * u * (1 - u) + u * u * u;
        if (cx < x) lo = u; else hi = u;
        u = (lo + hi) / 2;
    }
    return 3 * s[1] * u * (1 - u) * (1 - u) + 3 * s[3] * u * u * (1 - u) + u * u * u;
}

// the value (an array of numbers) of animation a at time t
function at(t, a) {
    const v = a.v, n = v.length;
    if (n === 1) return v[0];
    const p = phase(t, a);
    const kt = a.kt;
    let i, f;
    if (a.m === "discrete") {
        if (kt) { i = 0; while (i + 1 < n && kt[i + 1] <= p) i++; }
        else i = Math.min(n - 1, Math.floor(p * n));
        return v[i];
    }
    if (kt) {
        i = 0;
        while (i + 2 < n && kt[i + 1] <= p) i++;
        const span = kt[i + 1] - kt[i];
        f = span > 0 ? (p - kt[i]) / span : 0;
    } else {
        const s = p * (n - 1);
        i = Math.min(n - 2, Math.floor(s));
        f = s - i;
    }
    if (a.m === "spline" && a.ks && a.ks[i]) f = bez(a.ks[i], f);
    const x = v[i], y = v[i + 1], out = [];
    for (let k = 0; k < x.length; k++) out.push(x[k] + ((y[k] !== undefined ? y[k] : x[k]) - x[k]) * f);
    return out;
}

// 2D affine [a b c d e f] (SVG's matrix order) products
function mul(m, n) {
    return [m[0] * n[0] + m[2] * n[1], m[1] * n[0] + m[3] * n[1],
            m[0] * n[2] + m[2] * n[3], m[1] * n[2] + m[3] * n[3],
            m[0] * n[4] + m[2] * n[5] + m[4], m[1] * n[4] + m[3] * n[5] + m[5]];
}
function one(type, v) {
    switch (type) {
    case "translate": return [1, 0, 0, 1, v[0], v.length > 1 ? v[1] : 0];
    case "scale": { const sy = v.length > 1 ? v[1] : v[0]; return [v[0], 0, 0, sy, 0, 0]; }
    case "rotate": {
        const r = v[0] * Math.PI / 180, c = Math.cos(r), s = Math.sin(r), cx = v[1] || 0, cy = v[2] || 0;
        return [c, s, -s, c, cx - c * cx + s * cy, cy - s * cx - c * cy];
    }
    case "skewX": return [1, 0, Math.tan(v[0] * Math.PI / 180), 1, 0, 0];
    case "skewY": return [1, Math.tan(v[0] * Math.PI / 180), 0, 1, 0, 0];
    }
    return [1, 0, 0, 1, 0, 0];
}

// the element's transform at t: its own (base), replaced by a non-additive
// animateTransform, the additive ones multiplied on
function tf(t, base, anims) {
    let m = base;
    for (let k = 0; k < anims.length; k++) {
        const a = anims[k], x = one(a.y, at(t, a));
        m = a.add ? mul(m, x) : x;
    }
    return Qt.matrix4x4(m[0], m[2], 0, m[4], m[1], m[3], 0, m[5], 0, 0, 1, 0, 0, 0, 0, 1);
}
function mat(m) { return Qt.matrix4x4(m[0], m[2], 0, m[4], m[1], m[3], 0, m[5], 0, 0, 1, 0, 0, 0, 0, 1); }

// a number (opacity, a radius...) at t
function num(t, a) { return at(t, a)[0]; }

// a path string at t: the numbers of its keyframes interpolated, the
// commands of the first kept (the frames must share their structure)
function path(t, a) {
    const v = at(t, a), tpl = a.tpl;
    let k = 0;
    return tpl.replace(/@/g, () => +v[k++].toFixed(3));
}

// ellipse / circle / rect outlines as paths
function ellipse(cx, cy, rx, ry) {
    return "M" + (cx - rx) + " " + cy + " A" + rx + " " + ry + " 0 1 0 " + (cx + rx) + " " + cy +
           " A" + rx + " " + ry + " 0 1 0 " + (cx - rx) + " " + cy + " Z";
}
function rect(x, y, w, h) { return "M" + x + " " + y + " h" + w + " v" + h + " h" + (-w) + " Z"; }

# xvlet's mark: a Chinese dragon curled into a ring -- its body goes round
# a few times, wandering in and out, over and under itself (a gap where it
# crosses), its pearl in the hole. One colour and its cuts.
#
#   python tools/dragon.py assets/brand/xvlet.svg components/XvletMark.qml
#
# The body is drawn in pieces, each over the ones before it: a piece's
# sides get a stroke of the cut colour first, so where it lies over an
# earlier one there is a gap -- the over/under of a knot.
import math, sys

S = 512
C = S / 2
TURNS = 1.8                       # how many times round the ring
N = 520                           # samples along the body
PIECES = 14

def centre(u):
    # u 0..1 from the tail to the neck: round the ring, the radius
    # wandering (two waves out of step: no two loops alike)
    t = u * TURNS * 2 * math.pi + .4
    r = 150 + 46 * math.sin(2.35 * t + .7) + 22 * math.sin(4.2 * t + 2.1) - 18 * (1 - u)
    return (C + r * math.cos(t), C + r * math.sin(t))

def tangent(u, h=1e-4):
    (x0, y0), (x1, y1) = centre(max(0, u - h)), centre(min(1, u + h))
    d = math.hypot(x1 - x0, y1 - y0) or 1
    return ((x1 - x0) / d, (y1 - y0) / d)

def width(u):
    # a thin tail swelling to the shoulders, narrowing a little at the neck
    return 4 + 44 * math.sin(min(1, u * 1.25) * math.pi * .5) ** 1.4 - 8 * max(0, u - .88) / .12

us = [i / (N - 1) for i in range(N)]

def side(i0, i1, sign):
    pts = []
    for u in us[i0:i1 + 1]:
        (x, y), (tx, ty) = centre(u), tangent(u)
        nx, ny = -ty * sign, tx * sign
        w = width(u) / 2
        pts.append((x + nx * w, y + ny * w))
    return pts

def smooth(pts, move=True):
    out = ["M%.1f %.1f" % pts[0]] if move else []
    n = len(pts)
    for i in range(n - 1):
        p0 = pts[i - 1] if i > 0 else pts[i]
        p1, p2 = pts[i], pts[i + 1]
        p3 = pts[i + 2] if i + 2 < n else p2
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        out.append("C%.1f %.1f %.1f %.1f %.1f %.1f" % (c1 + c2 + p2))
    return " ".join(out)

pieces = []
step = (N - 1) / PIECES
for k in range(PIECES):
    i0, i1 = round(k * step), round((k + 1) * step)
    left, right = side(i0, i1, 1), side(i0, i1, -1)
    fill = smooth(left) + " L%.1f %.1f " % right[-1] + smooth(right[::-1], False) + " Z"
    edges = smooth(left) + " " + smooth(right)
    # fins on the outer side of the ring; scales cut across the back
    fins, scales = [], []
    for j in range(i0, i1, 9):
        u = us[j]
        if u < .1 or u > .93: continue
        (x, y), (tx, ty) = centre(u), tangent(u)
        ox, oy = x - C, y - C
        d = math.hypot(ox, oy) or 1
        sgn = 1 if (-ty * ox + tx * oy) > 0 else -1          # the normal that points out
        nx, ny = -ty * sgn, tx * sgn
        w = width(u) / 2
        h = 9 + 15 * u
        bx, by = x + nx * w * .92, y + ny * w * .92
        fins.append("M%.1f %.1f Q%.1f %.1f %.1f %.1f Q%.1f %.1f %.1f %.1f Z" % (
            bx - tx * h * .6, by - ty * h * .6,
            bx + nx * h * .7 - tx * h * .2, by + ny * h * .7 - ty * h * .2,
            bx + nx * h - tx * h, by + ny * h - ty * h,
            bx + nx * h * .4 + tx * h * .1, by + ny * h * .4 + ty * h * .1,
            bx + tx * h * .4, by + ty * h * .4))
    for j in range(i0 + 4, i1, 8):
        u = us[j]
        if u < .06 or u > .95: continue
        (x, y), (tx, ty) = centre(u), tangent(u)
        nx, ny = -ty, tx
        w = width(u) / 2 * .62
        s = width(u) * .2
        scales.append("M%.1f %.1f Q%.1f %.1f %.1f %.1f" % (
            x + nx * w - tx * s * .3, y + ny * w - ty * s * .3,
            x + tx * s, y + ty * s,
            x - nx * w - tx * s * .3, y - ny * w - ty * s * .3))
    pieces.append({"fill": fill, "edges": edges, "fins": " ".join(fins), "scales": " ".join(scales)})

# the head: drawn facing +x, neck at the origin; turned along the body's end
head = ("M-4 -22 C10 -30 30 -30 46 -24 C58 -20 70 -20 82 -14 C90 -10 92 -4 86 -1 "
        "C78 2 66 0 58 2 L84 10 C88 12 86 18 80 18 C66 18 52 16 40 18 C28 20 14 26 -4 22 Z")
mane = ("M-2 -20 C-14 -34 -24 -30 -30 -40 C-20 -38 -12 -40 -4 -30 Z "
        "M-4 20 C-16 32 -26 26 -34 34 C-22 34 -14 32 -6 24 Z "
        "M6 -26 C-4 -46 -18 -48 -22 -60 C-8 -54 4 -50 14 -30 Z")
horns = ("M18 -26 C14 -44 6 -54 -6 -62 C8 -60 20 -48 26 -28 Z "
         "M30 -26 C30 -40 26 -48 20 -56 C30 -52 36 -42 38 -26 Z")
eye = "M40 -14 C44 -20 54 -20 58 -14 C54 -10 44 -10 40 -14 Z"
nostril = "M74 -10 a3 3 0 1 0 0.1 0 Z"
teeth = "M60 3 L64 9 L66 4 L70 10 L72 5 L76 11 L78 7 Z"
whisk = ("M80 -6 C100 -14 120 -6 124 10 C128 26 112 34 104 24 C112 26 118 18 112 10 C104 0 92 0 80 -2 Z "
         "M70 14 C80 30 74 46 60 52 C48 56 40 46 46 40 C46 46 54 48 60 42 C68 34 66 24 62 16 Z")
hx, hy = centre(1)
tx, ty = tangent(1)
ix, iy = C - hx, C - hy
d = math.hypot(ix, iy); ix, iy = ix / d, iy / d
ang = math.degrees(math.atan2(ty * .7 + iy * .3, tx * .7 + ix * .3))   # (a little towards the pearl)
HS = 1.35

# the pearl in the hole, with its flames
pr = 24
pearl = "M%.1f %.1f a%d %d 0 1 0 0.1 0 Z" % (C, C - pr, pr, pr)
gleam = "M%.1f %.1f a7 7 0 1 0 0.1 0 Z" % (C - 9, C - 13)
flames = []
for k in range(7):
    a = k / 7 * 2 * math.pi + .3
    ux, uy = math.cos(a), math.sin(a)
    vx, vy = -uy, ux
    b0 = (C + ux * (pr + 2) - vx * 7, C + uy * (pr + 2) - vy * 7)
    b1 = (C + ux * (pr + 2) + vx * 7, C + uy * (pr + 2) + vy * 7)
    tip = (C + ux * (pr + 19) + vx * 10, C + uy * (pr + 19) + vy * 10)
    flames.append("M%.1f %.1f Q%.1f %.1f %.1f %.1f Q%.1f %.1f %.1f %.1f Z" % (
        b0 + (C + ux * (pr + 13) - vx * 2, C + uy * (pr + 13) - vy * 2) + tip +
        (C + ux * (pr + 9) + vx * 10, C + uy * (pr + 9) + vy * 10) + b1))

GAP = 7     # the cut round a piece where it crosses another

# ---- SVG ----
ink, cut = "var(--ink, #1b1d24)", "var(--cut, #ffffff)"
parts = []
for k, p in enumerate(pieces):
    parts.append(f'''    <g class="piece">
      <path d="{p["fins"]}" style="fill:{ink}"/>
      <path d="{p["edges"]}" style="fill:none;stroke:{cut};stroke-width:{GAP}" stroke-linecap="round"/>
      <path d="{p["fill"]}" style="fill:{ink}"/>
      <path d="{p["scales"]}" style="fill:none;stroke:{cut};stroke-width:3" stroke-linecap="round"/>
    </g>''')
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {S} {S}" width="{S}" height="{S}">
  <title>xvlet</title>
  <!-- xvlet's mark (tools/dragon.py): a Chinese dragon curled into a ring
       round its pearl. One colour (the CSS variable ink) and its cuts (cut).
       Parts: #pearl, #body (its .piece groups, tail first), #head. -->
  <g id="pearl">
    <path d="{pearl} {" ".join(flames)}" style="fill:{ink}"/>
    <path d="{gleam}" style="fill:{cut}" opacity=".85"/>
  </g>
  <g id="body">
{chr(10).join(parts)}
  </g>
  <g id="head" transform="translate({hx:.1f} {hy:.1f}) rotate({ang:.1f}) scale({HS})">
    <path d="{mane} {horns} {head} {whisk}" style="fill:{ink};stroke:{cut};stroke-width:{GAP / HS:.1f};paint-order:stroke"/>
    <path d="{eye} {nostril} {teeth}" style="fill:{cut}"/>
  </g>
</svg>
'''
open(sys.argv[1], "w", encoding="utf-8", newline="\n").write(svg)

# ---- QML (components/XvletMark.qml): Qt's SVG has no CSS variables; as
# shapes it takes the theme's colours, and its parts move ----
if len(sys.argv) > 2:
    def fp(d, colour="root.ink"):
        return f'            ShapePath {{ strokeWidth: -1; fillColor: {colour}; PathSvg {{ path: "{d}" }} }}\n'
    def sp(d, w):
        return (f'            ShapePath {{ strokeWidth: {w}; strokeColor: root.cut; fillColor: "transparent"; '
                f'capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin; PathSvg {{ path: "{d}" }} }}\n')
    body = "".join(fp(p["fins"]) + sp(p["edges"], GAP) + fp(p["fill"]) + sp(p["scales"], 3) for p in pieces)
    qml = f'''import QtQuick
import QtQuick.Shapes

// xvlet's mark (generated by tools/dragon.py, as assets/brand/xvlet.svg): a
// Chinese dragon curled into a ring round its pearl, over and under
// itself. One colour (ink) and its cuts (cut: what it sits on). The parts
// move: the pearl turns, the body breathes, the head nods.
Item {{
    id: root
    property color ink: "#1b1d24"
    property color cut: "#ffffff"
    property real pearlTurn: 0          // degrees
    property real headTurn: 0           // degrees, about the neck
    property real bodyScale: 1
    implicitWidth: 64
    implicitHeight: 64

    Item {{
        width: {S}; height: {S}
        transform: Scale {{ xScale: root.width / {S}; yScale: root.height / {S} }}
        Shape {{
            id: pearl
            width: {S}; height: {S}
            preferredRendererType: Shape.CurveRenderer
            transform: Rotation {{ origin.x: {C}; origin.y: {C}; angle: root.pearlTurn }}
{fp(pearl + " " + " ".join(flames))}{fp(gleam, "root.cut")}        }}
        Shape {{
            id: body
            width: {S}; height: {S}
            preferredRendererType: Shape.CurveRenderer
            transform: Scale {{ origin.x: {C}; origin.y: {C}; xScale: root.bodyScale; yScale: root.bodyScale }}
{body}        }}
        Shape {{
            id: head
            x: {hx:.1f}; y: {hy:.1f}
            preferredRendererType: Shape.CurveRenderer
            transform: [ Scale {{ xScale: {HS}; yScale: {HS} }}, Rotation {{ angle: {ang:.1f} + root.headTurn }} ]
            ShapePath {{ strokeWidth: {GAP / HS:.1f}; strokeColor: root.cut; fillColor: root.cut; PathSvg {{ path: "{mane} {horns} {head} {whisk}" }} }}
{fp(mane + " " + horns + " " + head + " " + whisk)}{fp(eye + " " + nostril + " " + teeth, "root.cut")}        }}
    }}
}}
'''
    open(sys.argv[2], "w", encoding="utf-8", newline="\n").write(qml)
print("ok")

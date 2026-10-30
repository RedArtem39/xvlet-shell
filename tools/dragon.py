# xvlet's mark: a Chinese dragon curled into a ring round its pearl --
# once round and a little more, its head coming over its own tail; a crest
# along its back, two clawed legs, the head upright (horns up, whiskers
# streaming back). One colour and its cuts.
#
#   python tools/dragon.py assets/brand/xvlet.svg components/XvletMark.qml
#
# The body is drawn in pieces, each over the ones before it: a piece's
# sides get a stroke of the cut colour first, so where it lies over an
# earlier one there is a gap -- the over/under of a knot.
import math, sys

S = 512
C = S / 2
N = 480                           # samples along the body
PIECES = 10
T1 = math.radians(272)            # the neck: at the top, going right (clockwise)
T0 = T1 - math.radians(410)       # the tail: a little past one turn before it

def centre(u):
    # u 0..1 from the tail to the neck; the radius wanders a little (two
    # waves out of step) and the tail end lies inside the ring
    t = T0 + (T1 - T0) * u
    r = 148 + 22 * math.sin(2 * t + .6) + 12 * math.sin(3.3 * t + 1.9) - 30 * (1 - u) ** 3
    return (C + r * math.cos(t), C + r * math.sin(t))

def tangent(u, h=1e-4):
    (x0, y0), (x1, y1) = centre(max(0, u - h)), centre(min(1, u + h))
    d = math.hypot(x1 - x0, y1 - y0) or 1
    return ((x1 - x0) / d, (y1 - y0) / d)

def outward(u):
    # the side normal pointing away from the pearl
    (x, y), (tx, ty) = centre(u), tangent(u)
    nx, ny = -ty, tx
    if nx * (x - C) + ny * (y - C) < 0: nx, ny = -nx, -ny
    return nx, ny

def width(u):
    # a thin tail swelling to the shoulders, a little narrower at the neck
    return 3 + 44 * math.sin(min(1, u * 1.35) * math.pi * .5) ** 1.3 - 6 * max(0, u - .9) / .1

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

def place(path_pts, ox, oy, ax, ay):
    # local (x along a, y along the normal of a) -> the drawing
    bx, by = -ay, ax
    return [(ox + x * ax + y * bx, oy + x * ay + y * by) for x, y in path_pts]

pieces = []
step = (N - 1) / PIECES
for k in range(PIECES):
    i0, i1 = round(k * step), round((k + 1) * step)
    left, right = side(i0, i1, 1), side(i0, i1, -1)
    # (the fill reaches back over the last piece's end: no seam across)
    fl, fr = side(max(0, i0 - 4), i1, 1), side(max(0, i0 - 4), i1, -1)
    fill = smooth(fl) + " L%.1f %.1f " % fr[-1] + smooth(fr[::-1], False) + " Z"
    edges = smooth(left) + " " + smooth(right)
    # the crest: sharp fins on the back (the outer side), leaning to the tail
    crest = []
    for j in range(i0, i1, 11):
        u = us[j]
        if u < .12 or u > .9: continue
        (x, y), (tx, ty) = centre(u), tangent(u)
        nx, ny = outward(u)
        w = width(u) / 2 * .9
        h = 9 + 16 * u
        bx, by = x + nx * w, y + ny * w
        crest.append("M%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % (
            bx + tx * h * .45, by + ty * h * .45,
            bx + nx * h - tx * h * .55, by + ny * h - ty * h * .55,
            bx - tx * h * .4, by - ty * h * .4))
    # the belly: one smooth line along the inner side
    inner = []
    for u in us[i0:i1 + 1]:
        (x, y) = centre(u)
        nx, ny = outward(u)
        inner.append((x - nx * width(u) * .22, y - ny * width(u) * .22))
    belly = smooth(inner) if us[i0] > .05 else ""
    pieces.append({"fill": fill, "edges": edges, "crest": " ".join(crest), "belly": belly})

# two legs, on the outer side, each with three claws (strokes)
legs = []
for u in (.42, .76):
    (x, y), (tx, ty) = centre(u), tangent(u)
    nx, ny = outward(u)
    w = width(u) / 2
    ox, oy = x + nx * w * .5, y + ny * w * .5
    # local: x back along the body, y outwards
    ax, ay = -tx, -ty
    leg = place([(0, 0), (-6, 26), (10, 42)], ox, oy, ax, ay)
    foot = leg[-1]
    claws = []
    for cx_, cy_ in ((26, 44), (22, 54), (12, 58)):
        p = place([(10, 42), (cx_, cy_)], ox, oy, ax, ay)
        claws.append("M%.1f %.1f L%.1f %.1f" % (p[0] + p[1]))
    legs.append({"leg": "M%.1f %.1f Q%.1f %.1f %.1f %.1f" % (leg[0] + leg[1] + leg[2]), "claws": " ".join(claws)})

# the head: facing +x, the neck at the origin, horns up (-y)
skull = ("M-8 -24 C6 -34 26 -38 44 -32 C60 -27 78 -26 96 -24 C106 -24 114 -30 118 -26 "
         "C121 -22 117 -14 110 -11 C98 -7 80 -6 64 -2 L54 2 "
         "C68 8 86 12 98 16 C104 18 106 24 100 27 C84 30 62 28 44 28 C26 28 8 30 -8 26 Z")
fang = "M86 -8 L90 7 L95 -9 Z M66 -4 L68 6 L72 -5 Z"
eye = "M38 -20 C42 -27 54 -27 58 -20 C54 -15 42 -15 38 -20 Z"
nostril = "M108 -19 a3 3 0 1 0 0.1 0 Z"
mane = ("M-6 -22 C-20 -30 -34 -26 -46 -38 C-34 -40 -22 -36 -8 -30 Z "
        "M-8 -6 C-24 -8 -36 -2 -50 -8 C-38 0 -24 2 -10 4 Z "
        "M-6 14 C-20 18 -30 28 -44 26 C-32 34 -18 30 -6 24 Z")
# (strokes) antlers, branching up and back; whiskers streaming back
antlers = "M20 -34 C14 -54 6 -66 -10 -78 M10 -58 C20 -64 26 -72 26 -82 M34 -34 C34 -50 30 -60 22 -70"
whiskers = ("M112 -18 C100 -40 80 -44 62 -50 C42 -56 24 -50 4 -62 "
            "M100 18 C86 34 66 30 46 40 C28 49 10 42 -12 50")

hx, hy = centre(1)
tx, ty = tangent(1)
ang = math.degrees(math.atan2(ty, tx)) - 18     # (lifted: it looks ahead, not down)
flip = math.cos(math.radians(ang)) < 0         # going left: mirrored, so the horns stay up
HS = 1.3

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
legs_fill = " ".join(l["leg"] for l in legs)
claws = " ".join(l["claws"] for l in legs)
head_tf = f"translate({hx:.1f} {hy:.1f}) rotate({ang:.1f}) scale({HS} {-HS if flip else HS})"

# ---- SVG ----
ink, cut = "var(--ink, #1b1d24)", "var(--cut, #ffffff)"
parts = []
for k, p in enumerate(pieces):
    parts.append(f'''    <g class="piece">
      <path d="{p["crest"]}" style="fill:{ink}"/>
      <path d="{p["edges"]}" style="fill:none;stroke:{cut};stroke-width:{GAP}" stroke-linecap="round"/>
      <path d="{p["fill"]}" style="fill:{ink}"/>
      {f'<path d="{p["belly"]}" style="fill:none;stroke:{cut};stroke-width:2.5" stroke-linecap="round"/>' if p["belly"] else ""}
    </g>''')
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {S} {S}" width="{S}" height="{S}">
  <title>xvlet</title>
  <!-- xvlet's mark (tools/dragon.py): a Chinese dragon curled into a ring
       round its pearl. One colour (the CSS variable ink) and its cuts (cut).
       Parts: #pearl, #legs, #body (its .piece groups, tail first), #head. -->
  <g id="pearl">
    <path d="{pearl} {" ".join(flames)}" style="fill:{ink}"/>
    <path d="{gleam}" style="fill:{cut}" opacity=".85"/>
  </g>
  <g id="legs" style="fill:none;stroke:{ink};stroke-linecap:round;stroke-linejoin:round">
    <path d="{legs_fill}" style="stroke-width:12"/>
    <path d="{claws}" style="stroke-width:5"/>
  </g>
  <g id="body">
{chr(10).join(parts)}
  </g>
  <g id="head" transform="{head_tf}">
    <path d="{mane} {skull}" style="fill:{ink};stroke:{cut};stroke-width:{GAP / HS:.1f};paint-order:stroke"/>
    <path d="{antlers} {whiskers}" style="fill:none;stroke:{ink};stroke-width:4.5;stroke-linecap:round"/>
    <path d="{eye} {nostril} {fang}" style="fill:{cut}"/>
  </g>
</svg>
'''
open(sys.argv[1], "w", encoding="utf-8", newline="\n").write(svg)

# ---- QML (components/XvletMark.qml): Qt's SVG has no CSS variables; as
# shapes it takes the theme's colours, and its parts move ----
if len(sys.argv) > 2:
    def fp(d, colour="root.ink"):
        return f'            ShapePath {{ strokeWidth: -1; fillColor: {colour}; PathSvg {{ path: "{d}" }} }}\n'
    def sp(d, w, colour="root.cut"):
        return (f'            ShapePath {{ strokeWidth: {w}; strokeColor: {colour}; fillColor: "transparent"; '
                f'capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin; PathSvg {{ path: "{d}" }} }}\n')
    body = "".join(fp(p["crest"]) + sp(p["edges"], GAP) + fp(p["fill"]) + (sp(p["belly"], 2.5) if p["belly"] else "") for p in pieces)
    qml = f'''import QtQuick
import QtQuick.Shapes

// xvlet's mark (generated by tools/dragon.py, as assets/brand/xvlet.svg): a
// Chinese dragon curled into a ring round its pearl, its head over its
// tail. One colour (ink) and its cuts (cut: what it sits on). The parts
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
{sp(legs_fill, 12, "root.ink")}{sp(claws, 5, "root.ink")}{body}        }}
        Shape {{
            id: head
            x: {hx:.1f}; y: {hy:.1f}
            preferredRendererType: Shape.CurveRenderer
            transform: [ Scale {{ xScale: {HS}; yScale: {-HS if flip else HS} }}, Rotation {{ angle: {ang:.1f} + root.headTurn }} ]
            ShapePath {{ strokeWidth: {GAP / HS:.1f}; strokeColor: root.cut; fillColor: root.cut; PathSvg {{ path: "{mane} {skull}" }} }}
{fp(mane + " " + skull)}{sp(antlers + " " + whiskers, 4.5, "root.ink")}{fp(eye + " " + nostril + " " + fang, "root.cut")}        }}
    }}
}}
'''
    open(sys.argv[2], "w", encoding="utf-8", newline="\n").write(qml)
print("ok", "flip" if flip else "")

# xvlet's mark: a Chinese dragon coiled into a spiral round a pearl.
# One colour (currentColor), details cut out as negative space, every part
# in its own group (body, fins, belly, head, whiskers, pearl) to animate.
import math, sys

S = 512                     # the viewBox
C = S / 2                   # the spiral's centre
TH0, TH1 = 1.3 * math.pi, 4.25 * math.pi   # the tail (inside) to the neck (outside)
B = 11.0                    # r = A + B * theta: coils 69 apart
A = 168 - B * TH1

def centre(t):
    r = A + B * t
    return (C + r * math.cos(t), C + r * math.sin(t))

def tangent(t, h=1e-3):
    (x0, y0), (x1, y1) = centre(t - h), centre(t + h)
    d = math.hypot(x1 - x0, y1 - y0)
    return ((x1 - x0) / d, (y1 - y0) / d)

def width(t):
    # thin at the tail, swelling to the neck, a little narrower at the throat
    u = (t - TH0) / (TH1 - TH0)
    return 5 + 46 * math.sin(min(1, u * 1.05) * math.pi * .5) ** 1.3 - 4 * max(0, u - .92) / .08

N = 220
ts = [TH0 + (TH1 - TH0) * i / (N - 1) for i in range(N)]

def side(sign):
    pts = []
    for t in ts:
        (x, y), (tx, ty) = centre(t), tangent(t)
        nx, ny = -ty * sign, tx * sign
        w = width(t) / 2
        pts.append((x + nx * w, y + ny * w))
    return pts

def smooth(pts, closed=False):
    # Catmull-Rom through the points, as cubic Beziers
    out = ["M%.1f %.1f" % pts[0]]
    n = len(pts)
    for i in range(n - 1):
        p0 = pts[i - 1] if i > 0 else pts[i]
        p1, p2 = pts[i], pts[i + 1]
        p3 = pts[i + 2] if i + 2 < n else p2
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        out.append("C%.1f %.1f %.1f %.1f %.1f %.1f" % (c1 + c2 + p2))
    return " ".join(out)

outer, inner = side(-1), side(1)
# the body: one edge out, the round tail tip, the other edge back
tx, ty = centre(TH0)
body = smooth(outer) + " L" + smooth(inner[::-1])[1:] + " Z"

# the belly: a cut line running along the inner side, in plates
belly = smooth([(x + (centre(t)[0] - x) * .35, y + (centre(t)[1] - y) * .35) for (x, y), t in zip(inner, ts)][10:-6])

# the fins: flames along the outer edge, growing towards the neck
fins = []
for k in range(26):
    u = .12 + .82 * k / 25
    t = TH0 + (TH1 - TH0) * u
    (x, y), (tx_, ty_) = centre(t), tangent(t)
    nx, ny = ty_, -tx_          # outwards
    w = width(t) / 2
    h = 6 + 13 * u
    bx, by = x + nx * w, y + ny * w
    # a curved flame leaning back along the body
    p0 = (bx - tx_ * h * .55, by - ty_ * h * .55)
    p1 = (bx + nx * h - tx_ * h * .9, by + ny * h - ty_ * h * .9)
    p2 = (bx + tx_ * h * .35, by + ty_ * h * .35)
    fins.append("M%.1f %.1f Q%.1f %.1f %.1f %.1f Q%.1f %.1f %.1f %.1f Z" % (
        p0 + ((bx + nx * h * .6 - tx_ * h * .2), (by + ny * h * .6 - ty_ * h * .2)) + p1 +
        ((bx + nx * h * .45 + tx_ * h * .2), (by + ny * h * .45 + ty_ * h * .2)) + p2))

# the scales: chevrons cut across the back
scales = []
for k in range(34):
    u = .08 + .86 * k / 33
    t = TH0 + (TH1 - TH0) * u
    (x, y), (tx_, ty_) = centre(t), tangent(t)
    nx, ny = ty_, -tx_
    w = width(t) / 2 * .55
    s = width(t) * .22
    scales.append("M%.1f %.1f Q%.1f %.1f %.1f %.1f" % (
        x + nx * w - tx_ * s * .2, y + ny * w - ty_ * s * .2,
        x + tx_ * s, y + ty_ * s,
        x - nx * w * .2 - tx_ * s * .2, y - ny * w * .2 - ty_ * s * .2))

# the head, drawn facing +x with its neck at the origin, then turned along
# the spiral's end: a long snout, the jaw open towards the pearl, horns,
# a mane of flames, the eye
hx, hy = centre(TH1)
tx_, ty_ = tangent(TH1)
# (along the coil, a little in: it chases the pearl round)
ix, iy = C - hx, C - hy
d = math.hypot(ix, iy); ix, iy = ix / d, iy / d
ang = math.degrees(math.atan2(ty_ * .85 + iy * .15, tx_ * .85 + ix * .15))
head = (
    "M-4 -22 C10 -30 30 -30 46 -24 C58 -20 70 -20 82 -14 C90 -10 92 -4 86 -1 "   # brow, snout top
    "C78 2 66 0 58 2 L84 10 C88 12 86 18 80 18 C66 18 52 16 40 18 "              # upper jaw, open mouth, lower jaw
    "C28 20 14 26 -4 22 Z"
)
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

# the pearl in the middle, with its flames
pr = 26
pearl = "M%.1f %.1f a%d %d 0 1 0 0.1 0 Z" % (C, C - pr, pr, pr)
gleam = "M%.1f %.1f a8 8 0 1 0 0.1 0 Z" % (C - 10, C - 14)
flames = []
for k in range(7):
    a = k / 7 * 2 * math.pi + .3
    ux, uy = math.cos(a), math.sin(a)
    vx, vy = -uy, ux
    b0 = (C + ux * (pr + 2) - vx * 7, C + uy * (pr + 2) - vy * 7)
    b1 = (C + ux * (pr + 2) + vx * 7, C + uy * (pr + 2) + vy * 7)
    tip = (C + ux * (pr + 20) + vx * 10, C + uy * (pr + 20) + vy * 10)
    flames.append("M%.1f %.1f Q%.1f %.1f %.1f %.1f Q%.1f %.1f %.1f %.1f Z" % (
        b0 + (C + ux * (pr + 14) - vx * 2, C + uy * (pr + 14) - vy * 2) + tip +
        (C + ux * (pr + 10) + vx * 10, C + uy * (pr + 10) + vy * 10) + b1))

cut = 'fill="none" style="stroke:var(--cut, #fff)" stroke-linecap="round" stroke-linejoin="round"'
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="20 54 530 530" width="{S}" height="{S}">
  <title>xvlet</title>
  <!-- xvlet's mark: a Chinese dragon coiled round its pearl. One colour
       (currentColor, the CSS variable ink); the cuts in the CSS variable cut. Parts:
       #pearl, #body (#fins, #scales, #belly), #head (#horns, #mane,
       #whiskers, #eye), each its own group to move. -->
  <g id="xvlet" fill="currentColor" style="color:var(--ink, #1b1d24)">
    <g id="pearl">
      <path d="{pearl}"/>
      <g id="flames">{"".join(f'<path d="{f}"/>' for f in flames)}</g>
      <path d="{gleam}" style="fill:var(--cut, #fff)" opacity=".85"/>
    </g>
    <g id="body">
      <g id="fins">{"".join(f'<path d="{f}"/>' for f in fins)}</g>
      <path id="trunk" d="{body}"/>
      <g id="scales" {cut} stroke-width="3.2">{"".join(f'<path d="{s_}"/>' for s_ in scales)}</g>
      <path id="belly" d="{belly}" {cut} stroke-width="2.6" stroke-dasharray="7 6"/>
    </g>
    <g id="head" transform="translate({hx:.1f} {hy:.1f}) rotate({ang:.1f}) scale(1.5)">
      <path id="mane" d="{mane}"/>
      <path id="horns" d="{horns}"/>
      <path id="skull" d="{head}"/>
      <path id="whiskers" d="{whisk}"/>
      <path id="eye" d="{eye}" style="fill:var(--cut, #fff)"/>
      <path d="{nostril}" style="fill:var(--cut, #fff)"/>
      <path d="{teeth}" style="fill:var(--cut, #fff)"/>
    </g>
  </g>
</svg>
'''
open(sys.argv[1], "w", encoding="utf-8").write(svg)
print("ok", len(svg))

# the same mark for QML (components/XvletMark.qml): Qt's SVG knows no CSS
# variables, and as shapes it takes the theme's colours and moves part by part
if len(sys.argv) > 2:
    J = lambda l: " ".join(l)
    def fillp(name, d):
        return f'''        ShapePath {{ objectName: "{name}"; strokeWidth: -1; fillColor: root.ink; PathSvg {{ path: "{d}" }} }}\n'''
    def cutp(d, w, dash=False):
        extra = "; strokeStyle: ShapePath.DashLine; dashPattern: [" + str(round(7 / w, 2)) + ", " + str(round(6 / w, 2)) + "]" if dash else ""
        return f'''        ShapePath {{ strokeWidth: {w}; strokeColor: root.cut; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin{extra}; PathSvg {{ path: "{d}" }} }}\n'''
    def cutf(d):
        return f'''        ShapePath {{ strokeWidth: -1; fillColor: root.cut; PathSvg {{ path: "{d}" }} }}\n'''
    qml = f'''import QtQuick
import QtQuick.Shapes

// xvlet's mark (generated by tools/dragon.py, as assets/brand/xvlet.svg): a
// Chinese dragon coiled round its pearl. One colour (ink) and its cuts
// (cut); the parts move: pearl (spin), body (breathe), head (nod).
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
        // the drawing's own box: 530 square from (20, 54)
        width: 530; height: 530
        transform: [ Translate {{ x: -20; y: -54 }}, Scale {{ xScale: root.width / 530; yScale: root.height / 530 }} ]
        Item {{
            id: pearl
            x: 0; y: 0; width: {S}; height: {S}
            transform: Rotation {{ origin.x: {C}; origin.y: {C}; angle: root.pearlTurn }}
            Shape {{
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
{fillp("pearl", pearl + " " + J(flames))}{cutf(gleam)}            }}
        }}
        Shape {{
            id: body
            width: {S}; height: {S}
            preferredRendererType: Shape.CurveRenderer
            transform: Scale {{ origin.x: {C}; origin.y: {C}; xScale: root.bodyScale; yScale: root.bodyScale }}
{fillp("fins", J(fins))}{fillp("trunk", body)}{cutp(J(scales), 3.2)}{cutp(belly, 2.6, True)}        }}
        Item {{
            id: head
            x: {hx:.1f}; y: {hy:.1f}
            transform: [ Scale {{ xScale: 1.5; yScale: 1.5 }}, Rotation {{ angle: {ang:.1f} + root.headTurn }} ]
            Shape {{
                preferredRendererType: Shape.CurveRenderer
{fillp("head", J([mane, horns, head, whisk]))}{cutf(J([eye, nostril, teeth]))}            }}
        }}
    }}
}}
'''
    open(sys.argv[2], "w", encoding="utf-8").write(qml)
    print("qml ok")

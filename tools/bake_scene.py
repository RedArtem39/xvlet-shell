#!/usr/bin/env python3
# A login scene (wynlogin/scenes/<id>/): an animated SVG baked for
# QtQuick -- the system has no QtSvg, and Qt plays no SMIL.
#
# The SVG's nesting is kept: what never moves is baked into PNG sprites
# (2x), each in the coordinate system of the group it sits in; every
# element that moves, or holds something that moves, becomes an Item in
# the generated Scene.qml with its transform and opacity bound to the
# scene's clock through wynlogin/anim.js, and its SMIL as numbers in
# data.js. Shapes whose outline moves (a path's d, a circle's r, an
# ellipse's rx/ry, a rect's size) are QtQuick Shapes; animateMotion is a
# PathInterpolator. Identical sprites are baked once.
#
#   python3 tools/bake_scene.py SCENE.svg [ID]   (needs cairosvg and Pillow)
import copy, hashlib, io, json, os, re, sys
import xml.etree.ElementTree as ET
import cairosvg
from PIL import Image, ImageFilter

NS, XL = 'http://www.w3.org/2000/svg', 'http://www.w3.org/1999/xlink'
ET.register_namespace('', NS)
ET.register_namespace('xlink', XL)
q = lambda t: '{%s}%s' % (NS, t)
K = 2                                                        # pixels per unit
ANIM = {q('animate'), q('animateTransform'), q('animateMotion'), q('set'), q('animateColor')}
NONRENDER = {q(t) for t in ('defs', 'title', 'desc', 'metadata', 'style', 'symbol', 'linearGradient', 'radialGradient',
                            'clipPath', 'mask', 'pattern', 'filter', 'marker')}
INHERIT = ['fill', 'fill-opacity', 'fill-rule', 'stroke', 'stroke-width', 'stroke-opacity', 'stroke-linecap',
           'stroke-linejoin', 'stroke-dasharray', 'stroke-miterlimit', 'font-family', 'font-size', 'font-weight',
           'font-style', 'text-anchor', 'letter-spacing', 'visibility', 'color', 'clip-rule']
SHAPES = {q('path'): ['d'], q('circle'): ['cx', 'cy', 'r'], q('ellipse'): ['cx', 'cy', 'rx', 'ry'],
          q('rect'): ['x', 'y', 'width', 'height']}

src = sys.argv[1]
sid = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(os.path.basename(src))[0].replace('-v2', '')
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'wynlogin', 'scenes', sid)
os.makedirs(OUT, exist_ok=True)
for f in os.listdir(OUT):
    os.remove(os.path.join(OUT, f))

root = ET.parse(src).getroot()
vb = [float(v) for v in re.split(r'[\s,]+', root.get('viewBox').strip())]
W, H = vb[2], vb[3]

# style="a:b" -> attributes
for e in root.iter():
    st = e.get('style')
    if st:
        for kv in st.split(';'):
            if ':' in kv:
                k, v = [x.strip() for x in kv.split(':', 1)]
                e.attrib.setdefault(k, v)
        del e.attrib['style']

is_anim = lambda e: e.tag in ANIM
# (a group cut by a clip-path or a mask stays still: its parts moving in
# QtQuick would leave the cut -- a blade's glint went walking off it)
has_anim = lambda e: not (e.get('clip-path') or e.get('mask')) and any(is_anim(x) for x in e.iter())

def strip(e):
    for c in list(e):
        if is_anim(c): e.remove(c)
        else: strip(c)
    return e

# everything referenced from a sprite: the defs, symbols, gradients... and
# any element a <use> points at
href = lambda e: e.get('{%s}href' % XL) or e.get('href')
used = {href(u)[1:] for u in root.iter(q('use')) if href(u) and href(u).startswith('#')}
DEFS = ET.Element(q('defs'))
for e in root.iter():
    if e is root: continue
    if e.tag == q('defs'):
        for c in e: DEFS.append(strip(copy.deepcopy(c)))
    elif e.tag in NONRENDER and e.tag not in (q('title'), q('desc'), q('metadata'), q('style')) and e.get('id'):
        DEFS.append(strip(copy.deepcopy(e)))
    elif e.get('id') in used:
        DEFS.append(strip(copy.deepcopy(e)))

def render_svg(parts, x, y, w, h, scale, inh):
    r = ET.Element(q('svg'), {'viewBox': '%g %g %g %g' % (x, y, w, h), 'width': '%g' % w, 'height': '%g' % h})
    r.append(copy.deepcopy(DEFS))
    g = ET.SubElement(r, q('g'), inh)
    for p in parts: g.append(strip(copy.deepcopy(p)))
    png = cairosvg.svg2png(bytestring=ET.tostring(r), output_width=max(1, round(w * scale)), output_height=max(1, round(h * scale)))
    return Image.open(io.BytesIO(png)).convert('RGBA')

SPRITES = {}
def sprite(parts, inh):
    """parts (in their parent's coordinates) as one PNG: (file, x, y, w, h) or None"""
    key = hashlib.sha1((json.dumps(inh, sort_keys=True) + ''.join(ET.tostring(strip(copy.deepcopy(p)), encoding='unicode') for p in parts)).encode()).hexdigest()
    if key in SPRITES: return SPRITES[key]
    R = 1.6 * max(W, H)
    lo = render_svg(parts, -R, -R, 2 * R, 2 * R, 0.25, inh)     # where it is, roughly
    box = lo.getbbox()
    if not box:
        SPRITES[key] = None; return None
    x0, y0 = box[0] / 0.25 - R - 2, box[1] / 0.25 - R - 2
    x1, y1 = box[2] / 0.25 - R + 2, box[3] / 0.25 - R + 2
    img = render_svg(parts, x0, y0, x1 - x0, y1 - y0, K, inh)
    b = img.getbbox()
    if not b:
        SPRITES[key] = None; return None
    img = img.crop(b)
    name = 's%03d.png' % len([v for v in SPRITES.values() if v])
    img.save(os.path.join(OUT, name), optimize=True)
    SPRITES[key] = (name, x0 + b[0] / K, y0 + b[1] / K, (b[2] - b[0]) / K, (b[3] - b[1]) / K)
    return SPRITES[key]

# ---- SVG transforms
def parse_tf(s):
    m = [1, 0, 0, 1, 0, 0]
    for name, args in re.findall(r'(\w+)\s*\(([^)]*)\)', s or ''):
        v = [float(x) for x in re.split(r'[\s,]+', args.strip()) if x]
        if name == 'matrix': n = v
        elif name == 'translate': n = [1, 0, 0, 1, v[0], v[1] if len(v) > 1 else 0]
        elif name == 'scale': n = [v[0], 0, 0, v[1] if len(v) > 1 else v[0], 0, 0]
        elif name == 'rotate':
            import math
            a = math.radians(v[0]); c, s_ = math.cos(a), math.sin(a); cx, cy = (v[1], v[2]) if len(v) > 2 else (0, 0)
            n = [c, s_, -s_, c, cx - c * cx + s_ * cy, cy - s_ * cx - c * cy]
        elif name == 'skewX':
            import math; n = [1, 0, math.tan(math.radians(v[0])), 1, 0, 0]
        elif name == 'skewY':
            import math; n = [1, math.tan(math.radians(v[0])), 0, 1, 0, 0]
        else: continue
        m = [m[0] * n[0] + m[2] * n[1], m[1] * n[0] + m[3] * n[1], m[0] * n[2] + m[2] * n[3],
             m[1] * n[2] + m[3] * n[3], m[0] * n[4] + m[2] * n[5] + m[4], m[1] * n[4] + m[3] * n[5] + m[5]]
    return m

# ---- SMIL
def secs(v, d=0.0):
    if not v: return d
    v = v.strip().split(';')[0].strip()
    m = re.match(r'^(-?[\d.]+)(ms|s|min|h)?$', v)
    if not m: return d
    x = float(m.group(1))
    return x / 1000 if m.group(2) == 'ms' else x * 60 if m.group(2) == 'min' else x * 3600 if m.group(2) == 'h' else x

nums = lambda s: [float(x) for x in re.findall(r'-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?', s)]

def anim(a, base=None):
    """an SMIL element as anim.js's object (None: not playable here)"""
    d = secs(a.get('dur'))
    if d <= 0: return None
    vals = a.get('values')
    if vals is None:
        fr, to, by = a.get('from'), a.get('to'), a.get('by')
        if fr is not None and to is not None: vals = fr + ';' + to
        elif to is not None and base is not None: vals = base + ';' + to
        elif by is not None and base is not None: vals = base + ';' + ' '.join(str(x + y) for x, y in zip(nums(base), nums(by)))
        else: return None
    o = {'d': d, 'b': secs(a.get('begin'))}
    o['v'] = [nums(v) for v in vals.strip().strip(';').split(';')]
    if a.get('keyTimes'): o['kt'] = [float(x) for x in a.get('keyTimes').strip().strip(';').split(';')]
    if a.get('keySplines'): o['ks'] = [nums(s) for s in a.get('keySplines').strip().strip(';').split(';')]
    mode = a.get('calcMode') or ('paced' if a.tag == q('animateMotion') else 'linear')
    o['m'] = 'linear' if mode == 'paced' else mode
    rc = a.get('repeatCount')
    if rc and rc != 'indefinite' and not a.get('repeatDur'):
        try: o['rc'] = float(rc)
        except ValueError: pass
    if a.tag == q('animateTransform'):
        o['y'] = a.get('type', 'translate')
        o['add'] = a.get('additive') == 'sum'
    return o

# ---- colours (for Shapes)
NAMED = {'white': '#ffffff', 'black': '#000000', 'none': None, 'transparent': None, 'red': '#ff0000'}
GRAD = {e.get('id'): e for e in root.iter() if e.tag in (q('linearGradient'), q('radialGradient')) and e.get('id')}

def stops(g):
    while g is not None and not g.findall(q('stop')) and href(g):
        g = GRAD.get(href(g)[1:])
    out = []
    for s in (g.findall(q('stop')) if g is not None else []):
        st = dict(s.attrib)
        for kv in (s.get('style') or '').split(';'):
            if ':' in kv: k, v = kv.split(':', 1); st.setdefault(k.strip(), v.strip())
        off = s.get('offset', '0'); off = float(off[:-1]) / 100 if off.endswith('%') else float(off)
        out.append((off, color(st.get('stop-color', '#000'), float(st.get('stop-opacity', '1')))))
    return out

def color(c, op=1.0):
    if c is None: return None
    c = c.strip()
    c = NAMED.get(c, c)
    if c is None: return None
    m = re.match(r'^#([0-9a-fA-F]{3})$', c)
    if m: c = '#' + ''.join(ch * 2 for ch in m.group(1))
    m = re.match(r'^rgba?\(([^)]*)\)$', c)
    if m:
        v = nums(m.group(1)); c = '#%02x%02x%02x' % tuple(int(x) for x in v[:3])
        if len(v) > 3: op *= v[3]
    if not re.match(r'^#[0-9a-fA-F]{6}$', c): return None
    return '#%02x%s' % (max(0, min(255, round(op * 255))), c[1:])

# ---- the generated QML
L = []
DATA = []                                                    # anim.js objects, by index
def emit(s, ind): L.append('    ' * ind + s)
def dref(o):
    DATA.append(o); return 'D.a[%d]' % (len(DATA) - 1)
def presentation(e, inh):
    out = dict(inh)
    for k in INHERIT:
        if e.get(k) is not None: out[k] = e.get(k)
    return out

def flush(run, inh, ind):
    if not run: return
    s = sprite(run, inh)
    if s:
        emit('Image { source: "%s"; x: %g; y: %g; width: %g; height: %g; smooth: true }' % s, ind)

def walk(e, inh, ind):
    run = []
    for c in e:
        if is_anim(c) or c.tag in NONRENDER or not isinstance(c.tag, str): continue
        if has_anim(c):
            flush(run, inh, ind); run = []
            node(c, inh, ind)
        else:
            run.append(c)
    flush(run, inh, ind)

def opacity_binding(c, own):
    op = [a for a in own if a.tag == q('animate') and a.get('attributeName') in ('opacity', 'fill-opacity', 'stroke-opacity')]
    if op:
        o = anim(op[0], c.get(op[0].get('attributeName')))
        if o: return 'A.num(sc.t, %s)' % dref(o)
    if c.get('opacity') not in (None, '1'): return c.get('opacity')
    return None

def node(c, inh, ind):
    own = [a for a in c if is_anim(a)]
    tfa = [anim(a) for a in own if a.tag == q('animateTransform')]
    tfa = [a for a in tfa if a]
    base = parse_tf(c.get('transform'))
    motion = [a for a in own if a.tag == q('animateMotion')]
    geom = [a for a in own if a.tag == q('animate') and a.get('attributeName') in SHAPES.get(c.tag, [])]
    if motion:
        mo = motion[0]
        path = mo.get('path')
        mp = mo.find(q('mpath'))
        if path is None and mp is not None and href(mp):
            t = root.find(".//*[@id='%s']" % href(mp)[1:])
            path = t.get('d') if t is not None else None
        o = anim(mo, '0') or {'d': secs(mo.get('dur'), 1), 'b': secs(mo.get('begin')), 'v': [[0], [1]], 'm': 'linear'}
        o['v'] = [[0], [1]] if not mo.get('keyPoints') else [[float(x)] for x in mo.get('keyPoints').split(';')]
        if path:
            emit('Item {', ind)
            emit('PathInterpolator { id: mo%d; path: Path { PathSvg { path: "%s" } } progress: A.num(sc.t, %s) }' % (len(DATA), ' '.join(path.split()), dref(o)), ind + 1)
            rot = 'Rotation { angle: mo%d.angle }, ' % (len(DATA) - 1) if mo.get('rotate') in ('auto', 'auto-reverse') else ''
            emit('transform: [%sTranslate { x: mo%d.x; y: mo%d.y }]' % (rot, len(DATA) - 1, len(DATA) - 1), ind + 1)
            ind += 1
            motion = 'open'
    emit('Item {', ind)
    if tfa:
        emit('transform: Matrix4x4 { matrix: A.tf(sc.t, %s, [%s]) }' % (json.dumps(base), ', '.join(dref(a) for a in tfa)), ind + 1)
    elif base != [1, 0, 0, 1, 0, 0]:
        emit('transform: Matrix4x4 { matrix: A.mat(%s) }' % json.dumps(base), ind + 1)
    ob = opacity_binding(c, own)
    if ob: emit('opacity: ' + ob, ind + 1)
    p = presentation(c, inh)
    soft = (p.get('fill') or '').startswith('url(') or c.get('filter')
    if geom and soft and c.tag in (q('circle'), q('ellipse')) and all(a.get('attributeName') in ('r', 'rx', 'ry') for a in geom):
        # a glow that swells: its sprite scaled about its centre (a Shape
        # would lose the gradient)
        cx, cy = float(c.get('cx', '0')), float(c.get('cy', '0'))
        r0 = {k: float(c.get(k) or c.get('r') or '1') for k in ('rx', 'ry')}
        sx = sy = '1'
        for a in geom:
            o = anim(a, c.get(a.get('attributeName')))
            if not o: continue
            n = a.get('attributeName')
            e_ = 'A.num(sc.t, %s)' % dref(o)
            if n in ('r', 'rx'): sx = '%s / %g' % (e_, r0['rx'])
            if n in ('r', 'ry'): sy = '%s / %g' % (e_, r0['ry'])
        emit('Item {', ind + 1)
        emit('transform: Scale { origin.x: %g; origin.y: %g; xScale: %s; yScale: %s }' % (cx, cy, sx, sy), ind + 2)
        bare = strip(copy.deepcopy(c))
        for k in ('transform', 'opacity'): bare.attrib.pop(k, None)
        flush([bare], inh, ind + 2)
        emit('}', ind + 1)
    elif geom and c.tag in SHAPES and shape(c, p, geom, ind + 1):
        pass
    elif c.tag in (q('g'), q('svg'), q('a'), q('switch')):
        walk(c, p, ind + 1)
    else:
        bare = strip(copy.deepcopy(c))
        for k in ('transform', 'opacity'):
            bare.attrib.pop(k, None)
        flush([bare], inh, ind + 1)
    emit('}', ind)
    if motion == 'open':
        emit('}', ind - 1)

def shape(c, p, geom, ind):
    """an outline that moves: a Shape; False when it cannot be one"""
    attrs = {}
    for a in geom:
        name = a.get('attributeName')
        if name == 'd':
            frames = (a.get('values') or '').strip().strip(';').split(';') if a.get('values') else [c.get('d'), a.get('to') or c.get('d')]
            ns_ = [nums(f) for f in frames]
            if len(set(len(n) for n in ns_)) != 1: return False
            tpl = re.sub(r'-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?', '@', frames[0].strip())
            o = anim(a, c.get('d'))
            if not o: return False
            o['v'] = ns_; o['tpl'] = ' '.join(tpl.split())
            attrs['d'] = 'A.path(sc.t, %s)' % dref(o)
        else:
            o = anim(a, c.get(name))
            if not o: return False
            attrs[name] = 'A.num(sc.t, %s)' % dref(o)
    g = lambda k, dflt='0': attrs.get(k) or str(float(c.get(k, dflt) or dflt))
    if c.tag == q('path'):
        d = attrs.get('d') or json.dumps(' '.join((c.get('d') or '').split()))
    elif c.tag == q('circle'):
        d = 'A.ellipse(%s, %s, %s, %s)' % (g('cx'), g('cy'), g('r'), g('r'))
    elif c.tag == q('ellipse'):
        d = 'A.ellipse(%s, %s, %s, %s)' % (g('cx'), g('cy'), g('rx'), g('ry'))
    else:
        d = 'A.rect(%s, %s, %s, %s)' % (g('x'), g('y'), g('width'), g('height'))
    fill, stroke = p.get('fill', '#000000'), p.get('stroke', 'none')
    fo, so = float(p.get('fill-opacity', '1')), float(p.get('stroke-opacity', '1'))
    emit('Shape {', ind)
    emit('preferredRendererType: Shape.CurveRenderer', ind + 1)
    emit('ShapePath {', ind + 1)
    fg = None
    if fill and fill.startswith('url('):
        gid = fill[5:-1].strip()
        ge = GRAD.get(gid)
        st = stops(ge)
        units = ge.get('gradientUnits') if ge is not None else None
        if ge is not None and st and units == 'userSpaceOnUse':
            fg = (ge, st)
        else:
            mid = st[len(st) // 2][1] if st else None
            fill = mid
    else:
        fill = color(fill, fo)
    emit('fillColor: "%s"' % (fill if fill and not fg else '#00000000'), ind + 2)
    if fg:
        ge, st = fg
        if ge.tag == q('linearGradient'):
            emit('fillGradient: LinearGradient { x1: %s; y1: %s; x2: %s; y2: %s' % tuple(str(float(ge.get(k, dv))) for k, dv in (('x1', '0'), ('y1', '0'), ('x2', '1'), ('y2', '0'))), ind + 2)
        else:
            emit('fillGradient: RadialGradient { centerX: %s; centerY: %s; centerRadius: %s; focalX: %s; focalY: %s' % (
                float(ge.get('cx', '0')), float(ge.get('cy', '0')), float(ge.get('r', '1')), float(ge.get('fx', ge.get('cx', '0'))), float(ge.get('fy', ge.get('cy', '0')))), ind + 2)
        for off, col in st:
            emit('    GradientStop { position: %g; color: "%s" }' % (off, col or '#00000000'), ind + 2)
        emit('}', ind + 2)
    sc_ = color(stroke, so) if stroke and not stroke.startswith('url(') else None
    emit('strokeColor: "%s"' % (sc_ or '#00000000'), ind + 2)
    emit('strokeWidth: %s' % (float(p.get('stroke-width', '1')) if sc_ else -1), ind + 2)
    cap = {'round': 'ShapePath.RoundCap', 'square': 'ShapePath.SquareCap'}.get(p.get('stroke-linecap'), 'ShapePath.FlatCap')
    join = {'round': 'ShapePath.RoundJoin', 'bevel': 'ShapePath.BevelJoin'}.get(p.get('stroke-linejoin'), 'ShapePath.MiterJoin')
    emit('capStyle: %s; joinStyle: %s' % (cap, join), ind + 2)
    if p.get('fill-rule') == 'evenodd': emit('fillRule: ShapePath.OddEvenFill', ind + 2)
    emit('PathSvg { path: %s }' % d, ind + 2)
    emit('}', ind + 1)
    emit('}', ind)
    return True

walk(root, {}, 1)

# the still picture: a thumbnail for the settings, the room's light for the
# login screen; the scene's own hue (the skin's colours) and whether the
# sky where the clock stands is light
still = render_svg([c for c in root if c.tag not in NONRENDER and isinstance(c.tag, str)], vb[0], vb[1], W, H, 0.5, {})
bg = Image.new('RGB', still.size, (20, 14, 18)); bg.paste(still, mask=still.split()[3])
bg.resize((bg.width * 340 // bg.width, bg.height * 340 // bg.width)).save(os.path.join(OUT, 'thumb.png'), optimize=True)   # (no JPEG in the system's Qt)
bg.resize((bg.width // 2, bg.height // 2)).filter(ImageFilter.GaussianBlur(9)).save(os.path.join(OUT, 'room.png'), optimize=True)

import math
def oklch(rgb):
    lin = [((c / 255 + .055) / 1.055) ** 2.4 if c / 255 > .04045 else c / 255 / 12.92 for c in rgb]
    l = .4122214708 * lin[0] + .5363325363 * lin[1] + .0514459929 * lin[2]
    m = .2119034982 * lin[0] + .6806995451 * lin[1] + .1073969566 * lin[2]
    s = .0883024619 * lin[0] + .2817188376 * lin[1] + .6299787005 * lin[2]
    l, m, s = [x ** (1 / 3) for x in (l, m, s)]
    L = .2104542553 * l + .7936177850 * m - .0040720468 * s
    a = 1.9779984951 * l - 2.4285922050 * m + .4505937099 * s
    b = .0259040371 * l + .7827717662 * m - .8086757660 * s
    return L, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360
small = bg.resize((96, 80))
bins = [0.0] * 36
for px in list(small.convert('RGB').tobytes()[i:i + 3] for i in range(0, 96 * 80 * 3, 3)):
    lum, C, h = oklch(px)
    if C > .03 and .2 < lum < .95: bins[int(h // 10) % 36] += C ** 1.5
sm = [bins[(k - 1) % 36] * .5 + bins[k] + bins[(k + 1) % 36] * .5 for k in range(36)]
HUE = (max(range(36), key=lambda k: sm[k]) * 10 + 5) if max(sm) > 0 else 285
corner = bg.crop((0, 0, int(bg.width * .45), int(bg.height * .3))).resize((32, 16))
cb = corner.convert('RGB').tobytes()
LIGHT = sum(oklch(cb[i:i + 3])[0] for i in range(0, len(cb), 3)) / (32 * 16) > .62

title = root.find(q('title'))
with open(os.path.join(OUT, 'Scene.qml'), 'w', encoding='utf-8') as f:
    f.write('// generated by tools/bake_scene.py from %s -- do not edit\n' % os.path.basename(src))
    f.write('// %s\n' % (title.text if title is not None else sid))
    f.write('import QtQuick\nimport QtQuick.Shapes\nimport "../../anim.js" as A\nimport "data.js" as D\n\n')
    f.write('Item {\n    id: sc\n    property bool running: true\n    width: %g; height: %g\n' % (W, H))
    f.write('    readonly property real hue: %d           // the scene\'s own (the skin\'s colours)\n' % HUE)
    f.write('    readonly property bool lightSky: %s     // the clock\'s corner: dark digits on it\n' % ('true' if LIGHT else 'false'))
    f.write('    readonly property string title: %s\n' % json.dumps(title.text if title is not None else sid, ensure_ascii=False))
    f.write('    property real t: 0\n')
    f.write('    NumberAnimation on t { from: 0; to: 36000; duration: 36000000; loops: Animation.Infinite; running: sc.running }\n')
    f.write('\n'.join(L) + '\n}\n')
with open(os.path.join(OUT, 'data.js'), 'w') as f:
    f.write('// generated by tools/bake_scene.py -- do not edit\n.pragma library\nvar a = ')
    json.dump(DATA, f, separators=(',', ':'))
    f.write(';\n')

with open(os.path.join(OUT, 'meta.json'), 'w', encoding='utf-8') as f:
    json.dump({'id': sid, 'title': title.text if title is not None else sid, 'w': W, 'h': H, 'hue': HUE, 'lightSky': LIGHT}, f, ensure_ascii=False)
n = len([v for v in SPRITES.values() if v])
print('%s: %d sprites, %d animations, %d QML lines, hue %d, light sky %s' % (sid, n, len(DATA), len(L), HUE, LIGHT))

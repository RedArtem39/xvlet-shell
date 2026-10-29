import QtQuick
import QtQuick.Shapes
import qs.services

// An M3 Expressive shape (Theme.shape points), filled; setting `shape`
// morphs to the new one point by point, as the prototype's clip-path does
Shape {
    id: root

    property var shape: Theme.shCircle
    property color color: Theme.primary
    // a diagonal gradient instead of the colour (135deg, as the prototype's
    // covers): three colours
    property var grad: []
    property LinearGradient lg: LinearGradient {
        x1: 0; y1: 0; x2: root.width; y2: root.height
        GradientStop { position: 0; color: root.grad[0] || root.color }
        GradientStop { position: .5; color: root.grad[1] || root.color }
        GradientStop { position: 1; color: root.grad[2] || root.grad[1] || root.color }
    }
    property int morphMs: 600

    property var _from: shape
    property var _to: shape
    property real _t: 1
    readonly property var _pts: {
        const a = _from, b = _to, t = _t, out = [];
        for (let i = 0; i < b.length; i++)
            out.push(Qt.point((a[i].x + (b[i].x - a[i].x) * t) * width, (a[i].y + (b[i].y - a[i].y) * t) * height));
        if (out.length) out.push(out[0]);
        return out;
    }

    onShapeChanged: {
        _from = _pts.length ? _pts.slice(0, -1).map(p => Qt.point(p.x / Math.max(1, width), p.y / Math.max(1, height))) : shape;
        _to = shape;
        morph.restart();
    }
    NumberAnimation on _t {
        id: morph
        running: false
        from: 0; to: 1
        duration: Theme.ms(root.morphMs)
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Theme.spring
    }

    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        strokeWidth: -1
        fillColor: root.color
        fillGradient: root.grad.length ? root.lg : null
        PathPolyline { path: root._pts }
    }
}

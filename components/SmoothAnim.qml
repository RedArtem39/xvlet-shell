import QtQuick
import qs.services

// M3's standard curve (cubic-bezier .2 0 0 1): for what must not overshoot
NumberAnimation {
    property int ms: 400
    duration: Theme.ms(ms)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.smooth
}

import QtQuick
import qs.services

// The M3 Expressive spring (cubic-bezier .34 1.56 .64 1): for Behaviors
NumberAnimation {
    property int ms: 450
    duration: Theme.ms(ms)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.spring
}

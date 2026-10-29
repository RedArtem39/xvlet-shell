import QtQuick
import qs.services

// colours change slowly, as the palette moves with the wallpaper
ColorAnimation {
    property int ms: 900
    duration: Theme.ms(ms)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.smooth
}

import QtQuick
import qs.services

// A card on a popout or a panel: surface-high, the medium radius
Rectangle {
    property real pad: 18
    radius: Theme.rm
    color: Theme.surfaceHigh
    Behavior on color { ColorAnim {} }
}

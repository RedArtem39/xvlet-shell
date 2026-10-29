import QtQuick
import qs.services

// A card on a popout or a panel (.card): surface-mid, the medium radius
Rectangle {
    property real pad: 18
    radius: Theme.rm
    color: Theme.surfaceMid
    Behavior on color { ColorAnim { ms: 900 } }
}

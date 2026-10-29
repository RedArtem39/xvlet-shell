import QtQuick
import qs.services

// Text in the shell's font and colours
Text {
    property real size: 14
    property int w: Font.DemiBold
    property bool dim: false
    font.family: Theme.font
    font.pixelSize: size
    font.weight: w
    color: dim ? Theme.fgSurfaceVar : Theme.fgSurface
    elide: Text.ElideRight
    Behavior on color { ColorAnim { ms: 300 } }
}

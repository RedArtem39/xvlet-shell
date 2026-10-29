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
    // (a variable font: Qt on Linux leaves the weight to the axes)
    font.variableAxes: ({ wght: w, opsz: Math.max(8, Math.min(144, size)) })
    color: dim ? Theme.fgSurfaceVar : Theme.fgSurface
    elide: Text.ElideRight
    Behavior on color { ColorAnim { ms: 300 } }
}

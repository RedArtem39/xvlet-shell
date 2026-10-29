import QtQuick
import qs.services

// A Material Symbols Rounded icon: its name is the text (a ligature)
Text {
    property bool fill: false
    property real size: 24

    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ FILL: fill ? 1 : 0, wght: fill ? 500 : 450, GRAD: 0, opsz: Math.min(48, Math.max(20, size)) })
    color: Theme.onSurface
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering
}

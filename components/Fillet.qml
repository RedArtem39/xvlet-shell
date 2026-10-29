import QtQuick
import qs.services

// A concave corner where a sheet meets the screen's edge (the prototype's
// radial-gradient ::before/::after): a square of colour with a quarter
// circle cut out round one of its corners -- hole: "tl", "tr", "bl", "br"
Canvas {
    id: f
    property real size: Theme.r
    property string hole: "tl"
    property color color: Theme.surface
    width: size; height: size
    onColorChanged: requestPaint()
    onSizeChanged: requestPaint()
    onHoleChanged: requestPaint()
    onPaint: {
        const g = getContext("2d"); g.reset();
        g.fillStyle = color; g.fillRect(0, 0, size, size);
        g.globalCompositeOperation = "destination-out";
        g.beginPath();
        g.arc(hole[1] === "r" ? size : 0, hole[0] === "b" ? size : 0, size, 0, Math.PI * 2);
        g.fill();
    }
}

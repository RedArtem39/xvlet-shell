import QtQuick
import QtQuick.Shapes
import qs.services

// A cat asleep on its pillow (cat-nap.svg, redrawn as Shapes: the system has
// no QtSvg, and QtSvg plays no CSS anyway): it breathes, the Z's drift up.
// The drawing's own view is 160x120 (x 50..210, y 15..135 of the original).
// `live`: animate (off while hidden: no frames for nothing).
Item {
    id: root
    property bool live: true
    implicitWidth: 200; implicitHeight: 150

    component P: ShapePath {
        property alias d: ps.path
        fillColor: "transparent"; strokeColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        PathSvg { id: ps }
    }
    // circles as one path: "x,y,r" each
    function dots(list) {
        return list.map(c => { const [x, y, r] = c;
            return "M" + (x - r) + " " + y + " a" + r + " " + r + " 0 1 0 " + 2 * r + " 0 a" + r + " " + r + " 0 1 0 " + -2 * r + " 0Z"; }).join(" ");
    }

    Item {
        width: 160; height: 120
        transform: [Translate { x: -50; y: -15 }, Scale { xScale: root.width / 160; yScale: root.height / 120 }]
        Shape {
            width: 280; height: 160
            preferredRendererType: Shape.CurveRenderer
            P { fillColor: "#ff8eae"; strokeColor: "#74423e"; strokeWidth: 2.5
                d: "M77 72 C66 72 58 80 57 92 C55 105 62 117 73 121 C95 129 159 129 183 121 C195 117 201 107 199 94 C198 81 190 73 179 72 C154 68 101 68 77 72Z" }
            P { fillColor: "#fff8f4"; strokeWidth: -1
                d: root.dots([[67,87,2.5],[84,79,2.4],[103,87,2.5],[124,78,2.5],[145,87,2.5],[166,78,2.4],[187,87,2.4],[78,101,2.4],
                              [98,108,2.5],[119,98,2.4],[139,110,2.5],[161,99,2.4],[181,108,2.5],[68,108,2],[191,101,2]]) }
        }
        Shape {
            width: 280; height: 160
            preferredRendererType: Shape.CurveRenderer
            // the bottom of its body (y 94), its middle (x 132)
            transform: Scale { id: breath; origin.x: 132; origin.y: 94 }
            P { fillColor: "#b9a990"; strokeColor: "#554536"; strokeWidth: 2.5
                d: "M80 87 C80 73 86 56 98 51 C107 47 119 48 130 52 L136 42 Q138 39 141 42 L148 52 C151 47 156 42 160 41 Q163 40 165 44 L173 55 C181 59 185 69 185 81 L184 91 C171 96 93 96 79 91Z" }
            P { strokeColor: "#8c7660"; strokeWidth: 2; d: "M133 48 L138 44 L143 51 M156 49 L161 45 L166 53" }
            P { strokeColor: "#ddd4c5ac"; strokeWidth: 2.2; d: "M86 83 C90 78 96 77 102 78 M106 58 C111 55 117 55 122 57" }
            P { strokeColor: "#75624f"; strokeWidth: 1.8; d: "M123 89 Q130 83 137 89 M142 89 Q149 83 156 89" }
            P { strokeColor: "#57473c"; strokeWidth: 2; d: "M150 64 L159 64 M169 64 L178 64" }
            P { strokeColor: "#8b625c"; strokeWidth: 1.8; d: "M162 68 Q164 71 166 68" }
            P { strokeColor: "#8b625c"; strokeWidth: 1.4; d: "M164 71 Q161 75 158 73 M164 71 Q167 75 170 73" }
            P { strokeColor: "#8b7663"; strokeWidth: 1.1; d: "M151 71 L143 69 M151 74 L142 74 M151 77 L144 79 M178 71 L186 69 M178 74 L187 74 M178 77 L185 79" }
            SequentialAnimation {
                running: root.live; loops: Animation.Infinite
                NumberAnimation { target: breath; property: "yScale"; from: 1; to: 1.025; duration: 1900; easing.type: Easing.InOutSine }
                NumberAnimation { target: breath; property: "yScale"; from: 1.025; to: 1; duration: 1900; easing.type: Easing.InOutSine }
            }
        }
        Repeater {
            model: [{ x: 169, y: 38, s: 19, d: 0 }, { x: 187, y: 25, s: 13, d: 1250 }]
            Text {
                id: z
                required property var modelData
                property real k: 0
                text: "Z"; font.family: "Georgia, serif"; font.bold: true; font.pixelSize: modelData.s
                color: Theme.tertiary
                x: modelData.x + 2 * k; y: modelData.y - modelData.s - 6 * k + 2
                rotation: -5 + 9 * k
                opacity: .5 + .5 * k
                SequentialAnimation on k {
                    running: root.live; loops: Animation.Infinite
                    PauseAnimation { duration: z.modelData.d }
                    NumberAnimation { from: 0; to: 1; duration: 1700; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1; to: 0; duration: 1700; easing.type: Easing.InOutSine }
                    PauseAnimation { duration: 1250 - z.modelData.d }
                }
            }
        }
    }
}

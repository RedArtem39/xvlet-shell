// The login screen's clock on its scene (the skin's card, and its live
// preview in the shell's settings). Styles:
//   big     the shell's heavy digits
//   tall    narrow digits stretched up the sky (as Apple's lock screen)
//   thin    light, wide digits
//   analog  a dial
// align: left, center or right in the space it is given; k: the scale (the
// card's height / 560).
import QtQuick

Item {
    id: c
    property string style: "big"
    property string align: "left"
    property bool showDate: true
    property color ink: "white"
    property real k: 1
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: c.now = new Date() }

    readonly property real m: 36 * k
    readonly property string hm: Qt.formatTime(now, "hh:mm")
    readonly property string day: now.toLocaleDateString(Qt.locale("ru_RU"), "dddd, d MMMM")
    function ax(w) { return align === "center" ? (width - w) / 2 : align === "right" ? width - w - m : m; }
    function dim(a) { return Qt.rgba(ink.r, ink.g, ink.b, a); }

    // ---- big
    Column {
        visible: c.style === "big"
        x: c.ax(width); y: 24 * c.k
        T { anchors.right: c.align === "right" ? parent.right : undefined; anchors.horizontalCenter: c.align === "center" ? parent.horizontalCenter : undefined
            text: c.hm; px: 104 * c.k; wght: 800; ls: -4 * c.k }
        T { anchors.right: c.align === "right" ? parent.right : undefined; anchors.horizontalCenter: c.align === "center" ? parent.horizontalCenter : undefined
            visible: c.showDate; text: c.day; px: 19 * c.k; wght: 650; color: c.dim(.85); leftPadding: 6 * c.k; rightPadding: 6 * c.k; topPadding: -6 * c.k }
    }

    // ---- thin
    Column {
        visible: c.style === "thin"
        x: c.ax(width); y: 20 * c.k
        T { anchors.right: c.align === "right" ? parent.right : undefined; anchors.horizontalCenter: c.align === "center" ? parent.horizontalCenter : undefined
            text: c.hm; px: 128 * c.k; wght: 200; ls: -2 * c.k }
        T { anchors.right: c.align === "right" ? parent.right : undefined; anchors.horizontalCenter: c.align === "center" ? parent.horizontalCenter : undefined
            visible: c.showDate; text: c.day; px: 18 * c.k; wght: 450; color: c.dim(.85); leftPadding: 4 * c.k; rightPadding: 4 * c.k; topPadding: -8 * c.k }
    }

    // ---- tall: narrow digits stretched up the sky
    Item {
        id: tall
        visible: c.style === "tall"
        readonly property real stretch: 1.9
        width: Math.max(tt.implicitWidth, td.implicitWidth); height: tt.implicitHeight * stretch + (c.showDate ? td.implicitHeight + 6 * c.k : 0)
        x: c.ax(width); y: 14 * c.k
        T {
            id: td
            visible: c.showDate
            x: c.align === "center" ? (parent.width - width) / 2 : c.align === "right" ? parent.width - width : 0
            text: c.day.toUpperCase(); px: 16 * c.k; wght: 700; ls: 2.2 * c.k; color: c.dim(.85)
        }
        T {
            id: tt
            x: c.align === "center" ? (parent.width - width) / 2 : c.align === "right" ? parent.width - width : 0
            y: c.showDate ? td.implicitHeight + 6 * c.k : 0
            text: c.hm; px: 150 * c.k; wght: 650; wdth: 25; ls: -2 * c.k
            transform: Scale { yScale: tall.stretch }
        }
    }

    // ---- analog: a dial
    Item {
        id: dial
        visible: c.style === "analog"
        readonly property real d: 168 * c.k
        width: d; height: d + (c.showDate ? 34 * c.k : 0)
        x: c.ax(width); y: 30 * c.k
        Rectangle { width: dial.d; height: width; radius: width / 2; color: c.dim(.10); border.width: 2 * c.k; border.color: c.dim(.45) }
        Repeater {
            model: 12
            Rectangle {
                id: tick
                required property int index
                width: (index % 3 ? 2.5 : 4) * c.k; height: (index % 3 ? 8 : 15) * c.k; radius: width / 2
                color: c.dim(index % 3 ? .55 : .9)
                x: dial.d / 2 - width / 2; y: 8 * c.k
                transform: Rotation { origin.x: tick.width / 2; origin.y: dial.d / 2 - 8 * c.k; angle: tick.index * 30 }
            }
        }
        Hand { len: .27; thick: 7; angle: (c.now.getHours() % 12 + c.now.getMinutes() / 60) * 30 }
        Hand { len: .38; thick: 4.5; angle: (c.now.getMinutes() + c.now.getSeconds() / 60) * 6 }
        Rectangle { width: 12 * c.k; height: width; radius: width / 2; color: c.ink; x: dial.d / 2 - width / 2; y: dial.d / 2 - width / 2 }
        T {
            visible: c.showDate
            anchors.horizontalCenter: parent.horizontalCenter; y: dial.d + 10 * c.k
            text: c.day; px: 16 * c.k; wght: 650; color: c.dim(.85)
        }
    }

    component Hand: Rectangle {
        id: hand
        property real len
        property real thick
        property real angle
        width: thick * c.k; height: dial.d * len; radius: width / 2
        color: c.ink
        x: dial.d / 2 - width / 2; y: dial.d / 2 - height
        transform: Rotation { origin.x: hand.width / 2; origin.y: hand.height; angle: hand.angle }
    }
    component T: Text {
        property real px: 14
        property int wght: 600
        property real wdth: 100
        property real ls: 0
        font.family: "Roboto Flex"
        font.pixelSize: px
        font.weight: wght
        font.letterSpacing: ls
        font.variableAxes: ({ wght: wght, wdth: wdth, opsz: Math.max(8, Math.min(144, px)) })
        font.features: ({ tnum: 1 })
        color: c.ink
    }
}

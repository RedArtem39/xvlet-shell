import QtQuick
import qs.components
import qs.services

// The wallpaper picker (the prototype's #wpick, Serpantinum's): slanted
// cards on a dimmed screen -- the chosen one wide in the middle, its
// neighbours smaller and darker; a row of colours on top keeps only the
// wallpapers of a hue. The arrows and the wheel move, Enter or a click on
// the middle one puts it on (it comes over the old one out of the card).
Item {
    id: root
    property bool shown: false
    property int hueK: 0
    property int cur: 0
    readonly property var hues: [{ n: "Все" }, { h: 25, a: [0, 45] }, { h: 70, a: [45, 100] }, { h: 145, a: [100, 180] }, { h: 220, a: [180, 250] }, { h: 285, a: [250, 320] }, { h: 345, a: [320, 361] }]
    readonly property var list: {
        const f = hues[hueK];
        return Walls.list.filter(p => { if (!f.a) return true; const h = Walls.hueOf(p); return h >= f.a[0] && h < f.a[1]; });
    }

    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    Behavior on opacity { SmoothAnim { ms: 300 } }
    onShownChanged: if (shown) { hueK = 0; cur = Math.max(0, list.indexOf(Config.data.wall.path)); keys.forceActiveFocus(); }
    onHueKChanged: cur = Math.max(0, list.indexOf(Config.data.wall.path))

    function apply() { const p = list[cur]; if (p) { Ui.wallpick = false; Walls.set(p); } }

    Item {
        id: keys
        focus: root.shown
        Keys.onRightPressed: root.cur = Math.min(root.list.length - 1, root.cur + 1)
        Keys.onLeftPressed: root.cur = Math.max(0, root.cur - 1)
        Keys.onReturnPressed: root.apply()
        Keys.onEscapePressed: Ui.wallpick = false
    }
    WheelHandler { onWheel: e => root.cur = Math.max(0, Math.min(root.list.length - 1, root.cur + ((e.angleDelta.y || e.angleDelta.x) < 0 ? 1 : -1))) }

    // the colours: all, or a hue
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 250
        width: bar.implicitWidth + 16; height: 52
        radius: Theme.rm
        color: Theme.surfaceLow
        MouseArea { anchors.fill: parent }
        Row {
            id: bar
            anchors.centerIn: parent
            spacing: 6
            Repeater {
                model: root.hues
                Item {
                    id: hb
                    required property var modelData
                    required property int index
                    readonly property bool on: root.hueK === index
                    width: modelData.n ? allLbl.implicitWidth + 28 : 36; height: 36
                    anchors.verticalCenter: parent.verticalCenter
                    // the ring of the chosen colour
                    Rectangle { visible: !hb.modelData.n && hb.on; anchors.centerIn: parent; width: 46; height: 46; radius: 23; color: "transparent"; border.width: 2; border.color: Theme.fgSurface }
                    Rectangle {
                        anchors.fill: parent
                        radius: hb.on || hm.containsMouse ? 18 : 12
                        color: hb.modelData.n ? (hb.on ? Theme.secondaryContainer : Theme.surfaceHigh) : Theme.oklch(70, .15, hb.modelData.h || 0)
                        scale: !hb.modelData.n && hm.containsMouse ? 1.08 : 1
                        Behavior on radius { SpringAnim { ms: 350 } }
                        Behavior on scale { SpringAnim { ms: 350 } }
                        Label { id: allLbl; visible: !!hb.modelData.n; anchors.centerIn: parent; text: hb.modelData.n || ""; size: 13; w: 700; color: hb.on ? Theme.fgSecondaryContainer : Theme.fgSurface }
                    }
                    MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true; onClicked: root.hueK = hb.index }
                }
            }
            IconButton { icon: "shuffle"; anchors.verticalCenter: parent.verticalCenter; onClicked: root.cur = Math.floor(Math.random() * root.list.length) }
        }
    }

    // the cards
    Item {
        id: track
        width: parent.width; height: 420
        y: 340
        MouseArea { anchors.fill: parent; onClicked: Ui.wallpick = false }
        Repeater {
            model: root.list
            Item {
                id: card
                required property string modelData
                required property int index
                readonly property int d: index - root.cur
                readonly property int ad: Math.abs(d)
                readonly property bool isCur: d === 0
                width: isCur ? 560 : 300; height: 420
                x: track.width / 2 - width / 2 + (d === 0 ? 0 : Math.sign(d) * (380 + (ad - 1) * 190))
                z: 100 - ad
                scale: isCur ? 1.06 : Math.max(.7, 1 - ad * .08)
                // far ones: gone, not just clear (they lay over the desktop)
                visible: ad <= 4
                opacity: ad > 3 ? 0 : 1
                // a new card starts where it belongs: it glides only when
                // the chosen one changes, never in from the left edge
                property bool placed: false
                Component.onCompleted: Qt.callLater(() => placed = true)
                Behavior on x { enabled: card.placed; SpringAnim { ms: 600 } }
                Behavior on width { SpringAnim { ms: 500 } }
                Behavior on scale { SpringAnim { ms: 600 } }
                Behavior on opacity { enabled: card.placed; NumberAnimation { duration: 400 } }
                readonly property real dim: isCur ? 0 : 1 - Math.max(.45, 1 - ad * .15)
                onDimChanged: pic.requestPaint()
                onWidthChanged: pic.requestPaint()

                // the picture, slanted (skewX -12deg) and rounded; the
                // picture itself kept upright inside the slant
                Canvas {
                    id: pic
                    // (the slant reaches past the card by half its height times tan 12deg on each side)
                    readonly property real k: Math.tan(12 * Math.PI / 180)
                    readonly property real o: card.height / 2 * k
                    x: -o; width: card.width + 2 * o; height: card.height
                    readonly property string src: "file://" + card.modelData
                    Image { id: probe; visible: false; source: pic.src; asynchronous: true }
                    Component.onCompleted: loadImage(src)
                    onImageLoaded: requestPaint()
                    onWidthChanged: requestPaint()
                    onPaint: {
                        const g = getContext("2d"), W = card.width, H = height, R = Theme.rm, Wc = width;
                        g.reset();
                        g.save();
                        g.transform(1, 0, -k, 1, 2 * o, 0);
                        g.beginPath(); g.roundedRect(0, 0, W, H, R, R); g.clip();
                        g.setTransform(1, 0, 0, 1, 0, 0);
                        if (isImageLoaded(src) && probe.implicitWidth > 0) {
                            // cover the box: the picture's middle
                            const iw = probe.implicitWidth, ih = probe.implicitHeight, sc = Math.max(Wc / iw, H / ih), sw = Wc / sc, sh = H / sc;
                            g.drawImage(src, (iw - sw) / 2, (ih - sh) / 2, sw, sh, 0, 0, Wc, H);
                        } else { g.fillStyle = Theme.surfaceHigh; g.fillRect(0, 0, Wc, H); }
                        if (card.dim > 0) { g.fillStyle = Qt.rgba(0, 0, 0, card.dim); g.fillRect(0, 0, Wc, H); }
                        g.restore();
                    }
                    Connections { target: probe; function onStatusChanged() { pic.requestPaint(); } }
                }
                Label {
                    x: 24 - 18 * Math.tan(12 * Math.PI / 180); anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                    text: Walls.nameOf(card.modelData); size: 15; w: 700; color: "white"
                    style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, .4)
                }
                MouseArea { anchors.fill: parent; onClicked: { Sfx.ui(card.isCur ? "press" : "click"); if (card.isCur) root.apply(); else root.cur = card.index; } }
            }
        }
        Label { visible: root.list.length === 0; anchors.centerIn: parent; text: "Нет обоев этого цвета"; size: 15; w: 600; color: "white" }
    }
    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 200
        text: "← → или колёсико · Enter — поставить · Esc — закрыть · свои: ~/Pictures/Wallpapers"
        size: 14; w: 600; color: Theme.oklch(96, .02, Theme.now.h, .8)
    }
}

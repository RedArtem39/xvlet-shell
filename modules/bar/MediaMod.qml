import QtQuick
import QtQuick.Effects
import qs.components
import qs.services

// What plays, in the bar:
//   playing  the cover in a circle, the track's progress as a ring round
//            it; the title (running along when it does not fit) and the
//            artist; little bars that dance -- the pointer on it: back,
//            play/pause, next instead
//   paused   the same, the cover dimmed, a pause mark for the bars
//   nothing  a quiet pill: a breathing cookie with a note, "Тишина", three
//            dots taking turns -- a click: the dashboard's media tab
// On a side bar: the cover with its ring (a pause mark over it while
// paused), or the breathing cookie.
Rectangle {
    id: root
    property bool vert: false
    readonly property bool has: Media.present
    readonly property bool on: Media.playing
    readonly property bool hov: hh.hovered
    readonly property real prog: Media.length > 0 ? Math.max(0, Math.min(1, Media.position / Media.length)) : 0

    implicitWidth: vert ? 40 : row.implicitWidth + 20
    implicitHeight: vert && (on || !has) ? 58 : 40
    Behavior on implicitHeight { SpringAnim { ms: 450 } }
    radius: hov ? 14 : 20
    color: !has ? (hov ? Theme.alpha(Theme.fgSurface, .08) : "transparent")
         : Theme.alpha(Theme.primary, hov ? .2 : on ? .13 : .07)
    Behavior on radius { SpringAnim {} }
    Behavior on color { ColorAnim { ms: 300 } }
    Behavior on implicitWidth { SpringAnim { ms: 450 } }

    HoverHandler { id: hh }
    // the click (under the controls): the dashboard's media tab
    MouseArea {
        anchors.fill: parent
        onClicked: { const p = root.mapToItem(null, root.width / 2, root.height / 2); Ui.toggle("dash", root.vert ? p.y : p.x); Ui.dashTab = "md"; }
    }

    // ---- the cover, its ring ----
    component Cover: Item {
        width: 36; height: 36
        // the progress round it
        Canvas {
            id: ring
            anchors.fill: parent
            property real v: root.prog
            property color fg: Theme.primary
            property color tr: Theme.alpha(Theme.fgSurface, .14)
            onVChanged: requestPaint()
            onFgChanged: requestPaint()
            visible: root.has
            onPaint: {
                const g = getContext("2d"), c = width / 2, r = c - 2;
                g.reset(); g.lineWidth = 2.5; g.lineCap = "round";
                g.strokeStyle = tr; g.beginPath(); g.arc(c, c, r, 0, Math.PI * 2); g.stroke();
                if (v > 0) { g.strokeStyle = fg; g.beginPath(); g.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + v * Math.PI * 2); g.stroke(); }
            }
        }
        // the cover itself (or the note on a cookie when there is none)
        Item {
            anchors.centerIn: parent
            width: 28; height: 28
            visible: root.has
            opacity: root.on ? 1 : .55
            Behavior on opacity { SmoothAnim { ms: 300 } }
            MShape { anchors.fill: parent; shape: Theme.shCircle; color: Theme.tertiaryContainer; visible: !img.ready }
            MIcon { anchors.centerIn: parent; text: "music_note"; fill: true; size: 16; color: Theme.fgTertiaryContainer; visible: !img.ready }
            Image {
                id: img
                readonly property bool ready: status === Image.Ready
                anchors.fill: parent
                source: Media.art
                sourceSize: Qt.size(56, 56)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }
            Rectangle { id: mask; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }
            MultiEffect {
                anchors.fill: parent
                source: img
                visible: img.ready
                maskEnabled: true
                maskSource: mask
            }
            RotationAnimation on rotation { from: 0; to: 360; duration: 12000; loops: Animation.Infinite; running: root.on && !Theme.still }
        }
        // paused, on a side bar: the pause mark over it
        MIcon { anchors.centerIn: parent; visible: root.vert && root.has && !root.on; text: "pause"; fill: true; size: 18; color: Theme.fgSurface }
        // nothing: a cookie that breathes
        MShape {
            anchors.centerIn: parent
            width: 32; height: 32
            visible: !root.has
            shape: Theme.shCookie9
            color: Theme.alpha(Theme.tertiary, .22)
            SequentialAnimation on scale {
                running: !root.has && !Theme.still; loops: Animation.Infinite
                NumberAnimation { from: .9; to: 1.04; duration: 1800; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.04; to: .9; duration: 1800; easing.type: Easing.InOutSine }
            }
            MIcon { anchors.centerIn: parent; text: "music_note"; fill: true; size: 16; color: Theme.tertiary }
        }
    }

    // a side bar: under the cover, small dancing bars while it plays, the
    // three dots while nothing does
    Row {
        visible: root.vert && (root.on || !root.has)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 6
        height: 10; spacing: 3
        Repeater {
            model: root.vert && (root.on || !root.has) ? 3 : 0
            Rectangle {
                id: vb
                required property int index
                width: root.on ? 3 : 4; radius: 2
                anchors.verticalCenter: parent.verticalCenter
                color: root.on ? Theme.primary : Theme.fgSurfaceVar
                property real h: 4
                height: root.on ? h : 4
                opacity: root.on ? 1 : .3
                SequentialAnimation on h {
                    running: root.vert && root.on && !Theme.still; loops: Animation.Infinite
                    PauseAnimation { duration: vb.index * 140 }
                    NumberAnimation { to: 10; duration: 420; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 4; duration: 420; easing.type: Easing.InOutQuad }
                }
                SequentialAnimation on opacity {
                    running: root.vert && !root.has && !Theme.still; loops: Animation.Infinite
                    PauseAnimation { duration: vb.index * 350 }
                    NumberAnimation { to: .9; duration: 500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: .3; duration: 500; easing.type: Easing.InOutSine }
                    PauseAnimation { duration: (2 - vb.index) * 350 }
                }
            }
        }
    }

    Row {
        id: row
        x: root.vert ? 2 : 6
        y: root.vert ? 2 : (root.height - height) / 2
        spacing: 10
        Cover { anchors.verticalCenter: parent.verticalCenter }

        // the words
        Column {
            visible: !root.vert
            anchors.verticalCenter: parent.verticalCenter
            width: root.has ? Math.min(220, Math.max(110, Math.max(t1.implicitWidth, t2.implicitWidth))) : Math.max(n1.implicitWidth, n2.implicitWidth)
            // playing / paused: the title running along when it does not fit
            Item {
                visible: root.has
                width: parent.width; height: t1.implicitHeight
                clip: true
                Label {
                    id: t1
                    text: Media.title; size: 13.5; w: 650
                    readonly property real over: implicitWidth - parent.width
                    x: 0
                    SequentialAnimation on x {
                        running: root.has && t1.over > 4 && !Theme.still; loops: Animation.Infinite
                        PauseAnimation { duration: 2200 }
                        NumberAnimation { to: -t1.over; duration: Math.max(1500, t1.over * 28); easing.type: Easing.InOutSine }
                        PauseAnimation { duration: 1600 }
                        NumberAnimation { to: 0; duration: Math.max(1500, t1.over * 28); easing.type: Easing.InOutSine }
                    }
                }
            }
            Label { id: t2; visible: root.has && text !== ""; text: Media.artist; size: 11.5; w: 550; dim: true; width: parent.width; elide: Text.ElideRight }
            // nothing
            Label { id: n1; visible: !root.has; text: "Тишина"; size: 13.5; w: 650 }
            Label { id: n2; visible: !root.has; text: "включить музыку"; size: 11.5; w: 550; dim: true }
        }

        // the right end: the bars / the pause mark / the controls / the dots
        Item {
            visible: !root.vert
            anchors.verticalCenter: parent.verticalCenter
            width: root.has && root.hov ? ctl.width : root.has ? 26 : 24
            height: 32
            clip: true
            Behavior on width { SpringAnim { ms: 450 } }
            // dancing (or a pause mark)
            Row {
                anchors.right: parent.right; anchors.rightMargin: root.on ? 4 : 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                visible: root.has && opacity > .01
                // (the pointer on it: they fade, the controls come in)
                opacity: root.hov ? 0 : 1
                scale: root.hov ? .6 : 1
                Behavior on opacity { SmoothAnim { ms: 180 } }
                Behavior on scale { SpringAnim { ms: 400 } }
                Repeater {
                    model: root.on ? 4 : 0
                    Rectangle {
                        id: eq
                        required property int index
                        width: 3.5; radius: 2; color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                        property real h: 6
                        height: h
                        SequentialAnimation on h {
                            running: root.on && !Theme.still
                            loops: Animation.Infinite
                            PauseAnimation { duration: eq.index * 140 }
                            NumberAnimation { to: 18; duration: 420; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 6; duration: 420; easing.type: Easing.InOutQuad }
                        }
                    }
                }
                MIcon { visible: !root.on; text: "pause"; fill: true; size: 18; color: Theme.fgSurfaceVar }
            }
            // the pointer on it: back, play/pause, next
            Row {
                id: ctl
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                spacing: 0
                visible: root.has && opacity > .01
                opacity: root.hov ? 1 : 0
                scale: root.hov ? 1 : .7
                transformOrigin: Item.Right
                transform: Translate { x: root.hov ? 0 : 14; Behavior on x { SpringAnim { ms: 450 } } }
                Behavior on opacity { SmoothAnim { ms: 220 } }
                Behavior on scale { SpringAnim { ms: 450 } }
                IconButton { size: 30; iconSize: 18; icon: "skip_previous"; fill: true; onClicked: Media.prev() }
                IconButton { size: 30; iconSize: 20; icon: root.on ? "pause" : "play_arrow"; fill: true; on: true; onClicked: Media.toggle() }
                IconButton { size: 30; iconSize: 18; icon: "skip_next"; fill: true; onClicked: Media.next() }
            }
            // nothing: three dots taking turns
            Row {
                anchors.centerIn: parent
                spacing: 4
                visible: !root.has
                Repeater {
                    model: 3
                    Rectangle {
                        id: dot
                        required property int index
                        width: 4; height: 4; radius: 2
                        color: Theme.fgSurfaceVar
                        opacity: .3
                        SequentialAnimation on opacity {
                            running: !root.has && !Theme.still; loops: Animation.Infinite
                            PauseAnimation { duration: dot.index * 350 }
                            NumberAnimation { to: .9; duration: 500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: .3; duration: 500; easing.type: Easing.InOutSine }
                            PauseAnimation { duration: (2 - dot.index) * 350 }
                        }
                    }
                }
            }
        }
    }
}

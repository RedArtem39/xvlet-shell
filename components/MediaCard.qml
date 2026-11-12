import QtQuick
import QtQuick.Effects
import qs.services

// What plays, Resonance's player: the cover a 9-lobed cookie while it plays
// and a circle while paused (eased between them); the title, the artist,
// the wavy line (press it to seek), the times, the controls -- the play
// button a pill that tightens while playing.
//   big: the cover on top in its wavy progress ring (drag the ring to
//        seek), everything else under it, centred
//   else: the cover on the left, the rest beside it
// Nothing plays: says so.
Item {
    id: root
    property real art: 132
    property bool big: false
    property bool small: false        // (a widget's: smaller controls)

    implicitHeight: big ? bigCol.implicitHeight : Math.max(art, col.implicitHeight)

    // ---- the cover ----
    component Cover: Item {
        id: cv
        property real size: 132
        width: size; height: size
        MShape {
            id: coverShape
            anchors.fill: parent
            shape: Media.playing ? Theme.shPlaying : Theme.shCircle
            morphMs: 900
            opacity: Media.present ? 1 : .35
            Behavior on opacity { SmoothAnim { ms: 400 } }
            SequentialAnimation on scale {
                running: !Media.present && !Theme.still; loops: Animation.Infinite
                NumberAnimation { from: .94; to: 1.02; duration: 2000; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.02; to: .94; duration: 2000; easing.type: Easing.InOutSine }
            }
            grad: [Theme.tertiary, Theme.primary, Theme.primaryContainer]
        }
        Image {
            id: img
            anchors.fill: parent
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
            asynchronous: true
            layer.enabled: visible
            layer.effect: MultiEffect { maskEnabled: true; maskSource: coverShape; maskThresholdMin: .5; maskSpreadAtMin: .2 }
        }
        MIcon { anchors.centerIn: parent; visible: img.status !== Image.Ready; text: "music_note"; fill: true; size: cv.size * .39; color: Theme.fgPrimary }
    }

    // ---- the line, the times ----
    component Seek: Column {
        width: parent ? parent.width : 0
        visible: Media.present
        WavyProgress {
            width: parent.width; height: 32
            value: Media.length > 0 ? Media.position / Media.length : 0
            waving: Media.playing
            onSeek: f => Media.seek(f)
        }
        Item {
            width: parent.width; height: 16
            Label { text: Media.fmt(Media.position); size: 12; w: 600; dim: true; font.features: { "tnum": 1 } }
            Label { anchors.right: parent.right; text: Media.fmt(Media.length); size: 12; w: 600; dim: true; font.features: { "tnum": 1 } }
        }
    }

    // ---- the controls ----
    component Controls: Row {
        id: ctls
        property bool large: false
        property bool sm: false
        spacing: 8
        visible: Media.present
        Ctl { icon: "skip_previous"; s: ctls.large ? 56 : ctls.sm ? 40 : 48; onClicked: Media.prev() }
        Rectangle {
            readonly property real bw: ctls.large ? 84 : ctls.sm ? 60 : 76
            width: (Media.playing ? bw - 8 : bw) + (pm.containsMouse ? 8 : 0); height: ctls.large ? 72 : ctls.sm ? 44 : 56
            radius: Media.playing ? (ctls.large ? 22 : ctls.sm ? 14 : 18) : height / 2
            color: Theme.primary
            scale: pm.pressed ? .9 : 1
            anchors.verticalCenter: parent.verticalCenter
            Behavior on width { SpringAnim { ms: 450 } }
            Behavior on radius { SpringAnim { ms: 450 } }
            Behavior on scale { SpringAnim { ms: 350 } }
            MIcon { anchors.centerIn: parent; text: Media.playing ? "pause" : "play_arrow"; fill: true; size: ctls.large ? 34 : ctls.sm ? 26 : 30; color: Theme.fgPrimary }
            MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; onClicked: Media.toggle() }
        }
        Ctl { icon: "skip_next"; s: ctls.large ? 56 : ctls.sm ? 40 : 48; onClicked: Media.next() }
    }

    // ---- beside (the overview, the widgets) ----
    Cover {
        visible: !root.big
        size: root.art
        anchors.verticalCenter: parent.verticalCenter
    }
    Column {
        id: col
        visible: !root.big
        x: root.art + 18
        width: root.width - x
        anchors.verticalCenter: parent.verticalCenter
        Label { text: Media.present ? Media.title : "Тишина"; size: root.small ? 18 : 22; w: 700; font.letterSpacing: -.3; width: parent.width; elide: Text.ElideRight }
        Label { text: Media.present ? Media.artist : "Включите музыку — она появится здесь"; size: 14; w: 500; dim: true; width: parent.width; topPadding: 2; elide: Text.ElideRight }
        Item { width: 1; height: 8 }
        Seek {}
        Controls { topPadding: 8; sm: root.small }
    }

    // ---- big: the cover in its ring on top ----
    Column {
        id: bigCol
        visible: root.big
        width: parent.width
        Item {
            width: root.art; height: root.art
            anchors.horizontalCenter: parent.horizontalCenter
            RingProgress {
                anchors.fill: parent
                visible: Media.present
                value: Media.length > 0 ? Media.position / Media.length : 0
                waving: Media.playing
                onSeek: f => Media.seek(f)
            }
            Cover { x: root.art * .09; y: root.art * .09; size: root.art * .82 }
        }
        Item { width: 1; height: 14 }
        Label { text: Media.present ? Media.title : "Тишина"; size: 24; w: 700; font.letterSpacing: -.4; width: parent.width; elide: Text.ElideRight }
        Label { text: Media.present ? Media.artist : "Включите музыку — она появится здесь"; size: 14; w: 500; dim: true; width: parent.width; topPadding: 4; elide: Text.ElideRight }
        Item { width: 1; height: 12 }
        Seek {}
        Controls { large: true; topPadding: 10; anchors.horizontalCenter: parent.horizontalCenter }
    }

    component Ctl: Rectangle {
        id: c
        property string icon
        property real s: 48
        signal clicked
        width: s; height: s
        radius: cm.containsMouse ? s / 3 : s / 2
        color: Theme.surfaceHighest
        scale: cm.pressed ? .88 : 1
        anchors.verticalCenter: parent.verticalCenter
        Behavior on radius { SpringAnim { ms: 350 } }
        Behavior on scale { SpringAnim { ms: 350 } }
        MIcon { anchors.centerIn: parent; text: c.icon; fill: true; size: 24 }
        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onClicked: c.clicked() }
    }
}

import QtQuick
import QtQuick.Effects
import qs.services

// What plays (the prototype's .media): the cover (a cookie while paused, a
// circle while it plays; no art: the gradient and a note), the title, the
// artist, the wavy progress (press it to seek), the times, the controls --
// the play button a pill that tightens while playing. Nothing: says so.
Item {
    id: root
    property real art: 132
    property bool big: false
    property bool small: false        // (a widget's: smaller controls)

    implicitHeight: Math.max(art, col.implicitHeight)

    Item {
        id: cover
        width: root.art; height: root.art
        anchors.verticalCenter: parent.verticalCenter
        readonly property real h: Theme.now.h
        MShape {
            id: coverShape
            anchors.fill: parent
            shape: Media.playing ? Theme.shCircle : Theme.shCookie12
            morphMs: 700
            grad: [Theme.oklch(70, .15, cover.h + 60), Theme.oklch(55, .17, cover.h), Theme.oklch(40, .12, cover.h - 40)]
        }
        // the cover art, cut to the shape
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
        MIcon { anchors.centerIn: parent; visible: img.status !== Image.Ready; text: "music_note"; fill: true; size: root.art * .39; color: Qt.rgba(.98, .98, .98, .9) }
    }
    Column {
        id: col
        x: root.art + 18
        width: root.width - x
        anchors.verticalCenter: parent.verticalCenter
        Label { text: Media.title; size: root.big ? 30 : root.small ? 18 : 22; w: 700; font.letterSpacing: -.3; width: parent.width }
        Label { text: Media.artist || (Media.present ? "" : "Плееров нет"); size: 14; w: 550; dim: true; width: parent.width; topPadding: 2 }
        Item { width: 1; height: 10 }
        WavyProgress {
            width: parent.width; height: 28
            visible: Media.present
            value: Media.length > 0 ? Media.position / Media.length : 0
            waving: Media.playing
            onSeek: f => Media.seek(f)
        }
        Item {
            width: parent.width; height: 16
            visible: Media.present
            Label { text: Media.fmt(Media.position); size: 12; w: 650; dim: true; font.features: { "tnum": 1 } }
            Label { anchors.right: parent.right; text: Media.fmt(Media.length); size: 12; w: 650; dim: true; font.features: { "tnum": 1 } }
        }
        Row {
            spacing: 8
            topPadding: 8
            Ctl { icon: "skip_previous"; onClicked: Media.prev() }
            Rectangle {
                readonly property real bw: root.small ? 60 : 76
                width: (Media.playing ? bw - 8 : bw) + (pm.containsMouse ? 8 : 0); height: root.small ? 44 : 56
                radius: Media.playing ? (root.small ? 14 : 18) : height / 2
                color: Theme.primary
                scale: pm.pressed ? .9 : 1
                anchors.verticalCenter: parent.verticalCenter
                Behavior on width { SpringAnim { ms: 450 } }
                Behavior on radius { SpringAnim { ms: 450 } }
                Behavior on scale { SpringAnim { ms: 350 } }
                MIcon { anchors.centerIn: parent; text: Media.playing ? "pause" : "play_arrow"; fill: true; size: root.small ? 26 : 30; color: Theme.fgPrimary }
                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; onClicked: Media.toggle() }
            }
            Ctl { icon: "skip_next"; onClicked: Media.next() }
        }
    }

    component Ctl: Rectangle {
        id: c
        property string icon
        signal clicked
        width: root.small ? 40 : 48; height: width
        radius: cm.containsMouse ? width / 3 : width / 2
        color: Theme.surfaceHighest
        scale: cm.pressed ? .88 : 1
        anchors.verticalCenter: parent.verticalCenter
        Behavior on radius { SpringAnim { ms: 350 } }
        Behavior on scale { SpringAnim { ms: 350 } }
        MIcon { anchors.centerIn: parent; text: c.icon; fill: true; size: 24 }
        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onClicked: c.clicked() }
    }
}

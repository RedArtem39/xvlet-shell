import QtQuick
import QtQuick.Effects
import qs.services

// What plays, as a card: the cover (a cookie while paused, a circle while
// it plays), the title, the artist, the wavy progress (press it to seek),
// the times, the controls -- the play button a pill that tightens while
// playing. Nothing: says so.
Item {
    id: root
    property real art: 132
    property bool big: false

    implicitHeight: Math.max(art, col.implicitHeight)

    Item {
        id: cover
        width: root.art; height: root.art
        MShape {
            id: coverShape
            anchors.fill: parent
            shape: Media.playing ? Theme.shCircle : Theme.shCookie12
            color: Theme.tertiaryContainer
            layer.enabled: true
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
        MIcon { anchors.centerIn: parent; visible: img.status !== Image.Ready; text: "music_note"; fill: true; size: root.art * .38; color: Theme.fgTertiaryContainer }
    }
    Column {
        id: col
        x: root.art + 18
        width: root.width - x
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Label { text: Media.title; size: root.big ? 30 : 22; w: Font.Bold; width: parent.width }
        Label { text: Media.artist || (Media.present ? "" : "Плееров нет"); size: 14; w: Font.Medium; dim: true; width: parent.width }
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
            Label { text: Media.fmt(Media.position); size: 12; dim: true }
            Label { anchors.right: parent.right; text: Media.fmt(Media.length); size: 12; dim: true }
        }
        Row {
            spacing: 8
            topPadding: 6
            IconButton { icon: "skip_previous"; fill: true; size: 48; onClicked: Media.prev() }
            Rectangle {
                width: Media.playing ? 68 : 76; height: 56
                radius: Media.playing ? 18 : 28
                color: Media.present ? Theme.primary : Theme.surfaceHighest
                Behavior on width { SpringAnim {} }
                Behavior on radius { SpringAnim {} }
                MIcon { anchors.centerIn: parent; text: Media.playing ? "pause" : "play_arrow"; fill: true; size: 30; color: Media.present ? Theme.fgPrimary : Theme.fgSurfaceVar }
                MouseArea { anchors.fill: parent; onClicked: Media.toggle() }
            }
            IconButton { icon: "skip_next"; fill: true; size: 48; onClicked: Media.next() }
        }
    }
}

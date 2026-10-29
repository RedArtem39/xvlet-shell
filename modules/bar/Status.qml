import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.components
import qs.services

// Sound and battery in one pill (the quick settings open from it): the
// default sink's volume from PipeWire -- the wheel turns it -- and the
// battery's charge from sysfs. What the machine does not have is not shown.
Rectangle {
    id: root
    signal clicked

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    property int battery: -1

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    FileView {
        id: bat
        path: "/sys/class/power_supply/BAT0/capacity"
        onLoaded: root.battery = parseInt(text()) || -1
        onLoadFailed: root.battery = -1
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: bat.reload() }

    implicitWidth: row.implicitWidth + 28
    implicitHeight: 40
    radius: area.containsMouse ? 14 : 20
    color: area.containsMouse ? Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, .1) : "transparent"
    Behavior on radius { NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spring } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        MIcon {
            visible: !!root.sink
            text: root.muted || root.vol <= 0 ? "volume_off" : root.vol < .34 ? "volume_mute" : root.vol < .67 ? "volume_down" : "volume_up"
            fill: true
            size: 20
        }
        Row {
            visible: root.battery >= 0
            spacing: 4
            MIcon {
                text: root.battery > 85 ? "battery_full" : "battery_" + Math.max(0, Math.round(root.battery / 100 * 6)) + "_bar"
                fill: true
                size: 20
            }
            Text {
                text: root.battery + "%"
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.onSurface
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Text {
            // nothing to show at all: say so, as the shell does for what is missing
            visible: !root.sink && root.battery < 0
            text: "нет звука"
            font.family: Theme.font
            font.pixelSize: 13
            color: Theme.onSurfaceVar
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
    WheelHandler {
        enabled: !!root.sink
        onWheel: e => { if (root.sink && root.sink.audio) root.sink.audio.volume = Math.max(0, Math.min(1, root.vol + (e.angleDelta.y > 0 ? .05 : -.05))); }
    }
}

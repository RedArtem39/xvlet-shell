import QtQuick
import qs.services

// The prototype's range (.sl / .srange): a track 40 px thick (16 if thin),
// primary up to the value, a narrow handle 52 px tall cut out of the track
// by a ring of the card's colour; the icon before it, the number after.
// value 0..1.
Item {
    id: root
    property real value: 0
    property string icon: ""
    property bool showValue: true
    property bool thin: false
    property string suffix: ""
    property string valueText: ""         // (instead of the percentage)
    property real valueWidth: 42
    property color ring: Theme.surfaceMid   // (what the slider sits on)
    signal moved(real v)

    implicitWidth: 240
    implicitHeight: thin ? 28 : 52
    opacity: enabled ? 1 : .38

    Row {
    anchors.fill: parent
    spacing: 12

    MIcon {
        visible: root.icon !== ""
        width: 28
        text: root.icon; size: 24
        color: Theme.fgSurfaceVar
        anchors.verticalCenter: parent.verticalCenter
    }
    Item {
        id: box
        width: root.width - (root.icon !== "" ? 40 : 0) - (root.showValue ? root.valueWidth + 12 : 0)
        height: root.implicitHeight
        anchors.verticalCenter: parent.verticalCenter
        readonly property real th: root.thin ? 16 : 40
        readonly property real p: width * Math.max(0, Math.min(1, root.value))

        Rectangle {
            width: parent.width; height: box.th; radius: box.th / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.surfaceHighest
            // the active part: primary up to the handle (a hard stop, as
            // the prototype's gradient)
            Item {
                width: box.p; height: parent.height
                clip: true
                Rectangle { width: box.width; height: box.th; radius: box.th / 2; color: Theme.primary }
            }
        }
        Rectangle {
            // the handle, its ring
            x: Math.max(0, Math.min(box.width - 6, box.p - 3)) - 5
            width: 16; height: (root.thin ? 28 : 52) + 10; radius: 8
            anchors.verticalCenter: parent.verticalCenter
            color: root.ring
            Rectangle { anchors.centerIn: parent; width: 6; height: parent.height - 10; radius: 3; color: Theme.primary }
        }
        MouseArea {
            anchors.fill: parent
            enabled: root.enabled
            // a tick for every step of 5 % passed (as Serpantinum's draggables)
            property int step: -1
            function at(x) {
                const v = Math.max(0, Math.min(1, x / box.width)), s = Math.round(v * 20);
                if (s !== step) { if (step >= 0) Sfx.ui("tick"); step = s; }
                root.moved(v);
            }
            onReleased: step = -1
            onPressed: e => at(e.x)
            onPositionChanged: e => { if (pressed) at(e.x); }
        }
        WheelHandler { enabled: root.enabled; onWheel: e => { Sfx.ui("tick"); root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? .05 : -.05)))); } }
    }
    Label {
        visible: root.showValue
        width: root.valueWidth
        horizontalAlignment: Text.AlignRight
        text: root.valueText !== "" ? root.valueText : Math.round(root.value * 100) + root.suffix
        size: 13; w: Font.Bold; dim: true
        font.features: { "tnum": 1 }
        anchors.verticalCenter: parent.verticalCenter
    }
}
}

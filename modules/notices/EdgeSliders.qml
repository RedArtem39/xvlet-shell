import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

// The right edge's sliders (as Caelestia's): the pointer at the middle of
// the right edge, on an empty desktop, and two tall pills roll out -- the
// volume and the brightness (the latter only with a backlight) -- dragged,
// clicked or wheeled; they roll back a moment after the pointer leaves.
// Over windows nothing comes: the edge is theirs then.
PanelWindow {
    id: root

    readonly property var bcfg: Config.data.bar
    readonly property real barThick: (bcfg.style === "islands" || bcfg.style === "solid") ? bcfg.height + 10 : bcfg.height
    readonly property var dcfg: Config.data.dock
    // which edge: the right one, unless the bar or the dock is there --
    // then the left; both taken, the right, out of the inner side of what
    // is there (the pointer at the screen's edge would be over the bar)
    function taken(e) { return bcfg.pos === e || (dcfg.on && dcfg.pos === e); }
    readonly property string side: !taken("right") ? "right" : !taken("left") ? "left" : "right"
    readonly property real edgeIn: (bcfg.pos === side ? barThick : 0) + (dcfg.on && dcfg.pos === side ? dcfg.size + 32 : 0)
    readonly property real dir: side === "right" ? 1 : -1
    // (an empty desktop, nothing else open)
    readonly property bool allowed: Ui.deskLive && !Ui.editing && !Ui.anyOpen && !Ui.locked
    property bool open: false
    readonly property var pills: Brightness.present ? ["volume", "brightness"] : ["volume"]

    visible: allowed || open
    WlrLayershell.namespace: "xvlet-edge"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; right: side === "right"; left: side === "left" }
    margins { right: side === "right" ? edgeIn : 0; left: side === "left" ? edgeIn : 0 }
    color: "transparent"
    implicitWidth: body.width + 28
    // only the edge's strip takes the pointer until the pills are out
    mask: Region { item: root.open ? sheet : trigger }

    onAllowedChanged: if (!allowed) open = false
    Connections { target: Ui; function onEdgePeekChanged() { root.open = Ui.edgePeek === "sliders" && root.allowed; } }
    onOpenChanged: Ui.edgeOpen = open

    Item {
        id: trigger
        x: root.side === "right" ? parent.width - width : 0
        // (the middle half of the edge)
        y: parent.height / 4
        width: 6; height: parent.height / 2
        HoverHandler { onHoveredChanged: if (hovered && root.allowed) { root.open = true; closeLater.stop(); } }
    }
    Timer { id: closeLater; interval: 700; onTriggered: root.open = false }

    // the sheet they sit on: against the screen's edge, rounded inside only,
    // coming out from behind the edge
    Rectangle {
        id: sheet
        x: root.side === "right" ? parent.width - width : 0
        y: body.y - 12
        width: body.width + 24; height: body.height + 24
        color: Theme.surfaceLow
        topLeftRadius: root.side === "right" ? Theme.r : 0; bottomLeftRadius: topLeftRadius
        topRightRadius: root.side === "left" ? Theme.r : 0; bottomRightRadius: topRightRadius
        opacity: body.opacity
        visible: body.visible
        transform: Translate { x: root.open ? 0 : sheet.width * root.dir; Behavior on x { SmoothAnim { ms: 380 } } }
        HoverHandler { onHoveredChanged: if (hovered) closeLater.stop(); else closeLater.restart() }
    }
    Row {
        id: body
        x: root.side === "right" ? parent.width - width - 12 : 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        opacity: root.open ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { SmoothAnim { ms: 220 } }
        transform: Translate { x: root.open ? 0 : sheet.width * root.dir; Behavior on x { SmoothAnim { ms: 380 } } }

        Repeater {
            model: root.pills
            Rectangle {
                id: pill
                required property string modelData
                readonly property bool vol: modelData === "volume"
                readonly property real v: vol ? Audio.volume : Brightness.value
                function put(y) {
                    const t = Math.max(0, Math.min(1, 1 - (y - track.y) / track.height));
                    if (vol) Audio.setVolume(t); else Brightness.set(Math.max(.02, t));
                }
                width: 64; height: 300; radius: 32
                color: Theme.surfaceMid
                MIcon {
                    anchors.horizontalCenter: parent.horizontalCenter; y: 14
                    text: pill.vol ? Audio.icon : "light_mode"; fill: true; size: 24; color: Theme.fgSurfaceVar
                }
                Rectangle {
                    id: track
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 48; width: 48; height: parent.height - 48 - 34
                    radius: 24
                    color: Theme.surfaceHigh
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: Math.max(24, parent.height * pill.v)
                        topLeftRadius: 8; topRightRadius: 8; bottomLeftRadius: 24; bottomRightRadius: 24
                        color: Theme.primary
                        Behavior on height { SmoothAnim { ms: 160 } }
                    }
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                    text: Math.round(pill.v * 100); size: 13; w: 750; font.features: { "tnum": 1 }
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: e => pill.put(e.y)
                    onPositionChanged: e => { if (pressed) pill.put(e.y); }
                    onWheel: w => { if (pill.vol) Audio.step(w.angleDelta.y > 0 ? .05 : -.05); else Brightness.step(w.angleDelta.y > 0 ? .05 : -.05); }
                    onDoubleClicked: if (pill.vol) Audio.toggleMute()
                }
            }
        }
    }
}

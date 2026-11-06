import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services
import "../desk"

// The other edge's system panel (Serpantinum's "system usage" quick
// action, in the desktop widgets' own faces): the pointer at the middle of
// the edge opposite the sliders (EdgeSliders.qml), on an empty desktop, and
// the machine's numbers roll out -- the processor, the memory, the
// temperature as liquid rounds, the disk and the battery as liquid bars.
PanelWindow {
    id: root

    readonly property var bcfg: Config.data.bar
    readonly property var dcfg: Config.data.dock
    readonly property real barThick: (bcfg.style === "islands" || bcfg.style === "solid") ? bcfg.height + 10 : bcfg.height
    function taken(e) { return bcfg.pos === e || (dcfg.on && dcfg.pos === e); }
    // the sliders' edge (the same rule as theirs), and this one the other
    readonly property string sliders: !taken("right") ? "right" : !taken("left") ? "left" : "right"
    readonly property string side: sliders === "right" ? "left" : "right"
    readonly property real edgeIn: (bcfg.pos === side ? barThick : 0) + (dcfg.on && dcfg.pos === side ? dcfg.size + 32 : 0)
    readonly property real dir: side === "right" ? 1 : -1
    readonly property bool allowed: Ui.deskLive && !Ui.editing && !Ui.anyOpen && !Ui.locked
    property bool open: false

    visible: allowed || open
    WlrLayershell.namespace: "xvlet-edge-system"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors { right: side === "right"; left: side === "left" }
    margins { right: side === "right" ? edgeIn : 0; left: side === "left" ? edgeIn : 0 }
    color: "transparent"
    implicitWidth: card.width + 28
    implicitHeight: card.height + 40
    mask: Region { item: root.open ? card : trigger }

    onAllowedChanged: if (!allowed) open = false
    Connections { target: Ui; function onEdgePeekChanged() { root.open = Ui.edgePeek === "system" && root.allowed; } }

    Item {
        id: trigger
        x: root.side === "right" ? parent.width - width : 0
        width: 6; height: parent.height
        HoverHandler { onHoveredChanged: if (hovered && root.allowed) { root.open = true; closeLater.stop(); } }
    }
    Timer { id: closeLater; interval: 700; onTriggered: root.open = false }

    Rectangle {
        id: card
        width: 384; height: 276
        x: root.side === "right" ? parent.width - width - 14 : 14
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.r
        color: Theme.surfaceLow
        border.width: 1; border.color: Theme.alpha(Theme.fgSurface, .06)
        opacity: root.open ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { SmoothAnim { ms: 220 } }
        transform: Translate { x: root.open ? 0 : 60 * root.dir; Behavior on x { SmoothAnim { ms: 380 } } }
        HoverHandler { onHoveredChanged: if (hovered) closeLater.stop(); else closeLater.restart() }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10
            Row {
                spacing: 10
                Repeater {
                    model: ["cpu", "ram", "temp"]
                    Face { required property string modelData; t: modelData; v: "wave"; width: 110; height: 110 }
                }
            }
            Row {
                spacing: 10
                Face { t: "disk"; v: "bar"; width: 173; height: 96 }
                Face { t: "battery"; v: "bar"; width: 173; height: 96 }
            }
            Label {
                text: Sys.diskText ? "Диск: " + Sys.diskText : ""
                size: 11.5; dim: true
                leftPadding: 4
            }
        }
    }
}

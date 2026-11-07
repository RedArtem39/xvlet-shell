import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services
import "../desk"

// The other edge's system panel (Serpantinum's "system usage" quick
// action): the pointer at the middle of the edge opposite the sliders
// (EdgeSliders.qml), on an empty desktop, and a short list rolls out -- who
// and how long up, then the processor, the memory, the temperature, the
// disk, the battery: an icon, a detail, the number, a slim level.
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
    anchors { top: true; bottom: true; right: side === "right"; left: side === "left" }
    margins { right: side === "right" ? edgeIn : 0; left: side === "left" ? edgeIn : 0 }
    color: "transparent"
    implicitWidth: card.width + 28
    // open: the whole window (a region following the card was never
    // taken as changed by Zerp: EdgeSliders.qml)
    mask: Region { item: root.open ? whole : trigger }
    Item { id: whole; anchors.fill: parent }

    onAllowedChanged: if (!allowed) open = false
    Connections { target: Ui; function onEdgePeekChanged() { root.open = Ui.edgePeek === "system" && root.allowed; } }

    Item {
        id: trigger
        x: root.side === "right" ? parent.width - width : 0
        // (the middle half of the edge)
        y: parent.height / 4
        width: 6; height: parent.height / 2
        HoverHandler { onHoveredChanged: if (hovered && root.allowed) { root.open = true; closeLater.stop(); idle.restart(); } }
    }
    Timer { id: closeLater; interval: 1500; onTriggered: root.open = false }
    Timer { id: idle; interval: 5000; onTriggered: root.open = false }

    Rectangle {
        id: card
        width: 316; height: list.implicitHeight + 24
        // against the screen's edge, rounded inside only
        x: root.side === "right" ? parent.width - width : 0
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.surfaceLow
        topLeftRadius: root.side === "right" ? Theme.r : 0; bottomLeftRadius: topLeftRadius
        topRightRadius: root.side === "left" ? Theme.r : 0; bottomRightRadius: topRightRadius
        opacity: root.open ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { SmoothAnim { ms: 220 } }
        transform: Translate { x: root.open ? 0 : card.width * root.dir; Behavior on x { SmoothAnim { ms: 380 } } }
        // the concave corners where it meets the screen's edge (as the
        // bar's segments)
        Fillet { size: Theme.r; color: parent.color; x: root.side === "right" ? parent.width - size : 0; y: -size; hole: root.side === "right" ? "tl" : "tr" }
        Fillet { size: Theme.r; color: parent.color; x: root.side === "right" ? parent.width - size : 0; y: parent.height; hole: root.side === "right" ? "bl" : "br" }
        // out of the way again: the pointer gone from it (or, if the
        // compositor never says it left, still for a while)
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
            onPositionChanged: { closeLater.stop(); idle.restart(); }
            onEntered: { closeLater.stop(); idle.restart(); }
            onExited: closeLater.restart()
        }

        // a short list (Serpantinum's "system usage"): who, how long up,
        // then each number -- an icon chip, the name and a detail, the
        // number, a slim level
        Column {
            id: list
            x: 12; y: 12
            width: parent.width - 24
            spacing: 4
            Row {
                spacing: 12; leftPadding: 6; bottomPadding: 6; topPadding: 2
                Rectangle {
                    width: 44; height: 44; radius: 16; color: Theme.tertiaryContainer
                    MIcon { anchors.centerIn: parent; text: "computer"; fill: true; size: 22; color: Theme.fgTertiaryContainer }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Label { text: Quickshell.env("USER") || "wynland"; size: 15; w: 750 }
                    Label { text: root.uptime ? "работает " + root.uptime : "WynlandOS"; size: 12; dim: true }
                }
            }
            Repeater {
                model: [
                    { t: "cpu", i: "memory", n: "Процессор" },
                    { t: "ram", i: "memory_alt", n: "Память" },
                    { t: "temp", i: "device_thermostat", n: "Температура" },
                    { t: "disk", i: "hard_drive", n: "Диск" },
                    { t: "battery", i: "battery_5_bar", n: "Батарея" }
                ]
                Rectangle {
                    id: it
                    required property var modelData
                    readonly property string t: modelData.t
                    // the level 0..1, the number, the detail; -1: none here
                    readonly property real v: t === "cpu" ? Sys.cpu : t === "ram" ? Sys.ram : t === "disk" ? Sys.disk
                        : t === "temp" ? (Sys.temp < 0 ? -1 : Math.min(1, Sys.temp / 100)) : (Power.present ? Power.capacity / 100 : -1)
                    readonly property string num: v < 0 ? "нет" : t === "temp" ? Math.round(Sys.temp) + "°" : Math.round(v * 100) + "%"
                    readonly property string detail: t === "cpu" ? (Sys.cores ? Sys.cores + " ядер" : "")
                        : t === "ram" ? Sys.ramUsedGb.toFixed(1).replace(".", ",") + " из " + Sys.ramTotalGb.toFixed(0) + " ГБ"
                        : t === "disk" ? Sys.diskText
                        : t === "temp" ? (Sys.temp < 0 ? "датчика нет" : "процессор")
                        : Power.present ? (Power.charging ? "заряжается" : "от батареи") : "батареи нет"
                    readonly property bool hot: t === "temp" && Sys.temp > 75
                    width: list.width; height: 62; radius: 18
                    color: Theme.surfaceMid
                    Rectangle {
                        x: 10; anchors.verticalCenter: parent.verticalCenter
                        width: 36; height: 36; radius: 12
                        color: it.t === "temp" ? Theme.tertiaryContainer : Theme.secondaryContainer
                        MIcon { anchors.centerIn: parent; text: it.t === "battery" ? Power.icon : it.modelData.i; fill: true; size: 20
                                color: it.t === "temp" ? Theme.fgTertiaryContainer : Theme.fgSecondaryContainer }
                    }
                    Column {
                        x: 58; y: 10
                        Label { text: it.modelData.n; size: 13; w: 700 }
                        Label { text: it.detail; size: 11; dim: true }
                    }
                    Label { anchors.right: parent.right; anchors.rightMargin: 12; y: 12; text: it.num; size: 16; w: 800; font.features: { "tnum": 1 } }
                    Rectangle {
                        x: 58; y: parent.height - 14; width: parent.width - 58 - 12; height: 6; radius: 3
                        color: Theme.surfaceHighest
                        Rectangle {
                            height: parent.height; radius: 3
                            width: parent.width * Math.max(0, it.v)
                            color: it.hot ? Theme.error : Theme.primary
                            Behavior on width { SmoothAnim { ms: 700 } }
                        }
                    }
                }
            }
        }
    }

    property string uptime: ""
    Cat {
        id: up
        path: "/proc/uptime"
        onLoaded: t => { const x = parseFloat(t), h = Math.floor(x / 3600), m = Math.floor(x % 3600 / 60); root.uptime = (h ? h + " ч " : "") + m + " мин"; }
    }
    Timer { interval: 30000; running: root.open; repeat: true; triggeredOnStart: true; onTriggered: up.reload() }
}

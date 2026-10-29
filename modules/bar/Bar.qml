import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

// The bar, built from the settings: its pieces (modules) in three zones --
// start, centre, end -- on any edge, in one of three styles (Exo's):
//   islands   floating zones of glass, a gap from the edge
//   flush     one surface strip, flush with the edge (the frame's)
//   seg       zones hanging from the edge, concave fillets where they meet it
// Its thickness is kept free of windows.
PanelWindow {
    id: root

    readonly property var bcfg: Config.data.bar
    readonly property string pos: bcfg.pos
    readonly property bool vert: pos === "left" || pos === "right"
    readonly property real bh: bcfg.height
    readonly property bool islands: bcfg.style === "islands"
    readonly property real thick: islands ? bh + 10 : bh
    readonly property var order: ["logo", "ws", "tasks", "media", "tray", "sysmon", "weather", "status", "bell", "clock", "power"]
    function keys(z) { return order.filter(k => bcfg.mods[k] === z); }

    WlrLayershell.namespace: "xvlet-bar"
    WlrLayershell.layer: WlrLayer.Top
    color: "transparent"
    anchors { top: pos !== "bottom"; bottom: pos !== "top"; left: pos !== "right"; right: pos !== "left" }
    implicitHeight: vert ? 0 : thick
    implicitWidth: vert ? thick : 0
    exclusiveZone: thick

    // the strip (flush): the bar is the frame's edge
    Rectangle {
        anchors.fill: parent
        visible: root.bcfg.style === "flush"
        color: Theme.surface
        Behavior on color { ColorAnim {} }
    }

    Item {
        id: lane
        // where the zones sit: inside the gap for islands
        x: root.vert ? (root.islands ? (root.pos === "left" ? 10 : 0) : 0) : (root.islands ? 12 : 0)
        y: root.vert ? (root.islands ? 12 : 0) : (root.islands ? (root.pos === "top" ? 10 : 0) : 0)
        width: root.vert ? root.bh : root.width - (root.islands ? 24 : 0)
        height: root.vert ? root.height - (root.islands ? 24 : 0) : root.bh

        Zone { id: zs; bar: root; which: "start" }
        Zone { id: zc; bar: root; which: "center" }
        Zone { id: ze; bar: root; which: "end" }
    }

    // a zone: its modules in a row (a column on a side bar)
    component Zone: Item {
        id: zone
        required property var bar
        required property string which
        readonly property var ks: bar.keys(which)
        readonly property bool empty: ks.length === 0
        readonly property real along: bar.vert ? grid.implicitHeight + 12 : grid.implicitWidth + 12
        readonly property real fil: bar.bh * .42                  // the seg style's fillet
        readonly property bool seg: bar.bcfg.style === "seg"
        readonly property real pad: seg ? (which === "center" ? 10 : 12) : 6

        visible: !empty
        width: bar.vert ? bar.bh : along + (seg ? pad * 2 - 12 : 0)
        height: bar.vert ? along + (seg ? pad * 2 - 12 : 0) : bar.bh
        x: bar.vert ? 0 : which === "start" ? 0 : which === "end" ? lane.width - width : (lane.width - width) / 2
        y: !bar.vert ? 0 : which === "start" ? 0 : which === "end" ? lane.height - height : (lane.height - height) / 2

        // islands: a glass pill; seg: the surface, rounded away from the edge
        Rectangle {
            id: bg
            anchors.fill: parent
            visible: zone.bar.bcfg.style !== "flush"
            color: zone.seg ? Theme.surface : Theme.glass
            radius: zone.seg ? zone.fil : zone.bar.bh / 2
            Behavior on color { ColorAnim {} }
            // seg: the corners on the edge's side are square (covered)
            Rectangle {
                visible: zone.seg
                color: parent.color
                x: zone.bar.pos === "right" ? parent.width - width : 0
                y: zone.bar.pos === "bottom" ? parent.height - height : 0
                width: zone.bar.vert ? zone.fil : parent.width
                height: zone.bar.vert ? parent.height : zone.fil
            }
        }
        // seg: concave fillets where the zone meets the edge (and the
        // screen's corner for the start and end zones)
        Fillet { visible: zone.seg; bar: zone.bar; zone: zone; side: 0 }
        Fillet { visible: zone.seg; bar: zone.bar; zone: zone; side: 1 }

        Grid {
            id: grid
            anchors.centerIn: parent
            columns: zone.bar.vert ? 1 : 64
            rows: zone.bar.vert ? 64 : 1
            spacing: 2
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter
            Repeater {
                model: zone.ks
                Loader {
                    required property string modelData
                    property bool vert: zone.bar.vert
                    property string barPos: zone.bar.pos
                    source: ({ logo: "Logo.qml", ws: "Workspaces.qml", tasks: "Tasks.qml", media: "MediaMod.qml", tray: "Tray.qml",
                               sysmon: "SysMon.qml", weather: "WeatherMod.qml", status: "Status.qml", bell: "Bell.qml",
                               clock: "Clock.qml", power: "PowerBtn.qml" })[modelData]
                    onLoaded: { if (item.vert !== undefined) item.vert = Qt.binding(() => vert); }
                }
            }
        }
    }

    // a concave quarter-circle of the surface, beside a hanging zone
    component Fillet: Canvas {
        id: f
        required property var bar
        required property var zone
        required property int side            // 0: before the zone, 1: after it
        readonly property real fil: zone.fil
        width: fil; height: fil
        readonly property string p: bar.pos
        x: bar.vert ? (p === "left" ? 0 : zone.width - fil) : (side === 0 ? -fil : zone.width)
        y: bar.vert ? (side === 0 ? -fil : zone.height) : (p === "top" ? 0 : zone.height - fil)
        property color c: Theme.surface
        onCChanged: requestPaint()
        onPaint: {
            const g = getContext("2d"); g.reset();
            // the corner of this square that touches the edge and the zone
            // stays; a circle around the opposite corner is cut away
            const ex = bar.vert ? (p === "left" ? 0 : fil) : (side === 0 ? fil : 0);
            const ey = bar.vert ? (side === 0 ? fil : 0) : (p === "top" ? 0 : fil);
            g.fillStyle = c; g.fillRect(0, 0, fil, fil);
            g.globalCompositeOperation = "destination-out";
            g.beginPath(); g.arc(fil - ex, fil - ey, fil, 0, Math.PI * 2); g.fill();
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

// The desktop's widgets: above the wallpaper, under the windows. In edit
// mode (the quick settings' tile, Settings: Рабочий стол) they move, grow
// from a corner -- on the 24 px grid, sticking to the others' sizes --
// turn by a handle (snapping to 15°), and the selected one gets a toolbar
// (its face, its opacity, remove); the gallery at the bottom adds.
PanelWindow {
    id: root

    WlrLayershell.namespace: "xvlet-desktop"
    WlrLayershell.layer: Ui.editing ? WlrLayer.Overlay : WlrLayer.Bottom
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: Ui.editing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    readonly property var list: Config.data.desk.widgets || []
    property int sel: -1
    readonly property real gridStep: 24
    function snap(v) { return Config.data.desk.grid ? Math.round(v / gridStep) * gridStep : Math.round(v); }
    function put(i, w) { const l = list.slice(); l[i] = w; Config.set("desk.widgets", l); }
    // (the screen the widgets were laid out for is 1920 x 1080: scale)
    readonly property real k: Math.min(width / 1920, height / 1080)

    Rectangle {
        // edit mode: the work area dims, a grid shows
        anchors.fill: parent
        visible: Ui.editing
        color: Theme.alpha(Theme.scrim, .4)
        Canvas {
            anchors.fill: parent
            visible: Config.data.desk.grid
            property color c: Theme.alpha(Theme.fgSurface, .08)
            onPaint: { const g = getContext("2d"); g.reset(); g.fillStyle = c; for (let x = 0; x < width; x += root.gridStep * root.k) for (let y = 0; y < height; y += root.gridStep * root.k) g.fillRect(x, y, 2, 2); }
        }
        MouseArea { anchors.fill: parent; onClicked: root.sel = -1 }
    }

    Repeater {
        model: root.list
        Item {
            id: wg
            required property var modelData
            required property int index
            readonly property var w: modelData
            readonly property bool picked: Ui.editing && root.sel === index
            x: w.x * root.k; y: w.y * root.k
            width: w.w * root.k; height: w.h * root.k
            rotation: w.r || 0
            opacity: w.op === undefined ? 1 : w.op
            Face { anchors.fill: parent; t: wg.w.t; v: wg.w.v; enabled: !Ui.editing }

            Rectangle {
                // the edit outline
                anchors.fill: parent; anchors.margins: -6
                visible: Ui.editing
                color: "transparent"; radius: Theme.r
                border.width: 2
                border.color: wg.picked ? Theme.primary : Theme.alpha(Theme.primary, .5)
            }
            MouseArea {
                // move
                anchors.fill: parent
                enabled: Ui.editing
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                property point p0
                property point o0
                onPressed: e => { root.sel = wg.index; p0 = mapToItem(null, e.x, e.y); o0 = Qt.point(wg.w.x, wg.w.y); }
                onPositionChanged: e => {
                    if (!pressed) return;
                    const p = mapToItem(null, e.x, e.y);
                    wg.x = root.snap(o0.x + (p.x - p0.x) / root.k) * root.k;
                    wg.y = root.snap(o0.y + (p.y - p0.y) / root.k) * root.k;
                }
                onReleased: root.put(wg.index, Object.assign({}, wg.w, { x: Math.max(0, Math.round(wg.x / root.k)), y: Math.max(0, Math.round(wg.y / root.k)) }))
            }
            Rectangle {
                // grow from the corner: the grid, then the others' sizes pull
                visible: wg.picked
                width: 22; height: 22; radius: 11
                x: parent.width - 6; y: parent.height - 6
                color: Theme.primary; border.width: 4; border.color: Theme.surface
                MouseArea {
                    anchors.fill: parent; anchors.margins: -8
                    cursorShape: Qt.SizeFDiagCursor
                    property point p0
                    property size s0
                    onPressed: e => { p0 = mapToItem(null, e.x, e.y); s0 = Qt.size(wg.w.w, wg.w.h); }
                    onPositionChanged: e => {
                        if (!pressed) return;
                        const p = mapToItem(null, e.x, e.y);
                        let nw = Math.max(72, root.snap(s0.width + (p.x - p0.x) / root.k)), nh = Math.max(48, root.snap(s0.height + (p.y - p0.y) / root.k));
                        for (const o of root.list) { if (o === wg.w) continue; if (Math.abs(o.w - nw) < 15) nw = o.w; if (Math.abs(o.h - nh) < 15) nh = o.h; }
                        wg.width = nw * root.k; wg.height = nh * root.k;
                    }
                    onReleased: root.put(wg.index, Object.assign({}, wg.w, { w: Math.round(wg.width / root.k), h: Math.round(wg.height / root.k) }))
                }
            }
            Rectangle {
                // turn: the handle above, snapping to 15°
                visible: wg.picked
                width: 24; height: 24; radius: 12
                x: parent.width / 2 - 12; y: -46
                color: Theme.tertiary; border.width: 4; border.color: Theme.surface
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height; width: 2; height: 22; color: Theme.tertiary; opacity: .7 }
                MouseArea {
                    anchors.fill: parent; anchors.margins: -8
                    onPositionChanged: e => {
                        if (!pressed) return;
                        const c = wg.mapToItem(null, wg.width / 2, wg.height / 2), p = mapToItem(null, e.x, e.y);
                        let a = Math.round(Math.atan2(p.y - c.y, p.x - c.x) * 180 / Math.PI + 90);
                        const s = Math.round(a / 15) * 15; if (Math.abs(a - s) < 4) a = s;
                        wg.rotation = ((a + 540) % 360) - 180;
                    }
                    onReleased: root.put(wg.index, Object.assign({}, wg.w, { r: wg.rotation }))
                }
            }
        }
    }

    // the selected one's toolbar: its face, its opacity, remove
    Rectangle {
        id: tool
        readonly property var w: root.sel >= 0 ? root.list[root.sel] : null
        visible: Ui.editing && !!w
        width: tr.implicitWidth + 24; height: 56; radius: 28
        color: Theme.surfaceLow
        x: w ? Math.max(12, Math.min(root.width - width - 12, (w.x + w.w / 2) * root.k - width / 2)) : 0
        y: w ? (w.y * root.k - 80 > 60 ? w.y * root.k - 80 : (w.y + w.h) * root.k + 16) : 0
        Row {
            id: tr
            anchors.centerIn: parent; spacing: 10
            MIcon { text: tool.w ? Widgets.types[tool.w.t].i : ""; fill: true; size: 20; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
            Label { text: tool.w ? Widgets.types[tool.w.t].n : ""; size: 14; anchors.verticalCenter: parent.verticalCenter }
            Seg {
                visible: !!tool.w && Object.keys(Widgets.types[tool.w.t].v).length > 1
                model: tool.w ? Object.keys(Widgets.types[tool.w.t].v).map(k => ({ k: k, n: Widgets.types[tool.w.t].v[k] })) : []
                value: tool.w ? tool.w.v : ""
                onPicked: k => {
                    // the new face at its own size, about the same centre
                    const o = tool.w, s = Widgets.sizeOf(o.t, k);
                    root.put(root.sel, Object.assign({}, o, { v: k, w: s[0], h: s[1], x: root.snap(o.x + o.w / 2 - s[0] / 2), y: root.snap(o.y + o.h / 2 - s[1] / 2) }));
                }
            }
            MIcon { text: "opacity"; size: 20; color: Theme.fgSurfaceVar; anchors.verticalCenter: parent.verticalCenter }
            MSlider { width: 120; height: 36; showValue: false; value: tool.w && tool.w.op !== undefined ? tool.w.op : 1; onMoved: v => root.put(root.sel, Object.assign({}, tool.w, { op: Math.max(.2, v) })) }
            IconButton { visible: !!tool.w && !!tool.w.r; icon: "rotate_left"; onClicked: root.put(root.sel, Object.assign({}, tool.w, { r: 0 })) }
            IconButton { icon: "delete"; tint: Theme.error; onClicked: { const l = root.list.slice(); l.splice(root.sel, 1); root.sel = -1; Config.set("desk.widgets", l); } }
        }
    }

    // the gallery: add a widget, the ready sets, done
    Rectangle {
        visible: Ui.editing
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 24
        width: gr.implicitWidth + 24; height: 116; radius: Theme.r
        color: Theme.surfaceLow
        Row {
            id: gr
            anchors.centerIn: parent; spacing: 8
            Repeater {
                model: Object.keys(Widgets.types)
                Rectangle {
                    id: ga
                    required property string modelData
                    width: 86; height: 92; radius: gm.containsMouse ? 30 : 20
                    color: gm.containsMouse ? Theme.surfaceHigh : "transparent"
                    Behavior on radius { SpringAnim {} }
                    Column { anchors.centerIn: parent; spacing: 6
                        MIcon { text: Widgets.types[ga.modelData].i; fill: true; size: 28; color: Theme.primary; anchors.horizontalCenter: parent.horizontalCenter }
                        Label { text: Widgets.types[ga.modelData].n; size: 11; width: 80; horizontalAlignment: Text.AlignHCenter } }
                    MouseArea {
                        id: gm; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            const v = Widgets.firstFace(ga.modelData), s = Widgets.sizeOf(ga.modelData, v);
                            Config.set("desk.widgets", root.list.concat([{ t: ga.modelData, v: v, x: root.snap(960 - s[0] / 2), y: root.snap(540 - s[1] / 2), w: s[0], h: s[1], op: 1 }]));
                            root.sel = root.list.length;
                        }
                    }
                }
            }
            Rectangle { width: 2; height: 70; color: Theme.outline; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                width: 110; height: 92; radius: dm.containsMouse ? 30 : Theme.rm; color: Theme.primary
                Behavior on radius { SpringAnim {} }
                Column { anchors.centerIn: parent; spacing: 4
                    MIcon { text: "check"; size: 28; color: Theme.fgPrimary; anchors.horizontalCenter: parent.horizontalCenter }
                    Label { text: "Готово"; size: 13; color: Theme.fgPrimary; anchors.horizontalCenter: parent.horizontalCenter } }
                MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; onClicked: { Ui.editing = false; root.sel = -1; } }
            }
        }
    }
    Item { focus: Ui.editing; Keys.onEscapePressed: { Ui.editing = false; root.sel = -1; } }
}

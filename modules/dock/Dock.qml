import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components
import qs.services

// The dock, as Serpantinum's: attached to the screen's edge with concave
// corners (or floating, or a strip -- a second bar), on any edge. Pinned
// apps, then running ones not pinned, then all apps. Hides by itself:
// never, when a window is on the workspace ("smart"), or always -- until
// the pointer comes to its edge. On the bar's own edge it floats beside it.
PanelWindow {
    id: root

    readonly property var dcfg: Config.data.dock
    readonly property string pos: dcfg.pos
    readonly property bool vert: pos === "left" || pos === "right"
    readonly property string style: dcfg.pos === Config.data.bar.pos ? "floating" : dcfg.style
    readonly property real ds: dcfg.size
    readonly property real rad: Theme.r
    readonly property bool strip: style === "strip"
    readonly property real thick: strip ? ds + 12 : ds + 20 + (style === "floating" ? 12 : 0)
    readonly property real barOff: dcfg.pos === Config.data.bar.pos ? (Config.data.bar.style === "islands" ? Config.data.bar.height + 10 : Config.data.bar.height) : 0

    readonly property bool busy: !!Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.toplevels.values.length > 0
    property bool hover: false
    readonly property bool hidden: !hover && !Ui.editing && (dcfg.autohide === "always" || (dcfg.autohide === "smart" && busy && !strip))

    visible: dcfg.on
    WlrLayershell.namespace: "xvlet-dock"
    WlrLayershell.layer: WlrLayer.Top
    color: "transparent"
    anchors { bottom: pos === "bottom"; top: pos === "top"; left: pos === "left"; right: pos === "right" }
    margins { bottom: pos === "bottom" ? barOff : 0; top: pos === "top" ? barOff : 0; left: pos === "left" ? barOff : 0; right: pos === "right" ? barOff : 0 }
    exclusiveZone: strip && !hidden ? thick : 0
    exclusionMode: strip ? ExclusionMode.Normal : ExclusionMode.Ignore
    // the window: the dock, its fillets, room for the zoomed icons and the tips
    implicitWidth: vert ? thick + 160 : (strip ? (screen ? screen.width : 1920) : body.width + rad * 2 + 4)
    implicitHeight: vert ? (strip ? (screen ? screen.height : 1080) : body.height + rad * 2 + 4) : thick + 70
    // only the dock (or, hidden, a strip at the edge) takes the pointer
    mask: Region { item: root.hidden ? trigger : body }

    readonly property var pinned: dcfg.apps.map(id => Apps.byId(id)).filter(a => a)
    readonly property var extra: {
        const out = [];
        for (const w of Apps.windows) { const e = Apps.entryOf(w); if (e && !dcfg.apps.includes(e.id) && !out.includes(e)) out.push(e); }
        return out;
    }

    // the edge strip that brings it back
    Item {
        id: trigger
        x: root.pos === "right" ? root.width - 6 : 0
        y: root.pos === "bottom" ? root.height - 6 : 0
        width: root.vert ? 6 : root.width
        height: root.vert ? root.height : 6
        HoverHandler { onHoveredChanged: if (hovered) root.hover = true }
    }

    Timer { id: leave; interval: 450; onTriggered: if (!bodyHover.hovered) root.hover = false }

    Item {
        id: body
        // (the pointer over it, children included, keeps the dock up)
        HoverHandler { id: bodyHover; onHoveredChanged: { if (hovered) root.hover = true; else leave.restart(); } }
        readonly property real along: (root.vert ? list.implicitHeight : list.implicitWidth) + 28
        width: root.vert ? root.thick : (root.strip ? root.width : along)
        height: root.vert ? (root.strip ? root.height : along) : root.thick
        x: root.vert ? (root.pos === "left" ? 0 : root.width - width) : (root.width - width) / 2
        y: root.vert ? (root.height - height) / 2 : (root.pos === "bottom" ? root.height - height : 0)
        // hidden: slides past the edge
        transform: Translate {
            x: root.vert ? (root.hidden ? (root.pos === "left" ? -1 : 1) * (root.thick + 4) : 0) : 0
            y: !root.vert ? (root.hidden ? (root.pos === "bottom" ? 1 : -1) * (root.thick + 4) : 0) : 0
            Behavior on x { SpringAnim { ms: 500 } }
            Behavior on y { SpringAnim { ms: 500 } }
        }

        // attached: the surface, the far corners round, fillets to the edge
        Rectangle {
            id: bg
            anchors.fill: parent
            anchors.margins: root.style === "floating" ? 6 : 0
            visible: root.style !== "strip"
            radius: root.rad
            color: root.style === "floating" ? Theme.glass : Theme.surface
            Behavior on color { ColorAnim {} }
            Rectangle {
                // the edge's side is square
                visible: root.style === "attached"
                color: parent.color
                x: root.pos === "right" ? parent.width - width : 0
                y: root.pos === "bottom" ? parent.height - height : 0
                width: root.vert ? root.rad : parent.width
                height: root.vert ? parent.height : root.rad
            }
        }
        Rectangle { anchors.fill: parent; visible: root.strip; color: Theme.surface }
        Fillet { side: 0 }
        Fillet { side: 1 }

        Grid {
            id: list
            anchors.centerIn: parent
            columns: root.vert ? 1 : 64
            spacing: root.strip ? 2 : 6
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter
            Repeater { model: root.pinned; DockItem { required property var modelData; app: modelData } }
            Sep { visible: root.extra.length > 0 }
            Repeater { model: root.extra; DockItem { required property var modelData; app: modelData } }
            Sep {}
            DockItem { app: null }
        }
    }

    // the separator (.dsep)
    component Sep: Item {
        width: root.vert ? 36 : 10; height: root.vert ? 10 : 36
        Rectangle { anchors.centerIn: parent; width: root.vert ? 36 : 2; height: root.vert ? 2 : 36; radius: 1; color: Theme.outline; opacity: .5 }
    }

    // an app in the dock: zooms under the pointer, its name in a tip, a dot
    // (a bar, focused) while it runs; a click opens or brings it up, a
    // right click pins or unpins it
    component DockItem: Item {
        id: di
        property var app
        readonly property bool all: app === null
        readonly property bool runs: !all && Apps.running(app)
        readonly property bool focused: runs && !!Hyprland.activeToplevel && Apps.entryOf(Hyprland.activeToplevel) === app
        width: root.dcfg.labels && !root.vert ? icon.width + lbl.implicitWidth + 30 : root.ds + 8
        height: root.ds + 8

        Rectangle {
            anchors.fill: parent
            visible: root.dcfg.labels
            radius: 16
            color: ma.containsMouse ? Theme.surfaceHigh : "transparent"
        }
        Item {
            id: icon
            width: root.ds; height: root.ds
            x: root.dcfg.labels && !root.vert ? 4 : 4
            y: 4
            scale: ma.pressed ? .92 : ma.containsMouse && !root.dcfg.labels ? root.dcfg.zoom : 1
            transformOrigin: root.pos === "bottom" ? Item.Bottom : root.pos === "top" ? Item.Top : root.pos === "left" ? Item.Left : Item.Right
            Behavior on scale { SpringAnim {} }
            AppIcon { anchors.fill: parent; visible: !di.all; app: di.app; size: root.ds; r: ma.containsMouse ? root.ds / 2 : root.ds * .34 }
            Rectangle {
                anchors.fill: parent; visible: di.all
                radius: ma.containsMouse ? root.ds / 2 : root.ds * .34
                color: Theme.surfaceHighest
                Behavior on radius { SpringAnim {} }
                MIcon { anchors.centerIn: parent; text: "apps"; size: root.ds * .5 }
            }
        }
        Label {
            id: lbl
            visible: root.dcfg.labels && !root.vert
            x: icon.width + 14; anchors.verticalCenter: parent.verticalCenter
            text: di.all ? "Все приложения" : di.app.name; size: 13
        }
        Rectangle {
            // running: a dot on the edge's side, a longer bar when focused
            visible: root.dcfg.inds && di.runs
            color: di.focused ? Theme.primary : Theme.fgSurfaceVar
            radius: 2
            width: root.vert ? 4 : (di.focused ? 20 : 6)
            height: root.vert ? (di.focused ? 20 : 6) : 4
            x: root.vert ? (root.pos === "left" ? 0 : parent.width - 4) : (parent.width - width) / 2
            y: root.vert ? (parent.height - height) / 2 : (root.pos === "bottom" ? parent.height - 4 : 0)
            Behavior on width { SpringAnim {} }
            Behavior on height { SpringAnim {} }
        }
        // the tip, away from the edge
        Rectangle {
            readonly property bool on: ma.containsMouse && !root.dcfg.labels
            opacity: on ? 1 : 0
            scale: on ? 1 : .9
            color: Theme.fgSurface
            radius: 14
            width: tip.implicitWidth + 28; height: tip.implicitHeight + 16
            x: root.vert ? (root.pos === "left" ? parent.width + 14 : -width - 14) : (parent.width - width) / 2
            y: root.vert ? (parent.height - height) / 2 : (root.pos === "bottom" ? -height - 14 : parent.height + 14)
            transform: Translate { y: root.vert ? 0 : parent.children.length && ma.containsMouse ? 0 : (root.pos === "bottom" ? 8 : -8); Behavior on y { SpringAnim { ms: 400 } } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale { SpringAnim { ms: 400 } }
            Label { id: tip; anchors.centerIn: parent; text: di.all ? "Все приложения" : di.app.name; size: 13; w: 650; color: Theme.surface }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: e => {
                Sfx.ui("icon");
                if (di.all) { Ui.openLauncher(); return; }
                if (e.button === Qt.RightButton) {
                    const apps = root.dcfg.apps.includes(di.app.id) ? root.dcfg.apps.filter(x => x !== di.app.id) : root.dcfg.apps.concat([di.app.id]);
                    Config.set("dock.apps", apps);
                } else Apps.launch(di.app);
            }
        }
    }

    // a concave corner of the surface where the attached dock meets the edge
    component Fillet: Canvas {
        id: f
        required property int side
        readonly property real fil: root.rad
        visible: root.style === "attached"
        width: fil; height: fil
        x: root.vert ? (root.pos === "left" ? 0 : body.width - fil) : (side === 0 ? -fil : body.width)
        y: root.vert ? (side === 0 ? -fil : body.height) : (root.pos === "bottom" ? body.height - fil : 0)
        property color c: Theme.surface
        onCChanged: requestPaint()
        onPaint: {
            const g = getContext("2d"); g.reset();
            const ex = root.vert ? (root.pos === "left" ? 0 : fil) : (side === 0 ? fil : 0);
            const ey = root.vert ? (side === 0 ? fil : 0) : (root.pos === "bottom" ? fil : 0);
            g.fillStyle = c; g.fillRect(0, 0, fil, fil);
            g.globalCompositeOperation = "destination-out";
            g.beginPath(); g.arc(fil - ex, fil - ey, fil, 0, Math.PI * 2); g.fill();
        }
    }
}

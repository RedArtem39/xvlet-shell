import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

// What opens over everything, on one screen: the bar's popouts (the
// dashboard, quick settings, the session menu), the launcher, the wallpaper
// picker, the settings. A click outside closes them, as does Esc. Shown
// only while something is open: the rest of the time it takes nothing.
PanelWindow {
    id: root

    readonly property var bcfg: Config.data.bar
    readonly property string bpos: bcfg.pos
    readonly property bool bvert: bpos === "left" || bpos === "right"
    readonly property real barThick: (bcfg.style === "islands" || bcfg.style === "solid") ? bcfg.height + 10 : bcfg.height
    readonly property bool open: Ui.anyOpen || Ui.settings

    // made once and kept: closed, it is clear and takes no pointer and no
    // keys (its surface and GPU buffers made and dropped at every popout
    // was where the laptop's widgets got eaten and the shell stalled after
    // many taps)
    visible: true
    mask: open ? whole : none
    Region { id: whole; item: root.contentItem }
    Region { id: none }
    WlrLayershell.namespace: "xvlet-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: !open ? WlrKeyboardFocus.None : Ui.launcher || Ui.settings || Ui.wallpick || Ui.pop === "session" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    // the dim behind the launcher, the session menu, the picker
    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: Ui.launcher || Ui.pop === "session" || Ui.wallpick || Ui.settings ? 1 : 0
        Behavior on opacity { SmoothAnim { ms: 300 } }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: { Ui.closeAll(); Ui.settings = false; }
    }
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: { if (Ui.wallpick) Ui.wallpick = false; else if (Ui.anyOpen) Ui.closeAll(); else Ui.settings = false; }
    }

    // where each popout's button was when it opened: its own, kept -- with
    // one shared Ui.popX, opening the quick settings moved the dashboard
    // (fading out, or hidden) over to the bell, and back, a little each time
    property real dashAt: 960
    property real qsAt: 1800
    Connections {
        target: Ui
        function onPopChanged() {
            if (Ui.pop === "dash") root.dashAt = Ui.popX;
            else if (Ui.pop === "qs") root.qsAt = Ui.popX;
        }
        function onPopXChanged() {
            if (Ui.pop === "dash") root.dashAt = Ui.popX;
            else if (Ui.pop === "qs") root.qsAt = Ui.popX;
        }
    }

    // a popout comes out of the bar at its button
    function popPos(a, w, h) {
        const m = 8, gap = barThick + 8;
        if (!bvert) return Qt.point(Math.max(m, Math.min(width - w - m, a - w / 2)), bpos === "top" ? gap : height - gap - h);
        return Qt.point(bpos === "left" ? gap : width - gap - w, Math.max(m, Math.min(height - h - m, a - h / 2)));
    }

    Dashboard { id: dash; shown: Ui.pop === "dash"; readonly property point p: root.popPos(root.dashAt, width, height); x: p.x; y: p.y; origin: root.bpos }
    QuickSettings { id: qs; shown: Ui.pop === "qs"; readonly property point p: root.popPos(root.qsAt, width, height); x: p.x; y: p.y; origin: root.bpos }
    Session { anchors.fill: parent; shown: Ui.pop === "session" }
    Launcher { anchors.fill: parent; shown: Ui.launcher }
    WallPicker { anchors.fill: parent; shown: Ui.wallpick }
    Settings { anchors.horizontalCenter: parent.horizontalCenter; y: 110; shown: Ui.settings }
}

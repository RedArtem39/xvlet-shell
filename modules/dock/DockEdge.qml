import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

// The dock's edge over the windows: an attached or floating dock lies under
// them (Dock.qml), so its own edge strip is covered too -- this thin strip,
// above the windows, brings it up when the pointer reaches the edge (the
// dock's own hover keeps it up, and lets it down again).
PanelWindow {
    id: root

    readonly property var dcfg: Config.data.dock
    readonly property string pos: dcfg.pos
    readonly property bool vert: pos === "left" || pos === "right"
    readonly property bool strip: dcfg.pos !== Config.data.bar.pos && dcfg.style === "strip"
    readonly property bool busy: !!Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.toplevels.values.length > 0

    // (only while the dock is under windows: otherwise its own strip works)
    visible: dcfg.on && !strip && busy && !Ui.dockLift && !Ui.locked
    WlrLayershell.namespace: "xvlet-dock-edge"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { bottom: pos === "bottom"; top: pos === "top"; left: pos === "left"; right: pos === "right" }
    color: "transparent"
    // the middle half of that edge
    implicitWidth: vert ? 4 : (screen ? screen.width / 2 : 960)
    implicitHeight: vert ? (screen ? screen.height / 2 : 540) : 4

    HoverHandler { onHoveredChanged: if (hovered) Ui.dockLift = true }
}

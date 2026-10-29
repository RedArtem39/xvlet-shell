import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// The bar (the prototype's "islands" style, at the top): three zones --
// the launcher and the workspaces, the middle, the status and the clock.
// Its height plus the gap is kept free of windows.
PanelWindow {
    id: root

    property real barHeight: 52
    readonly property real gap: 10

    WlrLayershell.namespace: "xvlet-bar"
    color: "transparent"
    anchors { top: true; left: true; right: true }
    implicitHeight: barHeight + gap
    exclusiveZone: barHeight + gap

    Zone {
        id: start
        barHeight: root.barHeight
        x: 12; y: root.gap
        Logo {}
        Workspaces {}
    }
    Zone {
        id: end
        barHeight: root.barHeight
        x: root.width - width - 12; y: root.gap
        Status {}
        Clock {}
    }
}

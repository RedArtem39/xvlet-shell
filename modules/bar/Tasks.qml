import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.services

// The open apps, right in the bar: one icon each, the focused one marked;
// a click brings it up. None: "нет окон".
Grid {
    id: root
    property bool vert: false
    columns: vert ? 1 : 32
    spacing: 2
    readonly property var apps: {
        const seen = [], out = [];
        for (const w of Apps.windows) { const e = Apps.entryOf(w); if (e && !seen.includes(e.id)) { seen.push(e.id); out.push(e); } }
        return out;
    }
    Label {
        visible: root.apps.length === 0
        text: "нет окон"; size: 12; dim: true
        height: 40; verticalAlignment: Text.AlignVCenter
        leftPadding: 6; rightPadding: 6
    }
    Repeater {
        model: root.apps
        Item {
            id: t
            required property var modelData
            readonly property bool focused: !!Hyprland.activeToplevel && Apps.entryOf(Hyprland.activeToplevel) === modelData
            width: 40; height: 40
            Rectangle {
                anchors.fill: parent; radius: 14
                color: t.focused ? Theme.secondaryContainer : ma.containsMouse ? Theme.alpha(Theme.fgSurface, .1) : "transparent"
            }
            AppIcon { anchors.centerIn: parent; app: t.modelData; size: 28; r: 9 }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: Apps.launch(t.modelData) }
        }
    }
}

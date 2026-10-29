import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// The wallpaper, under everything (the background layer). The picture
// later comes from the settings and gives the palette its seed.
PanelWindow {
    id: root
    property string source: "file:///usr/share/wynland/wallpapers/peaks.png"

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "xvlet-wallpaper"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.surface

    Image {
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(root.width, root.height)
    }
}

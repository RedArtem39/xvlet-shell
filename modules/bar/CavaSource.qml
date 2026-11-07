import QtQuick
import Caelestia.Services

// The sound's spectrum: cava (libcava, through Caelestia's plugin -- in the
// image beside Quickshell). Loaded by BarViz.qml through a Loader: without
// the plugin the bar's visualizer draws its own levels instead.
Item {
    id: root
    property int bars: 32
    readonly property var values: cava.values

    CavaProvider {
        id: cava
        bars: root.bars
    }
    // (the provider runs only while something holds a reference to it)
    ServiceRef {
        service: cava
    }
}

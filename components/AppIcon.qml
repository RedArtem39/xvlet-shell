import QtQuick
import qs.services

// An application's icon on a rounded square; no icon file: the app's own
// hue with a symbol (as the prototype's tiles)
Item {
    id: root
    property var app: null
    property real size: 52
    property real r: size * .34

    implicitWidth: size
    implicitHeight: size

    readonly property string src: Apps.icon(app)
    Rectangle {
        anchors.fill: parent
        radius: root.r
        visible: img.status !== Image.Ready
        color: Theme.oklch(72, .13, Apps.hue(root.app))
        Behavior on radius { SpringAnim {} }
        MIcon {
            anchors.centerIn: parent
            text: !root.app ? "apps" : (root.app.categories || []).includes("TerminalEmulator") ? "terminal"
                : (root.app.categories || []).includes("FileManager") ? "folder"
                : (root.app.categories || []).includes("WebBrowser") ? "travel_explore" : "apps"
            fill: true
            size: root.size * .52
            color: Theme.oklch(22, .06, Apps.hue(root.app))
        }
    }
    Image {
        id: img
        anchors.fill: parent
        anchors.margins: root.size * .04
        source: root.src
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        asynchronous: true
        smooth: true
        mipmap: true
    }
}

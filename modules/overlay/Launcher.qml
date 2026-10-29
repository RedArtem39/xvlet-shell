import QtQuick
import qs.components
import qs.services

// The launcher: a search field (typing goes straight there), the
// categories, the apps in a grid or a list; the arrows move, Enter opens.
// It comes from the bottom, the middle or the top (Settings: Лаунчер).
Item {
    id: root
    property bool shown: false
    property string q: ""
    property string cat: ""
    property int sel: 0
    readonly property var lcfg: Config.data.launcher
    readonly property bool grid: lcfg.view === "grid"
    readonly property var results: Apps.search(q, cat)
    readonly property int cols: grid ? 6 : 1

    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    Behavior on opacity { SmoothAnim { ms: 220 } }
    onShownChanged: if (shown) { q = ""; field.text = ""; sel = 0; cat = ""; field.forceActiveFocus(); }
    onQChanged: sel = 0
    onCatChanged: sel = 0

    function open(i) { const a = results[i]; if (a) { Ui.closeAll(); Apps.launch(a); } }

    Rectangle {
        id: box
        width: 900; height: 640
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.lcfg.pos === "top" ? 90 : root.lcfg.pos === "center" ? (parent.height - height) / 2 : parent.height - height - 90
        radius: Theme.r
        color: Theme.surfaceLow
        transform: Translate { y: root.shown ? 0 : (root.lcfg.pos === "top" ? -60 : 60); Behavior on y { SpringAnim { ms: 500 } } }
        scale: root.shown ? 1 : .94
        Behavior on scale { SpringAnim { ms: 500 } }
        MouseArea { anchors.fill: parent; onWheel: w => w.accepted = true }

        // the search
        Rectangle {
            id: search
            x: 20; y: 20; width: parent.width - 40; height: 60
            radius: field.activeFocus ? 22 : 30
            color: Theme.surfaceHigh
            Behavior on radius { SpringAnim {} }
            MIcon { x: 20; anchors.verticalCenter: parent.verticalCenter; text: root.q ? "search" : "auto_awesome"; size: 24; color: Theme.primary }
            TextInput {
                id: field
                x: 58; width: parent.width - 120; anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.font; font.pixelSize: 19; font.weight: Font.Medium
                color: Theme.fgSurface
                selectionColor: Theme.primary
                selectedTextColor: Theme.fgPrimary
                clip: true
                onTextChanged: root.q = text
                Keys.onDownPressed: root.sel = Math.min(root.results.length - 1, root.sel + root.cols)
                Keys.onUpPressed: root.sel = Math.max(0, root.sel - root.cols)
                Keys.onRightPressed: e => { if (root.grid && cursorPosition === text.length) root.sel = Math.min(root.results.length - 1, root.sel + 1); else e.accepted = false; }
                Keys.onLeftPressed: e => { if (root.grid && cursorPosition === text.length && root.sel > 0) root.sel--; else e.accepted = false; }
                Keys.onReturnPressed: root.open(root.sel)
                Keys.onEscapePressed: Ui.closeAll()
                Label { anchors.verticalCenter: parent.verticalCenter; visible: !parent.text; text: "Поиск"; size: 19; w: Font.Medium; dim: true }
            }
            IconButton {
                anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                icon: root.grid ? "view_list" : "grid_view"
                onClicked: Config.set("launcher.view", root.grid ? "list" : "grid")
            }
        }

        // the categories
        Column {
            id: cats
            x: 20; y: search.y + search.height + 16
            width: 190
            spacing: 4
            Repeater {
                model: Apps.cats
                Rectangle {
                    id: c
                    required property var modelData
                    readonly property bool on: root.cat === modelData.k
                    width: cats.width; height: 44
                    radius: on ? 22 : 14
                    color: on ? Theme.secondaryContainer : cm.containsMouse ? Theme.surfaceHigh : "transparent"
                    Behavior on radius { SpringAnim {} }
                    Row {
                        x: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                        MIcon { text: c.modelData.i; fill: c.on; size: 20; color: c.on ? Theme.fgSecondaryContainer : Theme.fgSurface }
                        Label { text: c.modelData.n; size: 14; color: c.on ? Theme.fgSecondaryContainer : Theme.fgSurface; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onClicked: root.cat = c.modelData.k }
                }
            }
        }

        // the results
        GridView {
            id: res
            x: cats.x + cats.width + 16; y: cats.y
            width: parent.width - x - 20; height: parent.height - y - 20
            clip: true
            cellWidth: root.grid ? width / 6 : width
            cellHeight: root.grid ? 132 : 60
            model: root.results
            currentIndex: root.sel
            highlightFollowsCurrentItem: false
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
            delegate: Item {
                id: d
                required property var modelData
                required property int index
                readonly property bool on: index === root.sel
                width: res.cellWidth; height: res.cellHeight
                Rectangle {
                    anchors.fill: parent; anchors.margins: 4
                    radius: d.on ? 28 : 18
                    color: d.on ? Theme.secondaryContainer : dm.containsMouse ? Theme.surfaceHigh : "transparent"
                    Behavior on radius { SpringAnim {} }
                }
                Column {
                    visible: root.grid
                    anchors.centerIn: parent; spacing: 8
                    AppIcon { app: d.modelData; size: 64; anchors.horizontalCenter: parent.horizontalCenter; scale: dm.containsMouse || d.on ? 1.06 : 1; Behavior on scale { SpringAnim {} } }
                    Label { text: d.modelData.name; size: 13; width: res.cellWidth - 16; horizontalAlignment: Text.AlignHCenter; color: d.on ? Theme.fgSecondaryContainer : Theme.fgSurface }
                }
                Row {
                    visible: !root.grid
                    x: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 14
                    AppIcon { app: d.modelData; size: 40 }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Label { text: d.modelData.name; size: 15; color: d.on ? Theme.fgSecondaryContainer : Theme.fgSurface }
                        Label { text: d.modelData.comment || d.modelData.genericName || ""; size: 12; dim: true; visible: text !== "" }
                    }
                }
                MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; onEntered: root.sel = d.index; onClicked: root.open(d.index) }
            }
            Column {
                visible: root.results.length === 0
                anchors.centerIn: parent; spacing: 10
                MShape { width: 80; height: 80; shape: Theme.shFlower; color: Theme.surfaceHigh; anchors.horizontalCenter: parent.horizontalCenter
                    MIcon { anchors.centerIn: parent; text: "search_off"; size: 34; color: Theme.fgSurfaceVar } }
                Label { text: "Ничего не нашлось"; size: 14; dim: true; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
    }
}

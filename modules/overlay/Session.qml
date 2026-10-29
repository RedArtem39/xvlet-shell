import QtQuick
import qs.components
import qs.services

// The session menu (the prototype's #session, the power button): four big
// shapes -- a cookie, a square cookie, a flower, a sun -- that turn into a
// circle in primary under the pointer (red for restart and power off); the
// arrows and Enter work too. Sleep: this system has none.
Item {
    id: root
    property bool shown: false
    property int sel: 0
    readonly property var acts: [
        { k: "lock", n: "Заблокировать", i: "lock", danger: false },
        { k: "logout", n: "Выйти", i: "logout", danger: false },
        { k: "reboot", n: "Перезагрузить", i: "restart_alt", danger: true },
        { k: "off", n: "Выключить", i: "power_settings_new", danger: true }
    ]
    readonly property var shapes: [Theme.shCookie9, Theme.shCookie4, Theme.shFlower, Theme.shSunny]
    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    Behavior on opacity { SmoothAnim { ms: 300 } }
    focus: shown
    onShownChanged: if (shown) { sel = 0; forceActiveFocus(); }
    Keys.onRightPressed: sel = (sel + 1) % 4
    Keys.onLeftPressed: sel = (sel + 3) % 4
    Keys.onReturnPressed: { Ui.closeAll(); Power.act(acts[sel].k); }
    Keys.onEscapePressed: Ui.closeAll()

    Row {
        anchors.centerIn: parent
        spacing: 22
        Repeater {
            model: root.acts
            Column {
                id: b
                required property var modelData
                required property int index
                readonly property bool on: root.sel === index
                spacing: 16
                opacity: root.shown ? 1 : 0
                scale: root.shown ? 1 : .6
                transform: Translate { y: root.shown ? 0 : 30; Behavior on y { SpringAnim { ms: 600 + b.index * 50 } } }
                Behavior on opacity { NumberAnimation { duration: Theme.ms(300 + b.index * 50) } }
                Behavior on scale { SpringAnim { ms: 600 + b.index * 50 } }
                Item {
                    width: 150; height: 150
                    anchors.horizontalCenter: parent.horizontalCenter
                    MShape {
                        id: sh
                        anchors.fill: parent
                        shape: b.on ? Theme.shCircle : root.shapes[b.index]
                        color: b.on ? (b.modelData.danger ? Theme.error : Theme.primary) : Theme.surfaceHigh
                        scale: bm.pressed ? .9 : b.on ? 1.08 : 1
                        Behavior on scale { SpringAnim { ms: 500 } }
                        Behavior on color { ColorAnim { ms: 250 } }
                    }
                    MIcon {
                        anchors.centerIn: parent; text: b.modelData.i; size: 52
                        color: b.on ? (b.modelData.danger ? Theme.oklch(20, .05, 25) : Theme.fgPrimary) : Theme.fgSurface
                        Behavior on color { ColorAnim { ms: 250 } }
                    }
                    MouseArea {
                        id: bm
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: root.sel = b.index
                        onClicked: { Ui.closeAll(); Power.act(b.modelData.k); }
                    }
                }
                Label { text: b.modelData.n; size: 16; w: 650; anchors.horizontalCenter: parent.horizontalCenter; color: Theme.oklch(97, .02, Theme.now.h) }
            }
        }
    }
    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 70
        text: "← → выбрать · Enter · Esc — отмена"
        size: 14; w: 600; color: Theme.oklch(95, .02, Theme.now.h, .7)
    }
}

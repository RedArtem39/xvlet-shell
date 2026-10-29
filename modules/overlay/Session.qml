import QtQuick
import qs.components
import qs.services

// The session menu (the power button): four big shapes in a row -- lock,
// log out, restart, power off -- that morph under the pointer; the arrows
// and Enter work too. Sleep: this system has none.
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
    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    Behavior on opacity { SmoothAnim { ms: 250 } }
    focus: shown
    onShownChanged: if (shown) { sel = 0; forceActiveFocus(); }
    Keys.onRightPressed: sel = (sel + 1) % 4
    Keys.onLeftPressed: sel = (sel + 3) % 4
    Keys.onReturnPressed: { Ui.closeAll(); Power.act(acts[sel].k); }
    Keys.onEscapePressed: Ui.closeAll()

    Row {
        anchors.centerIn: parent
        spacing: 26
        Repeater {
            model: root.acts
            Column {
                id: b
                required property var modelData
                required property int index
                readonly property bool on: root.sel === index
                spacing: 14
                scale: root.shown ? 1 : .6
                Behavior on scale { SpringAnim { ms: 500 + b.index * 60 } }
                MShape {
                    width: 140; height: 140
                    shape: b.on ? (b.modelData.danger ? Theme.shFlower : Theme.shCookie9) : Theme.shCircle
                    color: b.on ? (b.modelData.danger ? Theme.error : Theme.primary) : Theme.surfaceHigh
                    rotation: b.on ? 20 : 0
                    Behavior on rotation { SpringAnim {} }
                    MIcon {
                        anchors.centerIn: parent; text: b.modelData.i; size: 48; fill: b.on
                        color: b.on ? (b.modelData.danger ? Theme.surface : Theme.fgPrimary) : Theme.fgSurface
                        rotation: -parent.rotation
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: root.sel = b.index
                        onClicked: { Ui.closeAll(); Power.act(b.modelData.k); }
                    }
                }
                Label { text: b.modelData.n; size: 16; anchors.horizontalCenter: parent.horizontalCenter; color: b.on ? Theme.fgSurface : Theme.fgSurfaceVar }
            }
        }
    }
}

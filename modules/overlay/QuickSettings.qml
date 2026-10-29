import QtQuick
import qs.components
import qs.services

// Quick settings and the notifications (from the status pill and the
// bell): the battery, tiles, the volume and the brightness, the centre.
// What the machine has no stack for says "нет" -- Wi-Fi, Bluetooth.
Popout {
    id: root
    width: 440
    height: Math.min(780, col.implicitHeight + 36)

    Column {
        id: col
        width: parent.width
        spacing: 12

        // the head: the battery, the theme, the settings
        Item {
            width: parent.width; height: 40
            Row {
                anchors.verticalCenter: parent.verticalCenter; spacing: 8
                MIcon { text: Power.present ? Power.icon : "power"; fill: true; size: 22; color: Theme.primary }
                Label { text: Power.present ? Power.capacity + "%" + (Power.charging ? " · заряжается" : "") : "от сети · батареи нет"; size: 14; w: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
            }
            Row {
                anchors.right: parent.right
                IconButton { icon: Theme.dark ? "dark_mode" : "light_mode"; onClicked: Config.set("theme.mode", Theme.dark ? "light" : "dark") }
                IconButton { icon: "settings"; onClicked: Ui.openSettings() }
            }
        }

        Grid {
            width: parent.width
            columns: 2
            spacing: 8
            Tile { icon: "wifi_off"; name: "Wi-Fi"; sub: "нет"; enabled: false }
            Tile { icon: "bluetooth_disabled"; name: "Bluetooth"; sub: "нет"; enabled: false }
            Tile { icon: Net.icon; name: "Сеть"; sub: Net.online ? (Net.via || "подключено") : "нет"; on: Net.online }
            Tile { icon: Notifs.dnd ? "do_not_disturb_on" : "do_not_disturb_off"; name: "Не беспокоить"; sub: Notifs.dnd ? "вкл." : "выкл."; on: Notifs.dnd; onClicked: Config.set("notif.dnd", !Notifs.dnd) }
            Tile { icon: "dark_mode"; name: "Тёмная тема"; sub: Theme.dark ? "вкл." : "выкл."; on: Theme.dark; onClicked: Config.set("theme.mode", Theme.dark ? "light" : "dark") }
            Tile { icon: "widgets"; name: "Виджеты"; sub: Ui.editing ? "правка" : "на столе"; on: Ui.editing; onClicked: { Ui.editing = !Ui.editing; Ui.closeAll(); } }
        }

        Card {
            width: parent.width; height: sl.implicitHeight + 24
            Column {
                id: sl
                anchors.fill: parent; anchors.margins: 12
                spacing: 10
                MSlider { width: parent.width; icon: Audio.icon; value: Audio.volume; enabled: Audio.present; onMoved: v => Audio.setVolume(v) }
                Item {
                    width: parent.width; height: 44
                    MSlider { anchors.fill: parent; visible: Brightness.present; icon: "light_mode"; value: Brightness.value; onMoved: v => Brightness.set(v) }
                    Row {
                        visible: !Brightness.present
                        anchors.verticalCenter: parent.verticalCenter; x: 12; spacing: 10
                        MIcon { text: "light_mode"; size: 20; color: Theme.fgSurfaceVar }
                        Label { text: "Яркость: нет (у экрана нет регулировки)"; size: 13; dim: true; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }

        Item {
            width: parent.width; height: 36
            Label { text: "Уведомления"; size: 16; w: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                visible: Notifs.list.length > 0
                width: clr.implicitWidth + 28; height: 32; radius: cm.containsMouse ? 10 : 16
                color: Theme.surfaceHigh
                Behavior on radius { SpringAnim {} }
                Row { id: clr; anchors.centerIn: parent; spacing: 6
                    MIcon { text: "clear_all"; size: 18 }
                    Label { text: "Очистить"; size: 13; anchors.verticalCenter: parent.verticalCenter } }
                MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onClicked: Notifs.clear() }
            }
        }
        Item {
            width: parent.width
            height: Math.min(300, Math.max(120, nl.contentHeight))
            Column {
                visible: Notifs.list.length === 0
                anchors.centerIn: parent; spacing: 8
                MShape { width: 64; height: 64; shape: Theme.shCookie9; color: Theme.surfaceHigh; anchors.horizontalCenter: parent.horizontalCenter
                    MIcon { anchors.centerIn: parent; text: "notifications_off"; fill: true; size: 30; color: Theme.fgSurfaceVar } }
                Label { text: "Новых уведомлений нет"; size: 13; dim: true; anchors.horizontalCenter: parent.horizontalCenter }
            }
            ListView {
                id: nl
                anchors.fill: parent
                clip: true
                spacing: 8
                model: Notifs.list.slice().reverse()
                delegate: NoteCard { required property var modelData; n: modelData; width: nl.width }
                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.ms(250) } }
            }
        }
    }

    // a quick-settings tile: an icon in a shape, its name and its state
    component Tile: Rectangle {
        id: t
        property string icon
        property string name
        property string sub
        property bool on: false
        signal clicked
        width: (col.width - 8) / 2; height: 68
        radius: on ? 34 : 22
        color: on ? Theme.primary : Theme.surfaceHigh
        opacity: enabled ? 1 : .6
        Behavior on radius { SpringAnim {} }
        Behavior on color { ColorAnim { ms: 300 } }
        Row {
            anchors.verticalCenter: parent.verticalCenter; x: 14; spacing: 12
            Rectangle {
                width: 40; height: 40; radius: t.on ? 20 : 12
                color: t.on ? Theme.alpha(Theme.fgPrimary, .15) : Theme.surfaceHighest
                MIcon { anchors.centerIn: parent; text: t.icon; fill: t.on; size: 20; color: t.on ? Theme.fgPrimary : Theme.fgSurface }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label { text: t.name; size: 14; w: Font.Bold; color: t.on ? Theme.fgPrimary : Theme.fgSurface }
                Label { text: t.sub; size: 12; color: t.on ? Theme.alpha(Theme.fgPrimary, .8) : Theme.fgSurfaceVar }
            }
        }
        MouseArea { anchors.fill: parent; enabled: t.enabled; onClicked: t.clicked() }
    }
}

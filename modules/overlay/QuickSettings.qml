import QtQuick
import qs.components
import qs.services

// Quick settings and the notifications (the prototype's #qs): the battery,
// the toggles, the volume and the brightness, the centre. What the machine
// has no stack for says "нет" -- Wi-Fi, Bluetooth.
Popout {
    id: root
    width: 440
    height: Math.min(820, col.implicitHeight + 36)

    // the parts come in one after another as it opens
    onShownChanged: if (shown) for (const r of [q1, q2, q3, q4, q5, q6]) r.restart()
    Rise { id: q1; target: qHead; index: 0 }
    Rise { id: q2; target: qTiles; index: 1 }
    Rise { id: q3; target: qSliders; index: 2 }
    Rise { id: q4; target: qCentreHead; index: 3 }
    Rise { id: q5; target: qEmpty; index: 4 }
    Rise { id: q6; target: nl; index: 4 }

    Column {
        id: col
        width: parent.width
        spacing: 10

        // the head: the battery, the theme, the settings
        Item {
            id: qHead
            width: parent.width; height: 44
            Row {
                x: 4; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                MIcon { text: Power.present ? Power.icon : "power"; fill: true; size: 24; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                Label { text: Power.present ? Power.capacity + "%" + (Power.charging ? " · заряжается" : "") : "От сети · батареи нет"; size: 15; w: 700; anchors.verticalCenter: parent.verticalCenter }
            }
            Row {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                IconButton { icon: Theme.dark ? "dark_mode" : "light_mode"; onClicked: Config.set("theme.mode", Theme.dark ? "light" : "dark") }
                IconButton { icon: "settings"; onClicked: Ui.openSettings() }
            }
        }

        Grid {
            id: qTiles
            width: parent.width
            columns: 2
            spacing: 8
            Tile { icon: "wifi_off"; name: "Wi-Fi"; sub: "Нет адаптера"; dis: true }
            Tile { icon: "bluetooth_disabled"; name: "Bluetooth"; sub: "Нет адаптера"; dis: true }
            Tile { icon: Net.icon; name: "Сеть"; sub: Net.online ? (Net.via || "Подключено") : "Нет"; on: Net.online; dis: true }
            Tile { icon: "do_not_disturb_on"; name: "Не беспокоить"; sub: Notifs.dnd ? "Включено" : "Выключено"; on: Notifs.dnd; onClicked: Config.set("notif.dnd", !Notifs.dnd) }
            Tile { icon: "dark_mode"; name: "Тёмная тема"; sub: Theme.dark ? "Включена" : "Выключена"; on: Theme.dark; onClicked: Config.set("theme.mode", Theme.dark ? "light" : "dark") }
            Tile { icon: "widgets"; name: "Виджеты"; sub: Ui.editing ? "Правка" : "На столе"; on: Ui.editing; onClicked: { Ui.editing = !Ui.editing; Ui.closeAll(); } }
        }

        // the volume, the brightness
        Card {
            id: qSliders
            width: parent.width; height: sl.implicitHeight + 20
            Column {
                id: sl
                x: 18; y: 10; width: parent.width - 36
                MSlider { width: parent.width; icon: Audio.icon; value: Audio.volume; enabled: Audio.present; onMoved: v => Audio.setVolume(v) }
                MSlider { width: parent.width; visible: Brightness.present; icon: "light_mode"; value: Brightness.value; onMoved: v => Brightness.set(v) }
                Row {
                    visible: !Brightness.present
                    height: 52; spacing: 12
                    MIcon { width: 28; text: "light_mode"; size: 24; color: Theme.fgSurfaceVar; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "Яркость: у этого экрана нет регулировки"; size: 13; w: 600; dim: true; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }

        // the centre
        Item {
            id: qCentreHead
            width: parent.width; height: 42
            Label { x: 4; text: "Уведомления"; size: 15; w: 700; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 3 }
            Rectangle {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 3
                visible: Notifs.list.length > 0
                width: clr.implicitWidth + 28; height: 36; radius: cm.containsMouse ? 18 : 12
                color: Theme.surfaceHighest
                scale: cm.pressed ? .92 : 1
                Behavior on radius { SpringAnim { ms: 350 } }
                Behavior on scale { SpringAnim { ms: 350 } }
                Row { id: clr; anchors.centerIn: parent; spacing: 6
                    MIcon { text: "clear_all"; size: 18; color: Theme.fgSurfaceVar; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "Очистить"; size: 13; w: 650; dim: true; anchors.verticalCenter: parent.verticalCenter } }
                MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onClicked: Notifs.clear() }
            }
        }
        Column {
            id: qEmpty
            visible: Notifs.list.length === 0
            width: parent.width
            topPadding: 30; bottomPadding: 22; spacing: 10
            MShape { width: 72; height: 72; shape: Theme.shCookie9; color: Theme.secondaryContainer; anchors.horizontalCenter: parent.horizontalCenter
                MIcon { anchors.centerIn: parent; text: "notifications_off"; size: 28; color: Theme.fgSecondaryContainer } }
            Label { text: "Новых уведомлений нет"; size: 14; w: 600; dim: true; anchors.horizontalCenter: parent.horizontalCenter }
        }
        ListView {
            id: nl
            visible: Notifs.list.length > 0
            width: parent.width
            height: Math.min(360, contentHeight)
            clip: true
            spacing: 2
            interactive: contentHeight > height
            model: Notifs.list.slice().reverse()
            delegate: Rectangle {
                id: nt
                required property var modelData
                required property int index
                readonly property bool first: index === 0
                readonly property bool last: index === nl.count - 1
                readonly property real rr: ntm.containsMouse ? 20 : 0
                width: nl.width
                height: Math.max(44, ncol.implicitHeight) + 28
                topLeftRadius: rr || (first ? Theme.rm : 8); topRightRadius: rr || (first ? Theme.rm : 8)
                bottomLeftRadius: rr || (last ? Theme.rm : 8); bottomRightRadius: rr || (last ? Theme.rm : 8)
                color: ntm.containsMouse ? Theme.surfaceHighest : Theme.surfaceHigh
                Behavior on color { ColorAnim { ms: 200 } }
                MouseArea { id: ntm; anchors.fill: parent; hoverEnabled: true; onClicked: Notifs.dismiss(nt.modelData) }
                Rectangle {
                    x: 14; y: 14; width: 44; height: 44; radius: 16
                    color: Theme.tertiaryContainer
                    Image { id: npic; anchors.fill: parent; anchors.margins: 7; fillMode: Image.PreserveAspectFit; visible: status === Image.Ready
                        source: nt.modelData.image ? nt.modelData.image : nt.modelData.appIcon ? "image://icon/" + nt.modelData.appIcon : "" }
                    MIcon { anchors.centerIn: parent; text: Notifs.symbol(nt.modelData); size: 22; color: Theme.fgTertiaryContainer; visible: !npic.visible }
                }
                Column {
                    id: ncol
                    x: 14 + 44 + 12; y: 14
                    width: parent.width - x - 14 - tm.width - 12
                    Label { text: (nt.modelData.appName ? nt.modelData.appName + " · " : "") + nt.modelData.summary; size: 14; w: 650; width: parent.width }
                    Label { text: nt.modelData.body || ""; size: 13; w: 500; dim: true; width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 3; topPadding: 2; visible: text !== "" }
                }
                Label { id: tm; anchors.right: parent.right; anchors.rightMargin: 14; y: 15; text: Notifs.ago(nt.modelData); size: 11; w: 650; dim: true }
            }
        }
    }

    // a quick-settings toggle (.tg): an icon in a circle, its name and state;
    // on: the primary container, the circle a primary rounded square
    component Tile: Rectangle {
        id: t
        property string icon
        property string name
        property string sub
        property bool on: false
        property bool dis: false
        signal clicked
        width: (col.width - 8) / 2; height: 72
        radius: on ? 36 : tm2.containsMouse && !dis ? 18 : Theme.rm
        color: on ? Theme.primaryContainer : Theme.surfaceHigh
        opacity: dis && !on ? .55 : 1
        scale: tm2.pressed && !dis ? .96 : 1
        Behavior on radius { SpringAnim { ms: 450 } }
        Behavior on scale { SpringAnim { ms: 350 } }
        Behavior on color { ColorAnim { ms: 300 } }
        Row {
            anchors.verticalCenter: parent.verticalCenter; x: 14; spacing: 12
            Rectangle {
                width: 44; height: 44; radius: t.on ? 14 : 22
                color: t.on ? Theme.primary : Theme.surfaceHighest
                Behavior on radius { SpringAnim { ms: 450 } }
                Behavior on color { ColorAnim { ms: 300 } }
                MIcon { anchors.centerIn: parent; text: t.icon; size: 24; color: t.on ? Theme.fgPrimary : Theme.fgSurface }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label { text: t.name; size: 14; w: 650; color: t.on ? Theme.fgPrimaryContainer : Theme.fgSurface }
                Label { text: t.sub; size: 12; w: 550; topPadding: 2; color: t.on ? Theme.fgPrimaryContainer : Theme.fgSurfaceVar; opacity: t.on ? .8 : 1 }
            }
        }
        MouseArea { id: tm2; anchors.fill: parent; hoverEnabled: true; enabled: !t.dis; onClicked: t.clicked() }
    }
}

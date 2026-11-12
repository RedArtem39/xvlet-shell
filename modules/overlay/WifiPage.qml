import QtQuick
import qs.components
import qs.services

// Quick settings' Wi-Fi page (the prototype's wifi.js): it slides in over
// them (the Wi-Fi tile opens it). The switch: Wi-Fi on (automatic joining)
// or off; the network we are on, big; the networks around in one group --
// a known one joins with a tap, another asks for its password on a sheet
// from the bottom (an outlined field; a refused password says so there).
Item {
    id: root
    property bool open: false
    signal back
    property var asking: null                   // the network whose password the sheet asks for
    property bool refused: false

    implicitHeight: Math.min(760, page.implicitHeight)
    clip: true

    function ask(n, wrong) { asking = n; refused = !!wrong; pw.text = ""; pw.echoMode = TextInput.Password; pwFocus.restart(); }
    Timer { id: pwFocus; interval: 260; onTriggered: pw.forceActiveFocus() }
    onOpenChanged: if (!open) asking = null

    readonly property var cur: Wifi.networks.find(n => n.active) || null
    readonly property var others: Wifi.networks.filter(n => !n.active).slice().sort((a, b) => ((b.known > 0) - (a.known > 0)) || (b.signal - a.signal))
    function band(ch) { return ch > 14 ? "5 ГГц" : "2,4 ГГц" }
    function sigIcon(s) { return ["", "network_wifi_1_bar", "network_wifi_2_bar", "network_wifi_3_bar", "signal_wifi_4_bar"][Wifi.bars(s)] }
    function sigWord(s) { return ["", "слабый сигнал", "сигнал средний", "хороший сигнал", "отличный сигнал"][Wifi.bars(s)] }

    Flickable {
        anchors.fill: parent
        contentHeight: page.implicitHeight
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: page
            width: parent.width
            spacing: 10

            // the head: back, the title, the switch
            Item {
                width: parent.width; height: 48
                IconButton { anchors.verticalCenter: parent.verticalCenter; icon: "arrow_back"; onClicked: root.back() }
                Label { x: 48; anchors.verticalCenter: parent.verticalCenter; text: "Wi‑Fi"; size: 22; w: 750 }
                Toggle {
                    anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter
                    checked: Wifi.auto || Wifi.connected
                    onToggled: v => v ? Wifi.enable() : Wifi.disconnect()
                }
            }
            // scanning: a line running along
            Rectangle {
                x: 6; width: parent.width - 12; height: 4; radius: 2
                color: Theme.secondaryContainer
                opacity: Wifi.scanning ? 1 : 0
                Behavior on opacity { SmoothAnim { ms: 300 } }
                clip: true
                Rectangle {
                    width: parent.width * .4; height: 4; radius: 2; color: Theme.primary
                    NumberAnimation on x { running: Wifi.scanning && !Theme.still; from: -parent.width * .4; to: parent.width; duration: 1100; loops: Animation.Infinite; easing.type: Easing.InOutCubic }
                }
            }

            // Wi-Fi off
            Column {
                visible: !(Wifi.auto || Wifi.connected)
                width: parent.width; topPadding: 50; bottomPadding: 40; spacing: 6
                MIcon { anchors.horizontalCenter: parent.horizontalCenter; text: "wifi_off"; fill: true; size: 44; color: Theme.fgSurfaceVar }
                Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Wi‑Fi выключен"; size: 16; w: 700 }
                Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Включите, чтобы увидеть сети рядом"; size: 13; w: 600; dim: true }
            }

            // the network we are on
            Rectangle {
                visible: !!root.cur
                width: parent.width; height: 112; radius: 28
                color: Theme.primaryContainer
                Item {
                    x: 16; y: 16; width: 64; height: 64
                    MShape { anchors.fill: parent; shape: Theme.shCookie9; color: Theme.primary }
                    MIcon { anchors.centerIn: parent; text: root.cur ? root.sigIcon(root.cur.signal) : ""; fill: true; size: 30; color: Theme.fgPrimary }
                }
                Column {
                    x: 94; y: 16; width: parent.width - x - 16
                    Label { text: root.cur ? root.cur.ssid : ""; size: 18; w: 750; color: Theme.fgPrimaryContainer; width: parent.width; elide: Text.ElideRight }
                    Label { text: root.cur ? "Подключено · " + root.band(root.cur.channel) + " · " + root.sigWord(root.cur.signal) : ""; size: 13; w: 600; color: Theme.fgPrimaryContainer; opacity: .8; topPadding: 2 }
                    Item { width: 1; height: 8 }
                    Rectangle {
                        width: offRow.implicitWidth + 28; height: 36; radius: offM.containsMouse ? 12 : 18
                        color: Theme.alpha(Theme.fgPrimaryContainer, .12)
                        scale: offM.pressed ? .94 : 1
                        Behavior on radius { SpringAnim { ms: 350 } }
                        Behavior on scale { SpringAnim { ms: 350 } }
                        Row { id: offRow; anchors.centerIn: parent; spacing: 6
                            MIcon { text: "link_off"; size: 18; color: Theme.fgPrimaryContainer; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: "Отключить"; size: 13; w: 700; color: Theme.fgPrimaryContainer; anchors.verticalCenter: parent.verticalCenter } }
                        MouseArea { id: offM; anchors.fill: parent; hoverEnabled: true; onClicked: Wifi.disconnect() }
                    }
                }
            }

            // the networks around
            Item {
                visible: Wifi.auto || Wifi.connected
                width: parent.width; height: 40
                Label { x: 8; anchors.verticalCenter: parent.verticalCenter; text: "Доступные сети"; size: 14; w: 700; color: Theme.primary }
                IconButton { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; icon: "refresh"; onClicked: Wifi.scan() }
            }
            Label {
                visible: (Wifi.auto || Wifi.connected) && root.others.length === 0
                x: 8; topPadding: 16; bottomPadding: 20
                width: parent.width - 16; horizontalAlignment: Text.AlignHCenter
                text: Wifi.scanning ? "Ищу сети…" : "Сетей рядом не найдено"
                size: 13; w: 600; dim: true
            }
            Column {
                visible: Wifi.auto || Wifi.connected
                width: parent.width
                spacing: 3
                Repeater {
                    model: root.others
                    delegate: Rectangle {
                        id: nw
                        required property var modelData
                        required property int index
                        readonly property bool ok: modelData.sec === "wpa2"
                        readonly property bool joining: Wifi.pending === modelData.ssid
                        readonly property bool bad: modelData.known === 2
                        readonly property real big: Theme.rm
                        readonly property real rr: nm.containsMouse && ok ? 20 : 6
                        width: parent.width; height: 64
                        topLeftRadius: index === 0 ? big : rr; topRightRadius: index === 0 ? big : rr
                        bottomLeftRadius: index === root.others.length - 1 ? big : rr; bottomRightRadius: index === root.others.length - 1 ? big : rr
                        color: nm.containsMouse && ok ? Theme.surfaceHighest : Theme.surfaceHigh
                        opacity: ok ? 1 : .5
                        scale: nm.pressed && ok ? .98 : 1
                        Behavior on color { ColorAnim { ms: 200 } }
                        Behavior on scale { SpringAnim { ms: 350 } }
                        MouseArea {
                            id: nm
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                if (!nw.ok || Wifi.pending) return;
                                if (nw.modelData.known === 1) Wifi.connect(nw.modelData.ssid, "");
                                else root.ask(nw.modelData, nw.bad);
                            }
                        }
                        Rectangle {
                            id: sg
                            x: 12; anchors.verticalCenter: parent.verticalCenter
                            width: 40; height: 40; radius: nm.containsMouse && nw.ok ? 14 : 20
                            color: nw.joining ? Theme.primaryContainer : Theme.surfaceHighest
                            Behavior on radius { SpringAnim { ms: 400 } }
                            MIcon { anchors.centerIn: parent; text: root.sigIcon(nw.modelData.signal); fill: true; size: 22; color: nw.joining ? Theme.fgPrimaryContainer : Theme.fgSurface }
                            // joining: an arc running round it
                            Canvas {
                                anchors.fill: parent; anchors.margins: -3
                                visible: nw.joining
                                onPaint: { const g = getContext("2d"); g.reset(); g.lineWidth = 3; g.lineCap = "round"; g.strokeStyle = Theme.primary; g.beginPath(); g.arc(width / 2, height / 2, width / 2 - 2, 0, Math.PI * .6); g.stroke(); }
                                RotationAnimation on rotation { running: nw.joining; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
                            }
                        }
                        Column {
                            x: 66; anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - x - 50
                            Label { text: nw.modelData.ssid; size: 14.5; w: 650; width: parent.width; elide: Text.ElideRight }
                            Label {
                                size: 12; w: 550; topPadding: 2
                                color: nw.bad ? Theme.error : Theme.fgSurfaceVar
                                text: nw.joining ? "Подключение…" : nw.bad ? "Пароль не подошёл" : !nw.ok ? (nw.modelData.sec === "open" ? "Открытая · пока не поддерживается" : nw.modelData.sec.toUpperCase() + " · пока не поддерживается")
                                      : nw.modelData.known === 1 ? "Сохранена · " + root.band(nw.modelData.channel) : root.band(nw.modelData.channel)
                            }
                        }
                        MIcon {
                            anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                            visible: nw.modelData.sec !== "open" && !(nw.modelData.known > 0 && nm.containsMouse)
                            text: "lock"; size: 18; color: Theme.fgSurfaceVar
                        }
                        // a known one: forget it (it shows on hover, the whole row stays the target)
                        IconButton {
                            anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter
                            visible: nw.modelData.known > 0 && nm.containsMouse
                            icon: "delete"; size: 36; iconSize: 20
                            onClicked: Wifi.forget(nw.modelData.ssid)
                        }
                    }
                }
            }
            Item { width: 1; height: 6 }
        }
    }

    // ---- the password: a sheet from the bottom ----
    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.asking ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { SmoothAnim { ms: 300 } }
        MouseArea { anchors.fill: parent; onClicked: root.asking = null }
    }
    Rectangle {
        id: sheet
        x: 10; width: parent.width - 20
        height: sc.implicitHeight + 38
        y: root.asking ? parent.height - height - 10 : parent.height + 20
        radius: 30
        color: Theme.surfaceMid
        border.width: 1; border.color: Theme.edge
        Behavior on y { SpringAnim { ms: 550 } }
        MouseArea { anchors.fill: parent }                 // (its own clicks)
        Column {
            id: sc
            x: 20; y: 22; width: parent.width - 40
            spacing: 4
            Item {
                width: 64; height: 64; anchors.horizontalCenter: parent.horizontalCenter
                MShape { anchors.fill: parent; shape: Theme.shCookie9; color: Theme.primary }
                MIcon { anchors.centerIn: parent; text: root.asking ? root.sigIcon(root.asking.signal) : ""; fill: true; size: 30; color: Theme.fgPrimary }
            }
            Item { width: 1; height: 4 }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: root.asking ? root.asking.ssid : ""; size: 18; w: 750 }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: root.asking ? root.band(root.asking.channel) + " · WPA2" : ""; size: 12.5; w: 600; dim: true }
            Item { width: 1; height: 12 }
            // an outlined field, its label floating up
            Rectangle {
                id: field
                width: parent.width; height: 56; radius: 16
                color: "transparent"
                border.width: pw.activeFocus ? 2.5 : 1.5
                border.color: root.refused ? Theme.error : pw.activeFocus ? Theme.primary : Theme.outline
                Behavior on border.color { ColorAnim { ms: 200 } }
                SequentialAnimation on x {
                    id: shake; running: false
                    NumberAnimation { to: -6; duration: 60 } NumberAnimation { to: 6; duration: 80 }
                    NumberAnimation { to: -6; duration: 80 } NumberAnimation { to: 0; duration: 60 }
                }
                TextInput {
                    id: pw
                    x: 16; width: parent.width - 16 - 52; height: parent.height
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    renderType: TextInput.NativeRendering; font.family: Theme.font; font.pixelSize: 16; font.weight: 550; font.letterSpacing: .6
                    color: Theme.fgSurface; clip: true
                    selectionColor: Theme.primary; selectedTextColor: Theme.fgPrimary
                    onTextEdited: { root.refused = false; Sfx.ui("type"); }
                    Keys.onReturnPressed: go.go()
                    Keys.onEscapePressed: root.asking = null
                }
                Rectangle {
                    readonly property bool up: pw.activeFocus || pw.text.length > 0
                    x: 12; y: up ? -height / 2 : (parent.height - height) / 2
                    width: fl.implicitWidth + 8; height: fl.implicitHeight
                    color: Theme.surfaceMid
                    Behavior on y { SmoothAnim { ms: 220 } }
                    Label { id: fl; x: 4; text: "Пароль"; size: parent.up ? 12 : 16; w: 550
                        color: root.refused ? Theme.error : pw.activeFocus ? Theme.primary : Theme.fgSurfaceVar
                        Behavior on size { SmoothAnim { ms: 220 } } }
                }
                IconButton {
                    anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
                    icon: pw.echoMode === TextInput.Password ? "visibility" : "visibility_off"
                    onClicked: { pw.echoMode = pw.echoMode === TextInput.Password ? TextInput.Normal : TextInput.Password; pw.forceActiveFocus(); }
                }
            }
            Label {
                x: 16; topPadding: 4; width: parent.width - 32; wrapMode: Text.WordWrap
                text: root.refused ? "Пароль не подошёл. Возможно, его сменили на роутере." : "От 8 до 63 символов"
                size: 12; w: 550; color: root.refused ? Theme.error : Theme.fgSurfaceVar
            }
            Item {
                width: parent.width; height: 60
                Row {
                    anchors.right: parent.right; anchors.bottom: parent.bottom; spacing: 8
                    Rectangle {
                        width: 100; height: 44; radius: 22
                        color: noM.containsMouse ? Theme.alpha(Theme.primary, .1) : "transparent"
                        Label { anchors.centerIn: parent; text: "Отмена"; size: 14; w: 700; color: Theme.primary }
                        MouseArea { id: noM; anchors.fill: parent; hoverEnabled: true; onClicked: root.asking = null }
                    }
                    Rectangle {
                        id: go
                        readonly property bool can: pw.text.length >= 8 && pw.text.length <= 63
                        function go() {
                            if (!can) { shake.restart(); return; }
                            const n = root.asking;
                            Wifi.connect(n.ssid, pw.text);
                            pw.text = "";
                            root.asking = null;
                        }
                        width: 132; height: 44; radius: goM.containsMouse && can ? 14 : 22
                        color: Theme.primary
                        opacity: can ? 1 : .38
                        scale: goM.pressed && can ? .94 : 1
                        Behavior on radius { SpringAnim { ms: 350 } }
                        Behavior on scale { SpringAnim { ms: 350 } }
                        Label { anchors.centerIn: parent; text: "Подключить"; size: 14; w: 700; color: Theme.fgPrimary }
                        MouseArea { id: goM; anchors.fill: parent; hoverEnabled: true; onClicked: go.go() }
                    }
                }
            }
        }
    }
    // a refused password (wifid gave up on it): ask again, saying so
    Connections {
        target: Wifi
        function onNetworksChanged() {
            if (!root.open || root.asking || !Wifi.lastTried) return;
            const n = Wifi.networks.find(x => x.ssid === Wifi.lastTried && x.known === 2);
            if (n) { Wifi.lastTried = ""; root.ask(n, true); }
        }
    }
}

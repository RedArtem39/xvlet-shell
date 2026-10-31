import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.services

// The lock screen, as Serpantinum's: the wallpaper and a big clock; a key
// or a click brings the panel -- its core first (avatar, name, password),
// then its wings (weather and the system on the left, notifications and
// music on the right). Unlocking folds the panel away. The password is the
// account's own, checked by the system's helper for lock screens: chkpwd
// on WynlandOS, PAM's unix_chkpwd elsewhere (same use: the user's name as
// the argument, the password on stdin ending in a NUL).
//
// A session lock (ext-session-lock-v1: Zerp, Hyprland, sway): the
// compositor keeps the session locked -- nothing else drawn, no other
// window and no shortcut gets a key, and if this shell dies the session
// stays locked. One for all screens (shell.qml makes one).
WlSessionLock {
    id: lock
    locked: Ui.locked

WlSessionLockSurface {
    id: root
    color: "black"

    property string state_: "idle"        // idle, input, busy, unlocking
    property string pass: ""
    property bool wings: false
    property bool bad: false
    property real fold: 1

    onVisibleChanged: if (visible && Ui.locked) { state_ = "idle"; pass = ""; wings = false; bad = false; fold = 1; keys.forceActiveFocus(); }
    SystemClock { id: clock; precision: SystemClock.Seconds }

    function wake() {
        if (state_ !== "idle") return;
        state_ = "input"; idle.restart();
        wingsLater.restart();
    }
    function sleep_() { state_ = "idle"; wings = false; pass = ""; }
    Timer { id: wingsLater; interval: 160; onTriggered: if (root.state_ === "input") root.wings = true }
    Timer { id: idle; interval: 12000; onTriggered: if (root.state_ === "input" && !root.pass) root.sleep_() }

    Process {
        id: check
        // the password comes as one line; each helper gets it its own way
        // (chkpwd: a line; unix_chkpwd: ending in a NUL)
        command: ["sh", "-c", "IFS= read -r p; if [ -x /usr/lib/wynland/chkpwd ]; then printf '%s\\n' \"$p\" | /usr/lib/wynland/chkpwd \"$1\"; " +
                  "else printf '%s\\0' \"$p\" | \"$(command -v unix_chkpwd || echo /usr/sbin/unix_chkpwd)\" \"$1\" nullok; fi", "chkpwd", Quickshell.env("USER") || ""]
        stdinEnabled: true
        onStarted: { write(root.pass + "\n"); stdinEnabled = false; }
        onExited: code => {
            if (code === 0) { root.state_ = "unlocking"; root.wings = false; folding.start(); }
            else { root.state_ = "input"; root.bad = true; root.pass = ""; shake.restart(); }
        }
    }
    function tryUnlock() { if (!pass || state_ !== "input") return; bad = false; state_ = "busy"; check.running = true; }
    SequentialAnimation {
        id: folding
        PauseAnimation { duration: 140 }
        NumberAnimation { target: root; property: "fold"; to: 0; duration: Theme.ms(260); easing.type: Easing.InBack; easing.overshoot: 1.3 }
        ScriptAction { script: Ui.locked = false }
    }

    // the wallpaper, blurred once the panel is up
    Image {
        id: bg
        anchors.fill: parent
        anchors.margins: -40
        source: Config.data.wall.path ? "file://" + Config.data.wall.path : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width, root.height)
        opacity: root.fold
        scale: root.state_ === "idle" ? 1 : 1.04
        Behavior on scale { SmoothAnim { ms: 1100 } }
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blurMax: 48; blur: root.state_ === "idle" ? 0 : .7; saturation: .15; Behavior on blur { SmoothAnim { ms: 500 } } }
    }
    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.shadow, root.state_ === "idle" ? .2 : .42); opacity: root.fold; Behavior on color { ColorAnim { ms: 450 } } }

    // the clock
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * .36 - height / 2
        opacity: root.state_ === "idle" && root.fold > .5 ? 1 : 0
        scale: root.state_ === "idle" ? 1 : .92
        Behavior on opacity { SmoothAnim { ms: 150 } }
        Behavior on scale { SpringAnim { ms: 250 } }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 44
            Big { text: Qt.formatTime(clock.date, "hh"); color: Theme.primary }
            Big { text: Qt.formatTime(clock.date, "mm"); color: Theme.fgSurface }
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clock.date.toLocaleDateString(Qt.locale("ru_RU"), "dddd, d MMMM").toUpperCase()
            size: 17; w: 600; color: Theme.fgSurfaceVar; font.letterSpacing: 17 * .09; topPadding: 18
        }
    }

    // the panel: 1280 x 566; its core (440) comes first, the wings after
    Rectangle {
        id: panel
        readonly property bool up: root.state_ !== "idle"
        width: root.wings ? 1280 : 440
        height: 566
        anchors.horizontalCenter: parent.horizontalCenter
        y: (parent.height - height) / 2 + (up ? 0 : 90)
        radius: Theme.r * 1.5
        color: Theme.alpha(Theme.surfaceLow, .82)
        clip: true
        opacity: up ? root.fold : 0
        scale: (up ? 1 : .92) * (root.state_ === "unlocking" ? root.fold : 1)
        Behavior on width { SpringAnim { ms: 320 } }
        Behavior on y { SmoothAnim { ms: 250 } }
        Behavior on opacity { SmoothAnim { ms: 150 } }

        Item {
            // the inside keeps its place while the panel grows around it
            width: 1280; height: 566
            x: (panel.width - width) / 2

            // the left wing: the weather, four gauges
            Column {
                x: 20; y: 20; width: 380; spacing: 8
                opacity: root.wings ? 1 : 0
                Behavior on opacity { SmoothAnim { ms: 200 } }
                Rectangle {
                    width: parent.width; height: 190; radius: Theme.rm
                    gradient: Gradient {
                        GradientStop { position: 0; color: Theme.primaryContainer }
                        GradientStop { position: 1; color: Theme.mix(Theme.tertiaryContainer, Theme.surfaceHigh, .3) }
                    }
                    Row {
                        x: 18; y: 18; spacing: 16
                        MShape { width: 72; height: 72; shape: Theme.shSunny; color: Weather.ok ? Theme.oklch(85, .14, 85) : Theme.surfaceHighest
                            MIcon { anchors.centerIn: parent; visible: !Weather.ok; text: "cloud_off"; size: 28 } }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Label { text: Weather.ok ? Weather.sign(Weather.temp) : "нет данных"; size: Weather.ok ? 50 : 22; w: Font.Light; color: Theme.fgPrimaryContainer }
                            Label { text: Weather.ok ? Weather.desc : "нет сети"; size: 14; color: Theme.fgPrimaryContainer }
                        }
                    }
                    Row {
                        x: 18; y: 112; spacing: 6
                        Repeater { model: Weather.days
                            Rectangle { id: dd; required property var modelData; width: 80; height: 60; radius: 22; color: Qt.rgba(1, 1, 1, .12)
                                Row { anchors.centerIn: parent; spacing: 6
                                    MIcon { text: dd.modelData.icon; fill: true; size: 20; color: Theme.fgPrimaryContainer }
                                    Label { text: dd.modelData.d + " " + Weather.sign(dd.modelData.t); size: 12; color: Theme.fgPrimaryContainer; anchors.verticalCenter: parent.verticalCenter } } } }
                    }
                }
                Grid {
                    columns: 2; spacing: 8
                    LockGauge { name: "Процессор"; v: Sys.cpu }
                    LockGauge { name: "Память"; v: Sys.ram }
                    LockGauge { name: "Темп."; v: Sys.temp >= 0 ? Sys.temp / 100 : 0; label: Sys.temp >= 0 ? Math.round(Sys.temp) + "°" : "нет" }
                    LockGauge { name: "Диск"; v: Sys.disk }
                }
            }

            // the core: who, the status, the password
            Column {
                x: 450; y: 89; width: 380; spacing: 0
                MShape {
                    width: 200; height: 200; anchors.horizontalCenter: parent.horizontalCenter
                    shape: avm.containsMouse ? Theme.shCookie12 : Theme.shCircle
                    color: Theme.tertiaryContainer
                    Label { anchors.centerIn: parent; text: (Quickshell.env("USER") || "?")[0].toUpperCase(); size: 84; w: Font.Bold; color: Theme.fgTertiaryContainer }
                    MouseArea { id: avm; anchors.fill: parent; hoverEnabled: true }
                }
                Item { width: 1; height: 16 }
                Row {
                    spacing: 10
                    Chip { icon: "person"; text: Quickshell.env("USER") || "user" }
                    Chip {
                        icon: root.state_ === "busy" ? "progress_activity" : root.bad ? "error" : "lock"
                        text: root.state_ === "busy" ? "Проверка" : root.bad ? "Неверный пароль" : "Заблокировано"
                        bad: root.bad
                    }
                }
                Item { width: 1; height: 8 }
                Rectangle {
                    id: field
                    width: 380; height: 44
                    radius: 22
                    color: Theme.surfaceHighest
                    border.width: 2
                    border.color: root.bad ? Theme.error : Theme.primary
                    transform: Translate { id: sh }
                    SequentialAnimation {
                        id: shake
                        NumberAnimation { target: sh; property: "x"; to: -10; duration: 40 }
                        NumberAnimation { target: sh; property: "x"; to: 10; duration: 70 }
                        NumberAnimation { target: sh; property: "x"; to: -8; duration: 70 }
                        NumberAnimation { target: sh; property: "x"; to: 6; duration: 70 }
                        NumberAnimation { target: sh; property: "x"; to: 0; duration: 60 }
                    }
                    Rectangle {
                        x: 4; anchors.verticalCenter: parent.verticalCenter
                        width: 36; height: 36; radius: 18
                        color: root.bad ? Theme.errorContainer : Theme.primaryContainer
                        MIcon { anchors.centerIn: parent; text: "key"; fill: true; size: 20; color: root.bad ? Theme.error : Theme.fgPrimaryContainer }
                    }
                    Row {
                        anchors.centerIn: parent; spacing: 7
                        Repeater { model: root.pass.length
                            Rectangle { width: 11; height: 11; radius: 5.5; color: Theme.fgSurface; scale: 0; Component.onCompleted: scale = 1; Behavior on scale { SpringAnim { ms: 350 } } } }
                    }
                }
                Item { width: 1; height: 32 }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
                    Chip { icon: "keyboard"; text: "RU" }
                    Chip { icon: Power.present ? Power.icon : "power"; text: Power.present ? Power.capacity + "%" : "от сети" }
                }
            }

            // the right wing: the notifications, the music
            Column {
                x: 860; y: 20; width: 400; spacing: 8
                opacity: root.wings ? 1 : 0
                Behavior on opacity { SmoothAnim { ms: 200 } }
                Rectangle {
                    width: parent.width; height: 422; radius: Theme.rm; color: Theme.alpha(Theme.surfaceHigh, .85)
                    Label { x: 18; y: 16; text: "Уведомления"; size: 17; w: Font.Bold }
                    Column {
                        x: 12; y: 52; width: parent.width - 24; spacing: 8
                        Repeater { model: Notifs.list.slice(-3).reverse()
                            NoteCard { required property var modelData; n: modelData; width: parent.width } }
                        Label { visible: Notifs.list.length === 0; text: "Пусто"; size: 13; dim: true; leftPadding: 6 }
                    }
                }
                Rectangle {
                    width: parent.width; height: 96; radius: Theme.rm; color: Theme.alpha(Theme.surfaceHigh, .85)
                    Row {
                        x: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 14
                        MShape { width: 72; height: 72; shape: Media.playing ? Theme.shCircle : Theme.shCookie12; color: Theme.tertiaryContainer
                            MIcon { anchors.centerIn: parent; text: "music_note"; fill: true; size: 30; color: Theme.fgTertiaryContainer } }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter; width: 160
                            Label { text: Media.title; size: 15; w: Font.Bold; width: parent.width }
                            Label { text: Media.artist; size: 12; dim: true; width: parent.width }
                        }
                        IconButton { icon: Media.playing ? "pause" : "play_arrow"; fill: true; on: Media.playing; anchors.verticalCenter: parent.verticalCenter; onClicked: Media.toggle() }
                        IconButton { icon: "skip_next"; fill: true; anchors.verticalCenter: parent.verticalCenter; onClicked: Media.next() }
                    }
                }
            }
        }
    }

    // the keys: any wakes the panel, the rest is the password
    Item {
        id: keys
        anchors.fill: parent
        focus: Ui.locked
        Keys.onPressed: e => {
            if (root.state_ === "unlocking" || root.state_ === "busy") { e.accepted = true; return; }
            if (e.key === Qt.Key_Escape) { root.sleep_(); e.accepted = true; return; }
            if (root.state_ === "idle") root.wake();
            idle.restart();
            if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.tryUnlock();
            else if (e.key === Qt.Key_Backspace) { if (root.pass) Sfx.ui("type"); root.pass = root.pass.slice(0, -1); }
            // (a shortcut's key -- Super+T -- is not a character of the password)
            else if (e.text && e.text.length === 1 && e.text.charCodeAt(0) >= 32 && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) { root.pass += e.text; root.bad = false; Sfx.ui("type"); }
            e.accepted = true;
        }
        MouseArea { anchors.fill: parent; onClicked: root.wake() }
    }
}

    // the clock's digits: heavy, tight, a hard shadow 4 px under them
    component Big: Item {
        property alias text: bt.text
        property alias color: bt.color
        width: bt.implicitWidth; height: bt.implicitHeight * .9
        Label { x: 0; y: 4; text: bt.text; size: 190; w: 800; font.letterSpacing: -7.6; color: Qt.rgba(0, 0, 0, .32); font.features: { "tnum": 1 } }
        Label { id: bt; size: 190; w: 800; font.letterSpacing: -7.6; font.features: { "tnum": 1 } }
    }

    component Chip: Rectangle {
        id: ch
        property string icon
        property string text
        property bool bad: false
        width: Math.max(185, cr.implicitWidth + 28); height: 44; radius: Theme.rs
        color: bad ? Theme.errorContainer : Theme.alpha(Theme.surfaceHigh, .9)
        Row { id: cr; anchors.centerIn: parent; spacing: 8
            MIcon { text: ch.icon; fill: true; size: 19; color: ch.bad ? Theme.error : Theme.primary }
            Label { text: ch.text; size: 14; anchors.verticalCenter: parent.verticalCenter } }
    }
    component LockGauge: Rectangle {
        id: lg
        property string name
        property real v
        property string label: Math.round(v * 100) + "%"
        width: 186; height: 160; radius: Theme.rm; color: Theme.alpha(Theme.surfaceHigh, .85)
        Column { anchors.centerIn: parent
            Ring { width: 112; height: 112; value: lg.v; label: lg.label; anchors.horizontalCenter: parent.horizontalCenter }
            Label { text: lg.name; size: 13; dim: true; anchors.horizontalCenter: parent.horizontalCenter } }
    }
}

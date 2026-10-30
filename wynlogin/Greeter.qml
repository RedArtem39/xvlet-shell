// xvlet's skin for wynlogin, WynlandOS's login screen (what an SDDM theme
// is elsewhere): the shell's lock screen as the way in. Installed at
// /usr/share/wynlogin/themes/xvlet/Greeter.qml; chosen with "theme = xvlet"
// in /etc/wynland/login.conf.
//
// A theme only draws. wynlogin checks the password and starts the session;
// its link here is `greeter` (apps/zerp2/greeter.h in WynlandOS):
//   greeter.users    [{ name, fullName }]: the accounts that can log in
//   greeter.busy     a password is being checked
//   greeter.login(name, password)
//   greeter.accepted()   -> fade out, then greeter.quit()
//   greeter.refused(reason)
// and wallpaperUrl, the machine's wallpaper ("" if none). It runs as the
// unprivileged "greeter" account, inside Zerp, without Quickshell: plain
// QtQuick only, so the shell's components are not used here -- its colours
// (the default wallpaper's seed, tonal, dark) and fonts are.
import QtQuick
import QtQuick.Window
import QtQuick.Effects

Window {
    id: root
    visible: true
    visibility: Window.FullScreen
    color: surface
    title: "Login"

    // ---- the shell's colours: services/Theme.qml with the seed of the
    // default wallpaper (01-dusk: hue 257, tonal scheme), dark
    readonly property real hp: 257
    readonly property real ht: 317
    readonly property color primary: oklch(80, .12, hp)
    readonly property color primaryContainer: oklch(36, .108, hp)
    readonly property color fgPrimaryContainer: oklch(91, .06, hp)
    readonly property color tertiaryContainer: oklch(36, .081, ht)
    readonly property color fgTertiaryContainer: oklch(91, .045, ht)
    readonly property color surface: oklch(16.5, .024, hp)
    readonly property color surfaceLow: oklch(19.5, .027, hp)
    readonly property color surfaceHigh: oklch(26, .0315, hp)
    readonly property color surfaceHighest: oklch(30, .033, hp)
    readonly property color fgSurface: oklch(93, .0105, hp)
    readonly property color fgSurfaceVar: oklch(78, .024, hp)
    readonly property color error: oklch(72, .16, 25)
    readonly property color errorContainer: oklch(38, .12, 25)
    function oklch(L, C, H) {
        const h = H * Math.PI / 180, l0 = L / 100, A = C * Math.cos(h), B = C * Math.sin(h);
        const l = Math.pow(l0 + .3963377774 * A + .2158037573 * B, 3);
        const m = Math.pow(l0 - .1055613458 * A - .0638541728 * B, 3);
        const s = Math.pow(l0 - .0894841775 * A - 1.291485548 * B, 3);
        const g = x => { x = Math.max(0, Math.min(1, x)); return x <= .0031308 ? 12.92 * x : 1.055 * Math.pow(x, 1 / 2.4) - .055; };
        return Qt.rgba(g(4.0767416621 * l - 3.3077115913 * m + .2309699292 * s),
                       g(-1.2684380046 * l + 2.6097574011 * m - .3413193965 * s),
                       g(-.0041960863 * l - .7034186147 * m + 1.707614701 * s), 1);
    }
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
    readonly property var spring: [.34, 1.56, .64, 1, 1, 1]
    readonly property var smooth: [.2, 0, 0, 1, 1, 1]
    // the shell's size at 1080 lines
    function s(v) { return v * root.height / 1080 }

    // the shell's fonts, from where the shell is
    FontLoader { source: "file:///usr/share/xvlet/assets/fonts/RobotoFlex.ttf" }
    FontLoader { source: "file:///usr/share/xvlet/assets/fonts/MaterialSymbolsRounded.ttf" }

    // ---- who: the accounts, the one chosen
    readonly property var users: greeter.users
    property int current: 0
    readonly property var user: users.length > 0 ? users[Math.min(current, users.length - 1)] : null

    property string state_: "idle"        // idle, input, busy, leaving
    property bool bad: false
    property real fold: 1

    function wake() {
        if (state_ !== "idle") return;
        state_ = "input"; idle.restart(); input.forceActiveFocus();
    }
    function sleep_() { if (state_ === "input") { state_ = "idle"; input.text = ""; } }
    Timer { id: idle; interval: 15000; onTriggered: if (root.state_ === "input" && !input.text) root.sleep_() }
    function submit() {
        if (state_ !== "input" || !user || !input.text || greeter.busy) return;
        bad = false; state_ = "busy";
        greeter.login(user.name, input.text);
    }
    function pick(d) {
        if (users.length < 2 || state_ === "busy" || state_ === "leaving") return;
        current = (current + d + users.length) % users.length;
        input.text = ""; bad = false;
    }
    Connections {
        target: greeter
        function onAccepted() { root.state_ = "leaving"; leave.start(); }
        function onRefused(reason) { root.state_ = "input"; root.bad = true; input.text = ""; shake.restart(); idle.restart(); }
    }
    SequentialAnimation {
        id: leave
        PauseAnimation { duration: 140 }
        NumberAnimation { target: root; property: "fold"; to: 0; duration: 420; easing.type: Easing.InBack; easing.overshoot: 1.3 }
        ScriptAction { script: greeter.quit() }
    }

    // ---- the wallpaper: the shell's own, blurred once the panel is up
    Image {
        id: bg
        anchors.fill: parent
        anchors.margins: -40
        source: "file:///usr/share/xvlet/assets/walls/01-dusk.png"
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width, root.height)
        opacity: root.fold
        scale: root.state_ === "idle" ? 1 : 1.04
        Behavior on scale { NumberAnimation { duration: 1100; easing.type: Easing.BezierSpline; easing.bezierCurve: root.smooth } }
        onStatusChanged: if (status === Image.Error && wallpaperUrl) source = wallpaperUrl
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true; blurMax: 48; saturation: .15
            blur: root.state_ === "idle" ? 0 : .7
            Behavior on blur { NumberAnimation { duration: 500 } }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, root.state_ === "idle" ? .2 : .42)
        opacity: root.fold
        Behavior on color { ColorAnimation { duration: 450 } }
    }

    // ---- at rest: the clock, the shell's big digits
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * .36 - height / 2
        opacity: root.state_ === "idle" && root.fold > .5 ? 1 : 0
        scale: root.state_ === "idle" ? 1 : .92
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spring } }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.s(44)
            Big { text: Qt.formatTime(root.now, "hh"); color: root.primary }
            Big { text: Qt.formatTime(root.now, "mm"); color: root.fgSurface }
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.now.toLocaleDateString(Qt.locale("ru_RU"), "dddd, d MMMM").toUpperCase()
            size: 17; w: 600; color: root.fgSurfaceVar; font.letterSpacing: root.s(17 * .09); topPadding: root.s(18)
        }
    }
    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - height - root.s(48)
        text: "Нажмите любую клавишу"
        size: 14; w: 600; color: root.fgSurfaceVar
        opacity: root.state_ === "idle" && root.fold > .5 ? .8 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // ---- the panel: the lock screen's core -- who, the state, the password
    Rectangle {
        id: panel
        readonly property bool up: root.state_ !== "idle"
        width: root.s(440); height: core.height + root.s(120)
        anchors.horizontalCenter: parent.horizontalCenter
        y: (parent.height - height) / 2 + (up ? 0 : root.s(90))
        radius: root.s(48)
        color: root.alpha(root.surfaceLow, .82)
        opacity: up ? root.fold : 0
        scale: (up ? 1 : .92) * (root.state_ === "leaving" ? root.fold : 1)
        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: root.smooth } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Column {
            id: core
            x: root.s(30); y: root.s(60); width: root.s(380)
            // the avatar: the name's letter; arrows on the sides with more accounts
            Item {
                width: parent.width; height: root.s(200)
                Rectangle {
                    width: root.s(200); height: width; radius: width / 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.tertiaryContainer
                    scale: avm.containsMouse ? 1.04 : 1
                    Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spring } }
                    Label { anchors.centerIn: parent; text: root.user ? root.user.name[0].toUpperCase() : "?"; size: 84; w: 700; color: root.fgTertiaryContainer }
                    MouseArea { id: avm; anchors.fill: parent; hoverEnabled: true; onClicked: root.pick(1) }
                }
                Arrow { anchors.left: parent.left; icon: "chevron_left"; onClicked: root.pick(-1) }
                Arrow { anchors.right: parent.right; icon: "chevron_right"; onClicked: root.pick(1) }
            }
            Item { width: 1; height: root.s(16) }
            Row {
                spacing: root.s(10)
                Chip { icon: "person"; text: root.user ? root.user.fullName : "нет учётных записей" }
                Chip {
                    icon: root.state_ === "busy" ? "progress_activity" : root.bad ? "error" : "lock"
                    text: root.state_ === "busy" ? "Проверка" : root.state_ === "leaving" ? "Добро пожаловать" : root.bad ? "Неверный пароль" : "Вход"
                    bad: root.bad
                }
            }
            Item { width: 1; height: root.s(8) }
            Rectangle {
                id: field
                width: parent.width; height: root.s(44); radius: height / 2
                color: root.surfaceHighest
                border.width: 2
                border.color: root.bad ? root.error : root.primary
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
                    x: root.s(4); anchors.verticalCenter: parent.verticalCenter
                    width: root.s(36); height: width; radius: width / 2
                    color: root.bad ? root.errorContainer : root.primaryContainer
                    Icon { anchors.centerIn: parent; text: "key"; fill: true; size: 20; color: root.bad ? root.error : root.fgPrimaryContainer }
                }
                Row {
                    anchors.centerIn: parent; spacing: root.s(7)
                    Repeater {
                        model: input.text.length
                        Rectangle {
                            width: root.s(11); height: width; radius: width / 2; color: root.fgSurface
                            scale: 0
                            Component.onCompleted: scale = 1
                            Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spring } }
                        }
                    }
                }
                Label {
                    anchors.centerIn: parent
                    visible: !input.text.length
                    text: "Пароль"; size: 14; w: 500; color: root.fgSurfaceVar
                }
                // the keys themselves: a hidden field (the layouts, the input methods)
                TextInput {
                    id: input
                    width: 1; height: 1; opacity: 0
                    echoMode: TextInput.Password
                    enabled: root.state_ === "input"
                    onTextEdited: { root.bad = false; idle.restart(); }
                    onAccepted: root.submit()
                    Keys.onEscapePressed: root.sleep_()
                    Keys.onLeftPressed: e => { if (!text) root.pick(-1); else e.accepted = false; }
                    Keys.onRightPressed: e => { if (!text) root.pick(1); else e.accepted = false; }
                }
            }
            Item { width: 1; height: root.s(32) }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.s(10)
                Chip { icon: "group"; text: root.users.length > 1 ? (root.current + 1) + " из " + root.users.length : "1 учётная запись"; small: true }
                Chip { icon: "schedule"; text: Qt.formatTime(root.now, "hh:mm"); small: true }
            }
        }
    }

    // ---- any key or click brings the panel up
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        z: -1
        Keys.onPressed: e => {
            if (root.state_ !== "idle") return;
            root.wake();
            if (e.text && e.text.length === 1 && e.text.charCodeAt(0) >= 32) input.insert(input.length, e.text);
            e.accepted = true;
        }
        MouseArea { anchors.fill: parent; onClicked: root.state_ === "idle" ? root.wake() : input.forceActiveFocus() }
    }
    Component.onCompleted: keys.forceActiveFocus()

    // ---- the parts
    component Label: Text {
        property real size: 14
        property int w: 600
        font.family: "Roboto Flex"
        font.pixelSize: root.s(size)
        font.weight: w
        font.variableAxes: ({ wght: w, opsz: Math.max(8, Math.min(144, size)) })
        color: root.fgSurface
        elide: Text.ElideRight
    }
    component Icon: Text {
        property bool fill: false
        property real size: 24
        font.family: "Material Symbols Rounded"
        font.pixelSize: root.s(size)
        font.variableAxes: ({ FILL: fill ? 1 : 0, wght: fill ? 500 : 450, GRAD: 0, opsz: Math.min(48, Math.max(20, size)) })
        color: root.fgSurface
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
    // the clock's digits: heavy, tight, a hard shadow 4 px under them
    component Big: Item {
        property alias text: bt.text
        property alias color: bt.color
        width: bt.implicitWidth; height: bt.implicitHeight * .9
        Label { x: 0; y: root.s(4); text: bt.text; size: 190; w: 800; font.letterSpacing: root.s(-7.6); color: Qt.rgba(0, 0, 0, .32); font.features: { "tnum": 1 } }
        Label { id: bt; size: 190; w: 800; font.letterSpacing: root.s(-7.6); font.features: { "tnum": 1 } }
    }
    component Chip: Rectangle {
        id: ch
        property string icon
        property string text
        property bool bad: false
        property bool small: false
        width: Math.max(root.s(small ? 120 : 185), cr.implicitWidth + root.s(28)); height: root.s(44); radius: root.s(16)
        color: bad ? root.errorContainer : root.alpha(root.surfaceHigh, .9)
        Behavior on color { ColorAnimation { duration: 300 } }
        Row {
            id: cr; anchors.centerIn: parent; spacing: root.s(8)
            Icon { text: ch.icon; fill: true; size: 19; color: ch.bad ? root.error : root.primary }
            Label { text: ch.text; size: 14; anchors.verticalCenter: parent.verticalCenter; width: Math.min(implicitWidth, root.s(140)) }
        }
    }
    component Arrow: Rectangle {
        id: ar
        property string icon
        signal clicked
        visible: root.users.length > 1
        anchors.verticalCenter: parent.verticalCenter
        width: root.s(44); height: width; radius: am.containsMouse ? width / 2 : root.s(16)
        color: am.containsMouse ? root.surfaceHighest : root.alpha(root.surfaceHigh, .9)
        Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spring } }
        Icon { anchors.centerIn: parent; text: ar.icon; size: 24 }
        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; onClicked: ar.clicked() }
    }
}

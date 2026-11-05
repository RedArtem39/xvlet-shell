// xvlet's skin for wynlogin, WynlandOS's login screen (what an SDDM theme
// is elsewhere). Installed at /usr/share/wynlogin/themes/xvlet/Greeter.qml;
// chosen with "theme = xvlet" in /etc/wynland/login.conf.
//
// A card: on its left a living scene (scenes/<id>/Scene.qml beside the
// shell, at /usr/share/xvlet/wynlogin -- baked from animated SVGs by
// tools/bake_scene.py) with the clock in its sky (Clock.qml); on its right
// who logs in and the password. Behind it the same scene, blurred, as the
// room's light; the colours are the scene's own hue's.
//
// Each account has its own look, chosen in the shell's settings ("Экран
// входа"): the scene, the clock's style and place, the date --
// greeter.users[i].look, read by Zerp from /var/lib/wynlogin/looks/<name>.json
// (the file must be the account's own). Switching accounts switches the look.
// Without the scene (missing files): the shell's wallpaper in the card.
//
// A theme only draws. wynlogin checks the password and starts the session;
// its link here is `greeter` (apps/zerp2/greeter.h in WynlandOS):
//   greeter.users    [{ name, fullName }]: the accounts that can log in
//   greeter.busy     a password is being checked
//   greeter.login(name, password)
//   greeter.accepted()   -> fold away, then greeter.quit()
//   greeter.refused(reason)
// and wallpaperUrl, the machine's wallpaper ("" if none). It runs as the
// unprivileged "greeter" account, inside Zerp, without Quickshell: plain
// QtQuick only, so the shell's components are not used here -- its colour
// system (M3 tonal, dark; seeded by the scene's rose) and fonts are.
import QtQuick
import QtQuick.Window
import QtQuick.Effects

Window {
    id: root
    visible: true
    visibility: Window.FullScreen
    color: surface
    title: "Login"

    readonly property string shell: "file:///usr/share/xvlet/"

    // ---- the look: the chosen account's
    readonly property var look: user && user.look ? user.look : ({})
    readonly property string sceneId: look.scene || "sakura-katana"

    // ---- the shell's colours (services/Theme.qml: tonal, dark) seeded by
    // the scene's own hue
    property real hp: scene.item ? scene.item.hue : 355
    Behavior on hp { NumberAnimation { duration: 600 } }
    readonly property real ht: hp + 60
    readonly property color primary: oklch(82, .09, hp)
    readonly property color fgPrimary: oklch(26, .07, hp)
    readonly property color primaryContainer: oklch(38, .08, hp)
    readonly property color fgPrimaryContainer: oklch(92, .05, hp)
    readonly property color tertiaryContainer: oklch(38, .07, ht)
    readonly property color fgTertiaryContainer: oklch(92, .045, ht)
    readonly property color surface: oklch(15, .025, hp)
    readonly property color surfaceLow: oklch(20, .03, hp)
    readonly property color surfaceHigh: oklch(27, .032, hp)
    readonly property color surfaceHighest: oklch(31, .034, hp)
    readonly property color fgSurface: oklch(94, .012, hp)
    readonly property color fgSurfaceVar: oklch(79, .028, hp)
    // the clock on the scene's sky: dark digits on a light one
    readonly property color sky: scene.item && !scene.item.lightSky ? oklch(96, .03, hp) : oklch(31, .06, hp)
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
    FontLoader { source: root.shell + "assets/fonts/RobotoFlex.ttf" }
    FontLoader { source: root.shell + "assets/fonts/MaterialSymbolsRounded.ttf" }

    // ---- who: the accounts, the one chosen
    readonly property var users: greeter.users
    property int current: 0
    readonly property var user: users.length > 0 ? users[Math.min(current, users.length - 1)] : null

    property string state_: "idle"        // idle (the field asleep), input, busy, leaving
    property bool bad: false
    property real fold: 0                 // the card's way in (0 -> 1) and out (-> 0)
    NumberAnimation on fold { id: comeIn; from: 0; to: 1; duration: 800; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spring }

    function wake() {
        if (state_ !== "idle") return;
        state_ = "input"; idle.restart(); input.forceActiveFocus();
    }
    function sleep_() { if (state_ === "input") { state_ = "idle"; input.text = ""; keys.forceActiveFocus(); } }
    Timer { id: idle; interval: 30000; onTriggered: if (root.state_ === "input" && !input.text) root.sleep_() }
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
        function onRefused(reason) { root.state_ = "input"; root.bad = true; input.text = ""; shake.restart(); idle.restart(); input.forceActiveFocus(); }
    }
    SequentialAnimation {
        id: leave
        PauseAnimation { duration: 260 }
        NumberAnimation { target: root; property: "fold"; to: 0; duration: 480; easing.type: Easing.InBack; easing.overshoot: 1.3 }
        ScriptAction { script: greeter.quit() }
    }

    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // ---- the room: the scene blurred (or the wallpaper), dimmed
    Image {
        anchors.fill: parent
        anchors.margins: -root.s(40)
        source: root.shell + "wynlogin/scenes/" + root.sceneId + "/room.png"
        fillMode: Image.PreserveAspectCrop
        opacity: .25 + .75 * Math.max(0, Math.min(1, root.fold))
        onStatusChanged: if (status === Image.Error && wallpaperUrl) source = wallpaperUrl
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, .52) }

    // ---- the card
    Item {
        id: card
        width: Math.min(root.s(1180), root.width * .92)
        height: Math.min(root.s(560), root.height * .74)
        anchors.centerIn: parent
        opacity: Math.max(0, Math.min(1, root.fold * 1.4))
        scale: .94 + .06 * root.fold

        // its body: the scene's side and the panel's, one rounded shape
        RectangularShadow {
            anchors.fill: parent; radius: root.s(40)
            blur: root.s(70); offset.y: root.s(30); spread: -root.s(20)
            color: Qt.rgba(0, 0, 0, .55)
        }
        Rectangle { anchors.fill: parent; radius: root.s(40); color: root.alpha(root.surfaceLow, .92) }

        // the scene, cut to the card's left (rounded on the outer side)
        Item {
            id: art
            width: Math.round(card.width * 1.6 / 2.6); height: card.height
            layer.enabled: true
            layer.effect: MultiEffect { maskEnabled: true; maskSource: artMask; maskThresholdMin: .5; maskSpreadAtMin: 1 }
            Loader {
                id: scene
                source: root.shell + "wynlogin/scenes/" + root.sceneId + "/Scene.qml"
                // the scene covers the side, a little below its middle (the field, the blade)
                readonly property real k: item ? Math.max(art.width / item.width, art.height / item.height) : 1
                x: item ? (art.width - item.width * k) / 2 : 0
                y: item ? (art.height - item.height * k) * .6 : 0
                onLoaded: { item.transformOrigin = Item.TopLeft; item.scale = Qt.binding(() => scene.k); }
            }
            Image {
                anchors.fill: parent
                visible: scene.status === Loader.Error
                source: wallpaperUrl || root.shell + "assets/walls/01-dusk.png"
                fillMode: Image.PreserveAspectCrop
            }
            // the clock in the scene's sky (Clock.qml: the account's style)
            Loader {
                anchors.fill: parent
                source: root.shell + "wynlogin/Clock.qml"
                onLoaded: {
                    item.style = Qt.binding(() => root.look.clock || "big");
                    item.align = Qt.binding(() => root.look.clockPos || "left");
                    item.showDate = Qt.binding(() => root.look.date !== false);
                    item.ink = Qt.binding(() => root.sky);
                    item.k = Qt.binding(() => card.height / 560);
                }
            }
        }
        Item {
            id: artMask
            width: art.width; height: art.height
            visible: false; layer.enabled: true
            Rectangle { width: parent.width + root.s(60); height: parent.height; radius: root.s(40) }
        }

        // ---- the panel: who, the state, the password
        Item {
            x: art.width; width: card.width - art.width; height: card.height
            Column {
                id: core
                width: Math.min(parent.width - root.s(60), root.s(380))
                anchors.centerIn: parent
                // the avatar: the name's letter; arrows on the sides with more accounts
                Item {
                    width: parent.width; height: root.s(132)
                    Rectangle {
                        width: root.s(124); height: width; radius: width / 2
                        anchors.centerIn: parent
                        color: root.primaryContainer
                        border.width: root.s(3); border.color: root.primary
                        scale: avm.containsMouse ? 1.04 : 1
                        Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spring } }
                        Label { anchors.centerIn: parent; text: root.user ? root.user.name[0].toUpperCase() : "?"; size: 56; w: 750; color: root.fgPrimaryContainer }
                        MouseArea { id: avm; anchors.fill: parent; hoverEnabled: true; onClicked: root.pick(1) }
                    }
                    Arrow { anchors.left: parent.left; icon: "chevron_left"; onClicked: root.pick(-1) }
                    Arrow { anchors.right: parent.right; icon: "chevron_right"; onClicked: root.pick(1) }
                }
                Item { width: 1; height: root.s(14) }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.user ? (root.user.fullName || root.user.name) : "Нет учётных записей"
                    size: 26; w: 750; width: Math.min(implicitWidth, parent.width)
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.state_ === "busy" ? "Проверка…" : root.state_ === "leaving" ? "Добро пожаловать"
                        : root.bad ? "Неверный пароль" : root.user ? root.user.name + " · WynlandOS" : ""
                    size: 14; w: 600; topPadding: root.s(4)
                    color: root.bad ? root.error : root.fgSurfaceVar
                }
                Item { width: 1; height: root.s(26) }
                Rectangle {
                    id: field
                    width: parent.width; height: root.s(58); radius: height / 2
                    color: root.surfaceHighest
                    border.width: root.state_ === "idle" ? 0 : 2
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
                    Icon { x: root.s(18); anchors.verticalCenter: parent.verticalCenter; text: "key"; fill: true; size: 22; color: root.bad ? root.error : root.fgSurfaceVar }
                    Row {
                        x: root.s(52); anchors.verticalCenter: parent.verticalCenter; spacing: root.s(7)
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
                        x: root.s(52); anchors.verticalCenter: parent.verticalCenter
                        visible: !input.text.length
                        text: root.state_ === "idle" ? "Нажмите любую клавишу" : "Пароль"; size: 15; w: 500; color: root.fgSurfaceVar
                    }
                    // go: the field's end
                    Rectangle {
                        width: root.s(46); height: width; radius: gm.containsMouse ? root.s(15) : width / 2
                        anchors.right: parent.right; anchors.rightMargin: root.s(6); anchors.verticalCenter: parent.verticalCenter
                        color: root.state_ === "busy" ? root.surfaceHigh : root.primary
                        scale: gm.pressed ? .9 : 1
                        Behavior on radius { NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spring } }
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: root.spring } }
                        Icon {
                            anchors.centerIn: parent; size: 24; fill: true
                            text: root.state_ === "busy" ? "progress_activity" : "arrow_forward"
                            color: root.state_ === "busy" ? root.fgSurfaceVar : root.fgPrimary
                            RotationAnimation on rotation { running: root.state_ === "busy"; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
                        }
                        MouseArea { id: gm; anchors.fill: parent; hoverEnabled: true; onClicked: { root.wake(); root.submit(); } }
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
                Item { width: 1; height: root.s(22) }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.s(10)
                    Chip { icon: "group"; text: root.users.length > 1 ? (root.current + 1) + " из " + root.users.length : "1 учётная запись" }
                    Chip { icon: "language"; text: "RU" }
                }
            }
        }
    }

    // ---- any key or click wakes the field
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
    component Chip: Rectangle {
        id: ch
        property string icon
        property string text
        width: cr.implicitWidth + root.s(28); height: root.s(40); radius: root.s(14)
        color: root.alpha(root.surfaceHigh, .9)
        Row {
            id: cr; anchors.centerIn: parent; spacing: root.s(7)
            Icon { text: ch.icon; fill: true; size: 18; color: root.primary }
            Label { text: ch.text; size: 13; anchors.verticalCenter: parent.verticalCenter; color: root.fgSurfaceVar }
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

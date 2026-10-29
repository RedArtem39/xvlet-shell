import QtQuick
import QtQuick.Effects
import Quickshell
import qs.components
import qs.services

// A widget's face: what a type looks like in one of its variants, at any
// size (everything scales with the box)
Item {
    id: root
    property string t
    property string v
    readonly property real sz: Math.min(width, height)

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Loader {
        anchors.fill: parent
        sourceComponent: {
            if (root.t === "clock") return ({ lumen: lumen, cookie: cookieClock, digital: digital, stretched: stretched })[root.v] || lumen;
            if (root.t === "weather") return ({ full: wFull, round: wRound, compact: wCompact })[root.v] || wFull;
            if (root.t === "music") return root.v === "card" ? mCard : vinyl;
            if (["cpu", "ram", "disk", "temp", "battery"].includes(root.t)) return root.v === "bar" ? mBar : mWave;
            return ({ user: user, cal: cal, notes: notes, photo: photo })[root.t] || null;
        }
    }

    // ---- clocks ----
    Component {
        id: lumen
        // a dial: twelve numbers round the edge, the current hour's lit,
        // the hands in primary and tertiary, a thin second hand
        Item {
            Rectangle { anchors.fill: parent; radius: width / 2; color: Theme.primaryContainer }
            Repeater {
                model: 12
                Label {
                    required property int index
                    readonly property real a: (index + 1) / 12 * Math.PI * 2 - Math.PI / 2
                    readonly property bool now: ((clock.date.getHours() % 12) || 12) === index + 1
                    x: parent.width / 2 + Math.cos(a) * parent.width * .38 - width / 2
                    y: parent.height / 2 + Math.sin(a) * parent.height * .38 - height / 2
                    text: index + 1; size: root.sz * .07; w: Font.Bold
                    color: now ? Theme.fgPrimary : Theme.alpha(Theme.fgPrimaryContainer, .7)
                    Rectangle { z: -1; anchors.centerIn: parent; visible: parent.now; width: root.sz * .13; height: width; radius: width / 2; color: Theme.primary }
                }
            }
            Hand { len: .26; thick: .05; c: Theme.primary; turn: (clock.date.getHours() % 12 + clock.date.getMinutes() / 60) / 12 }
            Hand { len: .36; thick: .035; c: Theme.tertiary; turn: (clock.date.getMinutes() + clock.date.getSeconds() / 60) / 60 }
            Hand { len: .4; thick: .008; c: Theme.fgPrimaryContainer; turn: clock.date.getSeconds() / 60 }
            Rectangle { anchors.centerIn: parent; width: root.sz * .05; height: width; radius: width / 2; color: Theme.fgPrimaryContainer }
        }
    }
    component Hand: Rectangle {
        property real len
        property real thick
        property color c
        property real turn
        width: root.sz * thick; height: root.sz * len; radius: width / 2; color: c
        x: root.width / 2 - width / 2; y: root.height / 2 - height
        transformOrigin: Item.Bottom
        rotation: turn * 360
    }
    Component {
        id: cookieClock
        Item {
            MShape { anchors.fill: parent; shape: Theme.shCookie12; color: Theme.surfaceHigh }
            Hand { len: .24; thick: .07; c: Theme.primary; turn: (clock.date.getHours() % 12 + clock.date.getMinutes() / 60) / 12 }
            Hand { len: .34; thick: .05; c: Theme.tertiary; turn: clock.date.getMinutes() / 60 }
            Rectangle { anchors.centerIn: parent; width: root.sz * .08; height: width; radius: width / 2; color: Theme.fgSurface }
        }
    }
    Component {
        id: digital
        Column {
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            spacing: -root.height * .06
            Label { text: Qt.formatTime(clock.date, "hh"); size: root.height * .38; w: Font.Black; color: Theme.fgSurface; style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, .25) }
            Label { text: Qt.formatTime(clock.date, "mm"); size: root.height * .38; w: Font.Black; color: Theme.primary; style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, .25) }
            Label { text: clock.date.toLocaleDateString(Qt.locale("ru_RU"), "dddd, d MMMM"); size: root.height * .06; w: Font.Bold; color: Theme.fgSurface; topPadding: root.height * .08 }
        }
    }
    Component {
        id: stretched
        Label {
            text: Qt.formatTime(clock.date, "hh:mm")
            size: root.height * 1.05; w: Font.Black
            color: Theme.primary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.Fit
            minimumPixelSize: 12
            width: root.width; height: root.height
        }
    }

    // ---- weather ----
    Component {
        id: wFull
        Rectangle {
            radius: Theme.r; color: Theme.alpha(Theme.surfaceLow, .9)
            Row {
                x: root.sz * .07; y: root.sz * .07; spacing: root.sz * .06
                MShape { width: root.sz * .3; height: width; shape: Theme.shSunny; color: Weather.ok ? Theme.oklch(85, .14, 85) : Theme.surfaceHighest
                    RotationAnimation on rotation { from: 0; to: 360; duration: 30000; loops: Animation.Infinite; running: !Theme.still }
                    MIcon { anchors.centerIn: parent; visible: !Weather.ok; text: "cloud_off"; size: parent.width * .4 } }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Label { text: Weather.ok ? Weather.sign(Weather.temp) : "нет данных"; size: root.sz * (Weather.ok ? .22 : .1); w: Font.Light }
                    Label { text: Weather.ok ? Weather.desc + (Weather.place ? " · " + Weather.place : "") : "нет сети"; size: root.sz * .06; dim: true }
                }
            }
            Row {
                visible: Weather.ok
                anchors.bottom: parent.bottom; anchors.bottomMargin: root.sz * .06; x: root.sz * .07
                spacing: root.sz * .025
                Repeater { model: Weather.days
                    Rectangle { id: wd; required property var modelData
                        width: (root.width - root.sz * .14 - root.sz * .075) / 4; height: root.sz * .3; radius: width * .3; color: Theme.surfaceHigh
                        Column { anchors.centerIn: parent
                            Label { text: wd.modelData.d; size: root.sz * .055; anchors.horizontalCenter: parent.horizontalCenter }
                            MIcon { text: wd.modelData.icon; fill: true; size: root.sz * .09; color: Theme.primary; anchors.horizontalCenter: parent.horizontalCenter }
                            Label { text: Weather.sign(wd.modelData.t); size: root.sz * .055; anchors.horizontalCenter: parent.horizontalCenter } } } }
            }
        }
    }
    Component {
        id: wRound
        Rectangle {
            radius: width / 2; color: Theme.primaryContainer
            Column { anchors.centerIn: parent
                MIcon { text: Weather.icon; fill: true; size: root.sz * .3; color: Theme.fgPrimaryContainer; anchors.horizontalCenter: parent.horizontalCenter }
                Label { text: Weather.ok ? Weather.temp + "°" : "нет"; size: root.sz * .2; w: Font.Bold; color: Theme.fgPrimaryContainer; anchors.horizontalCenter: parent.horizontalCenter } }
        }
    }
    Component {
        id: wCompact
        Rectangle {
            radius: height / 2; color: Theme.alpha(Theme.surfaceLow, .9)
            Row { anchors.centerIn: parent; spacing: root.height * .15
                MIcon { text: Weather.icon; fill: true; size: root.height * .4; color: Theme.primary }
                Label { text: Weather.ok ? Weather.sign(Weather.temp) : "нет"; size: root.height * .32; w: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                Label { text: Weather.ok ? Weather.desc : ""; size: root.height * .18; dim: true; anchors.verticalCenter: parent.verticalCenter } }
        }
    }

    // ---- music ----
    Component {
        id: vinyl
        Item {
            Rectangle { anchors.fill: parent; anchors.margins: root.sz * .06; radius: width / 2; color: "#0d0d10"
                RotationAnimation on rotation { from: 0; to: 360; duration: 6000; loops: Animation.Infinite; running: Media.playing && !Theme.still }
                Repeater { model: 6
                    Rectangle { required property int index; anchors.centerIn: parent; width: parent.width * (.92 - index * .08); height: width; radius: width / 2; color: "transparent"; border.width: 1; border.color: Qt.rgba(1, 1, 1, .06) } }
                MShape { anchors.centerIn: parent; width: parent.width * .4; height: width; shape: Theme.shCookie9; color: Theme.primary
                    MIcon { anchors.centerIn: parent; text: "music_note"; fill: true; size: parent.width * .38; color: Theme.fgPrimary } } }
            Label { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; text: Media.present ? Media.title : "Ничего не играет"; size: root.sz * .05; dim: !Media.present }
            MouseArea { anchors.fill: parent; enabled: !Ui.editing; onClicked: Media.toggle() }
        }
    }
    Component {
        id: mCard
        Rectangle {
            radius: Theme.r; color: Theme.alpha(Theme.surfaceLow, .9)
            MediaCard { anchors.fill: parent; anchors.margins: root.sz * .1; art: root.height * .7 }
        }
    }

    // ---- the machine's numbers ----
    Component {
        id: mWave
        Canvas {
            // a circle filling with a moving liquid surface, the value on it
            id: wv
            property real level: Widgets.value(root.t)
            property real shown: level
            property real ph: 0
            Behavior on shown { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
            NumberAnimation on ph { from: 0; to: Math.PI * 2; duration: 2600; loops: Animation.Infinite; running: !Theme.still }
            onPhChanged: requestPaint()
            onShownChanged: requestPaint()
            property color c1: Theme.surfaceLow
            property color c2: Theme.primary
            property color ink: Theme.fgSurface
            property color ink2: Theme.fgPrimary
            onPaint: {
                const g = getContext("2d"), W = width, H = height, sz = Math.min(W, H), cx = W / 2, cy = H / 2, r = sz * .48;
                g.reset();
                g.save(); g.beginPath(); g.arc(cx, cy, r, 0, Math.PI * 2); g.clip();
                g.fillStyle = c1; g.fillRect(0, 0, W, H);
                const top = cy + r - 2 * r * shown;
                g.beginPath(); g.moveTo(cx - r, H);
                for (let x = cx - r; x <= cx + r; x += 2) g.lineTo(x, top + Math.sin((x - cx) / r * 3 + ph) * sz * .025);
                g.lineTo(cx + r, H); g.closePath(); g.fillStyle = c2; g.fill();
                g.restore();
                g.textAlign = "center"; g.textBaseline = "middle";
                g.fillStyle = shown > .55 ? ink2 : ink;
                g.font = "800 " + Math.round(sz * .2) + "px '" + Theme.font + "'"; g.fillText(Widgets.text(root.t), cx, cy - sz * .03);
                g.font = "700 " + Math.round(sz * .085) + "px '" + Theme.font + "'"; g.globalAlpha = .8; g.fillText(Widgets.label(root.t), cx, cy + sz * .14);
            }
        }
    }
    Component {
        id: mBar
        Rectangle {
            radius: Math.min(height / 2, width * .2); color: Theme.alpha(Theme.surfaceLow, .9); clip: true
            Rectangle { width: parent.width * Widgets.value(root.t); height: parent.height; radius: parent.radius; color: Theme.primary; Behavior on width { SmoothAnim { ms: 800 } } }
            Row {
                x: root.height * .3; anchors.verticalCenter: parent.verticalCenter; spacing: root.height * .2
                MIcon { text: root.t === "battery" ? Power.icon : (Widgets.types[root.t] || {}).i || ""; fill: true; size: root.height * .4; color: Theme.fgSurface }
                Column { anchors.verticalCenter: parent.verticalCenter
                    Label { text: Widgets.text(root.t); size: root.height * .3; w: Font.Black }
                    Label { text: root.t === "battery" ? (Power.present ? (Power.charging ? "заряжается" : "от батареи") : "батареи нет") : Widgets.label(root.t); size: root.height * .15; dim: true } }
            }
        }
    }

    // ---- the rest ----
    Component {
        id: user
        Rectangle {
            radius: Theme.r; color: Theme.alpha(Theme.surfaceLow, .9)
            Row { x: 18; y: 18; spacing: 14
                MShape { width: 64; height: 64; shape: Theme.shCookie9; color: Theme.tertiaryContainer
                    Label { anchors.centerIn: parent; text: (Quickshell.env("USER") || "?")[0].toUpperCase(); size: 26; w: Font.Bold; color: Theme.fgTertiaryContainer } }
                Column { anchors.verticalCenter: parent.verticalCenter
                    Label { text: Quickshell.env("USER") || "user"; size: 19; w: Font.Bold }
                    Label { text: "WynlandOS"; size: 13; dim: true } } }
            Row {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 14; x: 14; spacing: 8
                Repeater { model: [{ k: "lock", i: "lock" }, { k: "logout", i: "logout" }, { k: "reboot", i: "restart_alt" }, { k: "off", i: "power_settings_new" }]
                    IconButton { required property var modelData; icon: modelData.i; size: 56; on: false; onClicked: if (!Ui.editing) Power.act(modelData.k) } }
            }
        }
    }
    Component {
        id: cal
        Rectangle { radius: Theme.r; color: Theme.alpha(Theme.surfaceLow, .9)
            Calendar { anchors.fill: parent; anchors.margins: 18 } }
    }
    Component {
        id: notes
        Rectangle {
            radius: Theme.rm; color: Theme.tertiaryContainer
            rotation: -1.5
            TextEdit {
                anchors.fill: parent; anchors.margins: 18
                text: Config.data.desk.note || "Купить молоко\nДоделать шелл 🙂"
                font.family: Theme.font; font.pixelSize: 17; font.weight: Font.Medium
                color: Theme.fgTertiaryContainer
                wrapMode: TextEdit.Wrap
                readOnly: Ui.editing
                onTextChanged: if (activeFocus) Config.set("desk.note", text)
            }
        }
    }
    Component {
        id: photo
        Item {
            MShape { id: ph; anchors.fill: parent; visible: root.v !== "rounded"; shape: root.v === "round" ? Theme.shCircle : Theme.shCookie9; color: Theme.surfaceHigh; layer.enabled: true }
            Rectangle { id: pr; anchors.fill: parent; visible: root.v === "rounded"; radius: Theme.r; color: Theme.surfaceHigh; layer.enabled: true }
            Image {
                anchors.fill: parent
                source: Walls.list.length ? "file://" + Walls.list[Math.min(Walls.list.length - 1, 1)] : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(width, height)
                layer.enabled: true
                layer.effect: MultiEffect { maskEnabled: true; maskSource: root.v === "rounded" ? pr : ph; maskThresholdMin: .5; maskSpreadAtMin: .2 }
            }
        }
    }
}

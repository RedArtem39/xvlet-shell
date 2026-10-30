import QtQuick
import QtQuick.Effects
import Quickshell
import qs.components
import qs.services

// A widget's face, the prototype's (widgets.js faceHtml/drawWidget,
// shell.css): what a type looks like in one of its variants, at any size --
// everything is in cq, a hundredth of the box's smaller side.
Item {
    id: root
    property string t
    property string v
    readonly property real sz: Math.min(width, height)
    readonly property real cq: sz / 100
    readonly property real hue: Theme.now.h
    readonly property real chroma: Theme.pal.cp

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

    // the glass card most faces sit on
    component Glass: Rectangle {
        radius: Theme.r
        color: Theme.glass
    }

    // ---- clocks ----
    Component {
        id: lumen
        // a dial on the primary container: the twelve numbers lit (and
        // glowing) where a hand passes them, the hour hand tertiary, the
        // minute primary, the second thin
        Canvas {
            id: lc
            property real ms: 0
            property color pc: Theme.primaryContainer
            property color onpc: Theme.fgPrimaryContainer
            property color pri: Theme.primary
            property color ter: Theme.tertiary
            property color fg: Theme.fgSurface
            // (a tick a second while the desktop is seen; once a minute behind windows)
            Timer { interval: Ui.deskLive && !Theme.still ? 1000 : 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { lc.ms = Date.now(); lc.requestPaint(); } }
            onPaint: {
                const g = getContext("2d"), W = width, H = height, S = Math.min(W, H), cx = W / 2, cy = H / 2, now = new Date();
                g.reset();
                g.fillStyle = pc; g.beginPath(); g.arc(cx, cy, S * .47, 0, Math.PI * 2); g.fill();
                const hr = (now.getHours() % 12 + now.getMinutes() / 60) / 12, mn = (now.getMinutes() + now.getSeconds() / 60) / 60, sc = (now.getSeconds() + now.getMilliseconds() / 1000) / 60;
                const hands = [[hr, ter], [mn, pri], [sc, fg]];
                g.textAlign = "center"; g.textBaseline = "middle";
                g.font = "800 " + Math.round(S * .065) + "px '" + Theme.font + "'";
                for (let k = 1; k <= 12; k++) {
                    const a = k / 12, ang = a * Math.PI * 2;
                    let best = 0, col = pri;
                    for (const [p, c] of hands) { let d = Math.abs(p - a); d = Math.min(d, 1 - d); const it = Math.exp(-Math.pow(d / .045, 2)); if (it > best) { best = it; col = c; } }
                    const x = cx + Math.sin(ang) * S * (.385 + .02 * best), y = cy - Math.cos(ang) * S * (.385 + .02 * best);
                    if (best > .05) { g.globalAlpha = best * .3; g.fillStyle = col; g.beginPath(); g.arc(x, y, S * .055, 0, Math.PI * 2); g.fill(); g.globalAlpha = 1; }
                    g.fillStyle = best > .5 ? onpc : col; g.globalAlpha = .35 + .65 * best;
                    g.fillText(k, x, y + S * .004); g.globalAlpha = 1;
                }
                g.lineCap = "round";
                for (const [p, L, Wd, c] of [[hr, S * .2, S * .06, ter], [mn, S * .3, S * .045, pri], [sc, S * .33, S * .015, fg]]) {
                    const ang = p * Math.PI * 2;
                    g.strokeStyle = c; g.lineWidth = Wd;
                    g.beginPath(); g.moveTo(cx, cy); g.lineTo(cx + Math.sin(ang) * L, cy - Math.cos(ang) * L); g.stroke();
                }
                g.fillStyle = fg; g.beginPath(); g.arc(cx, cy, S * .025, 0, Math.PI * 2); g.fill();
            }
        }
    }
    component Hand: Rectangle {
        property real len
        property real thick
        property real turn
        width: root.cq * thick; height: root.cq * len; radius: width / 2
        x: root.width / 2 - width / 2; y: root.height / 2 - height
        transformOrigin: Item.Bottom
        rotation: turn * 360
        Behavior on rotation { enabled: false }
    }
    Component {
        id: cookieClock
        // .ck: a glass cookie, the hour hand primary, the minute tertiary,
        // a dot on the second, the hub
        Item {
            MShape { anchors.fill: parent; shape: Theme.shCookie12; color: Theme.glass }
            Hand { len: 24; thick: 9; color: Theme.primary; turn: (clock.date.getHours() % 12 + clock.date.getMinutes() / 60) / 12 }
            Hand { len: 36; thick: 6.5; color: Theme.tertiary; turn: (clock.date.getMinutes() + clock.date.getSeconds() / 60) / 60 }
            Rectangle {
                // the second: a dot running round
                width: root.cq * 6.5; height: width; radius: width / 2; color: Theme.fgSurface
                readonly property real a: clock.date.getSeconds() / 60 * Math.PI * 2
                x: root.width / 2 + Math.sin(a) * root.cq * 40 - width / 2
                y: root.height / 2 - Math.cos(a) * root.cq * 40 - height / 2
            }
            Rectangle { anchors.centerIn: parent; width: root.cq * 5; height: width; radius: width / 2; color: Theme.surface }
        }
    }
    Component {
        id: digital
        // .mdig: the hours near white, the minutes primary, the date under
        Column {
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            spacing: -root.cq * 46 * .18
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Theme.oklch(10, .05, root.hue, .3); shadowBlur: 1; shadowVerticalOffset: 2 }
            Label { text: Qt.formatTime(clock.date, "hh"); size: root.cq * 46; w: 800; font.letterSpacing: -root.cq * 46 * .04; color: Theme.oklch(97, root.chroma * .2, root.hue); font.features: { "tnum": 1 } }
            Label { text: Qt.formatTime(clock.date, "mm"); size: root.cq * 46; w: 800; font.letterSpacing: -root.cq * 46 * .04; color: Theme.primary; font.features: { "tnum": 1 } }
            Label { text: clock.date.toLocaleDateString(Qt.locale("ru_RU"), "dddd, d MMMM"); size: root.cq * 7; w: 650; color: Theme.oklch(95, .03, root.hue, .85); topPadding: root.cq * 5 + root.cq * 46 * .18 }
        }
    }
    Component {
        id: stretched
        // the time drawn thin and narrow, stretched over the whole box
        Item {
            Text {
                id: st
                text: Qt.formatTime(clock.date, "hh:mm")
                font.family: Theme.font
                font.pixelSize: Math.max(8, root.height * 1.05)
                font.variableAxes: ({ wght: 150, wdth: 25, opsz: 144 })
                color: Theme.oklch(97, root.chroma * .2, root.hue, .92)
                transformOrigin: Item.TopLeft
                scale: 1
                transform: Scale { xScale: st.implicitWidth > 0 ? root.width / st.implicitWidth : 1 }
                y: (root.height - height) / 2
            }
        }
    }

    // ---- weather ----
    readonly property color sun: Theme.oklch(85, .14, 85)
    Component {
        id: wFull
        // .wfull: the sun, the temperature, the place; four days under
        Glass {
            MShape {
                id: sunShape
                x: root.cq * 7; y: (wfTop.height - height) / 2 + root.cq * 7
                width: root.cq * 30; height: width; shape: Theme.shSunny
                color: Weather.ok ? root.sun : Theme.surfaceHighest
                RotationAnimation on rotation { from: 0; to: 360; duration: 30000; loops: Animation.Infinite; running: Weather.ok && Ui.deskLive && !Theme.still }
                MIcon { anchors.centerIn: parent; visible: !Weather.ok; text: "cloud_off"; size: parent.width * .45 }
            }
            Column {
                id: wfTop
                x: sunShape.x + sunShape.width + root.cq * 6; y: root.cq * 7
                Label { text: Weather.ok ? Weather.sign(Weather.temp) : "Нет данных"; size: root.cq * (Weather.ok ? 24 : 11); w: Weather.ok ? 300 : 650; font.letterSpacing: Weather.ok ? -root.cq * 24 * .04 : 0 }
                Label { text: Weather.ok ? Weather.desc + (Weather.place ? " · " + Weather.place : "") : "нет сети"; size: root.cq * 6.5; w: 650; dim: true; topPadding: root.cq }
            }
            Row {
                visible: Weather.ok
                x: root.cq * 7; anchors.bottom: parent.bottom; anchors.bottomMargin: root.cq * 7
                width: parent.width - root.cq * 14
                spacing: root.cq * 2.5
                Repeater { model: Weather.days
                    Rectangle { id: wd; required property var modelData
                        width: (parent.width - root.cq * 2.5 * 3) / 4; height: wdc.implicitHeight + root.cq * 6
                        radius: root.cq * 6; color: Theme.surfaceHigh
                        Column { id: wdc; anchors.centerIn: parent
                            Label { text: wd.modelData.d; size: root.cq * 5.5; w: 650; anchors.horizontalCenter: parent.horizontalCenter }
                            MIcon { text: wd.modelData.icon; fill: true; size: root.cq * 9; color: Theme.primary; anchors.horizontalCenter: parent.horizontalCenter; topPadding: root.cq * 2; bottomPadding: root.cq * 2 }
                            Label { text: Weather.sign(wd.modelData.t); size: root.cq * 5.5; w: 650; anchors.horizontalCenter: parent.horizontalCenter } } } }
            }
        }
    }
    Component {
        id: wRound
        // .wpill: a glass capsule turned 45 degrees, the sun and the degrees upright
        Item {
            Rectangle {
                anchors.centerIn: parent
                width: root.cq * 52; height: root.cq * 118; radius: root.cq * 26
                rotation: 45
                color: Theme.glass
            }
            Column {
                anchors.centerIn: parent; spacing: root.cq * 2
                MIcon { text: Weather.ok ? Weather.icon : "cloud_off"; fill: true; size: root.cq * 30; color: Weather.ok ? root.sun : Theme.fgSurfaceVar; anchors.horizontalCenter: parent.horizontalCenter }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    Label { text: Weather.ok ? Weather.temp : "—"; size: root.cq * 26; w: 900; lineHeight: .9 }
                    Label { text: "°"; size: root.cq * 12; w: 900; visible: Weather.ok }
                }
            }
        }
    }
    Component {
        id: wCompact
        // .wcomp: a glass pill -- the sun, the temperature, the sky
        Glass {
            radius: height / 2
            Row {
                x: root.cq * 12; anchors.verticalCenter: parent.verticalCenter; spacing: root.cq * 6
                MIcon { text: Weather.ok ? Weather.icon : "cloud_off"; fill: true; size: root.cq * 55; color: Weather.ok ? root.sun : Theme.fgSurfaceVar; anchors.verticalCenter: parent.verticalCenter }
                Label { text: Weather.ok ? Weather.sign(Weather.temp) : "нет"; size: root.cq * 42; w: 800; anchors.verticalCenter: parent.verticalCenter }
                Label { text: Weather.ok ? Weather.desc : ""; size: root.cq * 20; w: 650; dim: true; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }

    // ---- music ----
    Component {
        id: vinyl
        // a record (grooves, the label a gradient) spinning while it plays,
        // a ring of 72 strokes round it that dance with the music (drawn
        // levels: there is no spectrum analyser -- still and short when
        // nothing plays), a glow behind on the bass
        Item {
            Canvas {
                id: ring
                anchors.fill: parent
                property real tm: 0
                property color pri: Theme.primary
                property color ter: Theme.tertiary
                Timer { interval: 40; running: Media.playing && Ui.deskLive && !Theme.still; repeat: true; onTriggered: { ring.tm = Date.now() / 1000; ring.requestPaint(); } }
                onPriChanged: requestPaint()
                Component.onCompleted: requestPaint()
                onPaint: {
                    const g = getContext("2d"), W = width, H = height, S = Math.min(W, H), cx = W / 2, cy = H / 2, n = 72, t = tm, on = Media.playing, sp = [];
                    for (let i = 0; i < n; i++) {
                        const f = i / n;
                        const v = .55 * Math.exp(-f * 2.2) * (.6 + .4 * Math.sin(t * 7.3 + i * .9)) + .25 * (.5 + .5 * Math.sin(t * 3.1 + i * 1.7)) * (1 - f * .6) + .12 * Math.pow(Math.sin(t * 11 + i * 2.3), 2);
                        sp.push(on ? Math.max(.04, Math.min(1, v)) : .04);
                    }
                    g.reset();
                    const bass = sp[0] * .6 + sp[1] * .4, R0 = S * .34;
                    if (on) { g.fillStyle = pri; g.globalAlpha = .06 + bass * .12; g.beginPath(); g.arc(cx, cy, R0 + S * .1 + bass * S * .04, 0, Math.PI * 2); g.fill(); g.globalAlpha = 1; }
                    g.lineCap = "round"; g.lineWidth = S * .012;
                    for (let i = 0; i < n; i++) {
                        const a = i / n * Math.PI * 2, s = sp[i < n / 2 ? i : n - i], L = S * (.015 + s * .11);
                        g.strokeStyle = i % 2 ? pri : ter; g.globalAlpha = .5 + s * .5;
                        g.beginPath(); g.moveTo(cx + Math.cos(a) * (R0 + S * .03), cy + Math.sin(a) * (R0 + S * .03)); g.lineTo(cx + Math.cos(a) * (R0 + S * .03 + L), cy + Math.sin(a) * (R0 + S * .03 + L)); g.stroke();
                    }
                }
            }
            Item {
                id: disc
                anchors.centerIn: parent
                width: root.cq * 64; height: width
                RotationAnimation on rotation { from: 0; to: 360; duration: 6000; loops: Animation.Infinite; running: Media.playing && Ui.deskLive && !Theme.still }
                RectangularShadow { anchors.fill: parent; radius: width / 2; blur: root.cq * 12; offset.y: root.cq * 3; spread: -root.cq * 3; color: Qt.rgba(0, 0, 0, .8) }
                // the grooves: rings of two tones
                Canvas {
                    anchors.fill: parent
                    property color a: Theme.oklch(14, .02, root.hue)
                    property color b: Theme.oklch(18, .02, root.hue)
                    onAChanged: requestPaint()
                    onPaint: {
                        const g = getContext("2d"), r = width / 2, step = root.cq * 2.2, dark = root.cq * 1.2;
                        g.reset();
                        g.fillStyle = b; g.beginPath(); g.arc(r, r, r, 0, Math.PI * 2); g.fill();
                        g.fillStyle = a;
                        for (let k = r; k > 0; k -= step) { g.beginPath(); g.arc(r, r, k, 0, Math.PI * 2); g.arc(r, r, Math.max(0, k - dark), 0, Math.PI * 2, true); g.fill(); }
                    }
                }
                Rectangle {
                    // the label
                    anchors.centerIn: parent
                    width: parent.width * .4; height: width; radius: width / 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.oklch(72, .15, root.hue + 60) }
                        GradientStop { position: .5; color: Theme.oklch(55, .17, root.hue) }
                        GradientStop { position: 1; color: Theme.oklch(40, .12, root.hue - 40) }
                    }
                    rotation: 45
                }
                MIcon { anchors.centerIn: parent; text: "music_note"; fill: true; size: root.cq * 12; color: Qt.rgba(1, 1, 1, .87); rotation: -disc.rotation }
            }
            MouseArea { anchors.fill: parent; enabled: !Ui.editing; onClicked: Media.toggle() }
        }
    }
    Component {
        id: mCard
        Glass {
            MediaCard { anchors.fill: parent; anchors.margins: root.cq * 7; art: root.cq * 36 * root.width / root.sz > root.height - root.cq * 14 ? root.height - root.cq * 14 : root.cq * 36 * root.width / root.sz; small: true }
        }
    }

    // ---- the machine's numbers: a liquid level ----
    component Liquid: Canvas {
        id: lq
        property bool round: true
        property real level: Widgets.value(root.t)
        property real shown: level
        property real tm: 0
        property color s1: Theme.surfaceHigh
        property color pri: Theme.primary
        property color onp: Theme.fgPrimary
        property color fg: Theme.fgSurface
        Behavior on shown { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
        // the wave: 10 frames a second, and only while the desktop is seen
        Timer { interval: 100; running: Ui.deskLive && !Theme.still; repeat: true; onTriggered: { lq.tm = Date.now() / 1000 + root.t.length; lq.requestPaint(); } }
        onShownChanged: requestPaint()
        onPaint: {
            const g = getContext("2d"), W = width, H = height, val = shown, t = tm;
            g.reset();
            // the liquid's outline, as a path the text can be clipped to
            const liquid = (x, y, w, hh, vertical) => {
                g.beginPath();
                if (vertical) {
                    const top = y + hh * (1 - val), A = Math.min(hh * .035, 8);
                    g.moveTo(x, y + hh);
                    for (let k = 0; k <= w; k += 4) g.lineTo(x + k, top + Math.sin(k / w * Math.PI * 3 + t * 2.2) * A);
                    g.lineTo(x + w, y + hh);
                } else {
                    const right = x + w * val, A = Math.min(w * .02, 7);
                    g.moveTo(x, y);
                    for (let k = 0; k <= hh; k += 3) g.lineTo(right + Math.sin(k / hh * Math.PI * 2 + t * 2.4) * A, y + k);
                    g.lineTo(x, y + hh);
                }
                g.closePath();
            };
            if (round) {
                const S = Math.min(W, H), cx = W / 2, cy = H / 2, r = S * .48;
                g.save(); g.beginPath(); g.arc(cx, cy, r, 0, Math.PI * 2); g.clip();
                g.fillStyle = s1; g.fillRect(0, 0, W, H);
                liquid(cx - r, cy - r, r * 2, r * 2, true); g.fillStyle = pri; g.fill();
                g.restore();
                g.textAlign = "center"; g.textBaseline = "middle";
                const draw = c => {
                    g.fillStyle = c; g.font = "800 " + Math.round(S * .2) + "px '" + Theme.font + "'"; g.fillText(Widgets.text(root.t), cx, cy - S * .03);
                    g.font = "700 " + Math.round(S * .085) + "px '" + Theme.font + "'"; g.globalAlpha = .8; g.fillText(Widgets.label(root.t), cx, cy + S * .14); g.globalAlpha = 1;
                };
                draw(fg);
                g.save(); g.beginPath(); g.arc(cx, cy, r, 0, Math.PI * 2); g.clip(); liquid(cx - r, cy - r, r * 2, r * 2, true); g.clip(); draw(onp); g.restore();
            } else {
                const R = Math.min(H / 2, W * .2);
                g.save(); g.beginPath(); g.roundedRect(0, 0, W, H, R, R); g.clip();
                g.fillStyle = s1; g.fillRect(0, 0, W, H);
                liquid(0, 0, W, H, false); g.fillStyle = pri; g.fill();
                g.restore();
                g.textBaseline = "middle"; g.textAlign = "left";
                const ic = { cpu: "memory", ram: "memory_alt", disk: "hard_drive", temp: "device_thermostat", battery: "battery_5_bar" }[root.t];
                const sub = root.t === "battery" ? (Power.present ? (Power.charging ? "заряжается" : "от батареи") : "батареи нет") : Widgets.label(root.t);
                const draw = (c, acc) => {
                    g.font = Math.round(H * .4) + "px '" + Theme.icons + "'"; g.fillStyle = acc; g.fillText(ic, H * .3, H / 2);
                    g.fillStyle = c; g.font = "850 " + Math.round(H * .32) + "px '" + Theme.font + "'"; g.fillText(Widgets.text(root.t), H * .8, H * .42);
                    g.font = "700 " + Math.round(H * .16) + "px '" + Theme.font + "'"; g.globalAlpha = .8; g.fillText(sub, H * .8, H * .72); g.globalAlpha = 1;
                };
                draw(fg, pri);
                g.save(); g.beginPath(); g.roundedRect(0, 0, W, H, R, R); g.clip(); liquid(0, 0, W, H, false); g.clip(); draw(onp, onp); g.restore();
            }
        }
    }
    Component { id: mWave; Liquid { round: true } }
    Component { id: mBar; Liquid { round: false } }

    // ---- the rest ----
    Component {
        id: user
        // .wuser: the avatar, the name, the lock; three held buttons --
        // restart, power off, log out (hold a second: it fills, then acts)
        Glass {
            Row {
                x: root.cq * 7; y: root.cq * 7; spacing: 14
                width: parent.width - root.cq * 14
                MShape { width: 64; height: 64; shape: Theme.shCookie9; color: Theme.tertiaryContainer
                    Label { anchors.centerIn: parent; text: (Quickshell.env("USER") || "?")[0].toUpperCase(); size: 26; w: 750; color: Theme.fgTertiaryContainer } }
                Column { anchors.verticalCenter: parent.verticalCenter; width: parent.width - 64 - 44 - 28
                    Label { text: Quickshell.env("USER") || "user"; size: 18; w: 750 }
                    Label { text: "WynlandOS"; size: 12; w: 600; dim: true; topPadding: 3 } }
                Rectangle {
                    width: 44; height: 44; radius: 22; color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                    MIcon { anchors.centerIn: parent; text: "lock"; size: 22; color: Theme.fgPrimary }
                    MouseArea { anchors.fill: parent; enabled: !Ui.editing; onClicked: Ui.lock() }
                }
            }
            Row {
                x: root.cq * 7; anchors.bottom: parent.bottom; anchors.bottomMargin: root.cq * 7
                width: parent.width - root.cq * 14; spacing: 8
                Repeater {
                    model: [{ k: "logout", i: "logout", c: Theme.oklch(70, .12, 250) }, { k: "reboot", i: "restart_alt", c: Theme.oklch(72, .14, 60) }, { k: "off", i: "power_settings_new", c: Theme.oklch(66, .18, 25) }]
                    Rectangle {
                        id: cap
                        required property var modelData
                        width: (parent.width - 16) / 3; height: 46
                        radius: capm.containsMouse ? 14 : 23
                        color: Theme.surfaceHigh
                        clip: true
                        Behavior on radius { SpringAnim { ms: 350 } }
                        Rectangle { height: parent.height; width: parent.width * capm.hold; color: cap.modelData.c }
                        MIcon { anchors.centerIn: parent; text: cap.modelData.i; size: 22; color: capm.hold > .99 ? "#111" : cap.modelData.c }
                        MouseArea {
                            id: capm
                            anchors.fill: parent; hoverEnabled: true; enabled: !Ui.editing
                            property real hold: 0
                            NumberAnimation on hold { id: fillUp; running: false; to: 1; duration: 1000 }
                            onPressed: { fillUp.from = hold; fillUp.restart(); }
                            onReleased: { fillUp.stop(); if (hold >= .99) Power.act(cap.modelData.k); hold = 0; }
                        }
                    }
                }
            }
        }
    }
    Component {
        id: cal
        Glass {
            Calendar { anchors.fill: parent; anchors.margins: 18 }
        }
    }
    Component {
        id: notes
        // .wnote: a note in the tertiary's neighbour hue; a pin, the text
        Rectangle {
            radius: Theme.r
            readonly property real nh: root.hue + 80
            color: Theme.dark ? Theme.oklch(40, .08, nh) : Theme.oklch(88, .09, nh)
            readonly property color ink: Theme.dark ? Theme.oklch(95, .03, nh) : Theme.oklch(25, .05, nh)
            Row {
                x: 20; y: 18; spacing: 6
                MIcon { text: "push_pin"; fill: true; size: 18; color: parent.parent.ink }
                Label { text: "Заметка"; size: 14; w: 750; color: parent.parent.ink; anchors.verticalCenter: parent.verticalCenter }
            }
            TextEdit {
                x: 20; y: 18 + 24 + 8; width: parent.width - 40; height: parent.height - y - 18
                text: Config.data.desk.note || ""
                font.family: Theme.font; font.pixelSize: 15; font.weight: 500; font.variableAxes: ({ wght: 500 })
                color: parent.ink
                wrapMode: TextEdit.Wrap
                readOnly: Ui.editing
                onTextChanged: if (activeFocus) Config.set("desk.note", text)
                Label { visible: !parent.text; text: "Что-нибудь важное…"; size: 15; w: 500; color: parent.color; opacity: .55 }
            }
        }
    }
    Component {
        id: photo
        Item {
            MShape { id: ph; anchors.fill: parent; visible: root.v !== "rounded"; shape: root.v === "round" ? Theme.shCircle : Theme.shCookie12; color: Theme.surfaceHigh; layer.enabled: true }
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

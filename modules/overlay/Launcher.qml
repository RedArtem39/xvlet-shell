import QtQuick
import QtQuick.Effects
import Quickshell
import qs.components
import qs.services

// The launcher, the prototype's (launcher.js, shell.css #launch): a sheet
// out of the screen's bottom edge (or in the middle, or under the bar's
// logo). The search, the categories, the apps in a grid or a list; the
// arrows move, Enter opens, Tab steps through the modes: > actions,
// = calculator, : emoji, @ wallpapers.
Item {
    id: root
    property bool shown: false
    property string raw: ""
    property string cat: ""
    property int sel: 0
    readonly property var lcfg: Config.data.launcher
    readonly property var bcfg: Config.data.bar
    readonly property string pos: lcfg.pos || "bottom"
    readonly property bool grid: lcfg.view !== "list"
    readonly property bool cats: lcfg.cats !== false
    readonly property string mode: /^[>=@:]/.test(raw) ? raw[0] : ""
    readonly property string q: (mode ? raw.slice(1) : raw).trim().toLowerCase()
    readonly property real barT: bcfg.style === "islands" ? bcfg.height + 10 : bcfg.height

    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    Behavior on opacity { SmoothAnim { ms: 220 } }
    onShownChanged: if (shown) { field.text = ""; sel = 0; cat = ""; field.forceActiveFocus(); }
    onRawChanged: sel = 0
    onCatChanged: sel = 0

    // ---- what the results are ----
    readonly property var acts: [
        { n: "Настройки шелла", i: "tune", s: "xvlet", f: () => Ui.openSettings() },
        { n: "Сменить обои", i: "wallpaper", s: "Оформление", f: () => { Ui.closeAll(); Ui.wallpick = true; } },
        { n: "Изменить виджеты", i: "widgets", s: "Рабочий стол", f: () => { Ui.closeAll(); Ui.editing = true; } },
        { n: "Светлая тема", i: "light_mode", s: "Оформление", f: () => { Ui.closeAll(); Config.set("theme.mode", "light"); } },
        { n: "Тёмная тема", i: "dark_mode", s: "Оформление", f: () => { Ui.closeAll(); Config.set("theme.mode", "dark"); } },
        { n: "Не беспокоить", i: "do_not_disturb_on", s: "Уведомления", f: () => { Ui.closeAll(); Config.set("notif.dnd", !Config.data.notif.dnd); } },
        { n: "Заблокировать", i: "lock", s: "Сеанс", f: () => Ui.lock() },
        { n: "Выйти", i: "logout", s: "Сеанс", danger: true, f: () => { Ui.closeAll(); Power.act("logout"); } },
        { n: "Перезагрузить", i: "restart_alt", s: "Сеанс", danger: true, f: () => { Ui.closeAll(); Power.act("reboot"); } },
        { n: "Выключить", i: "power_settings_new", s: "Сеанс", danger: true, f: () => { Ui.closeAll(); Power.act("off"); } }
    ]
    readonly property var emoji: "😀 😁 😂 🤣 😊 😍 😘 😎 🤔 😴 😭 😡 🤯 🥳 😇 🙃 😉 😏 🙂 🤗 👍 👎 👏 🙏 💪 🤝 👋 ✌️ 🤞 👀 🔥 ✨ 💯 ❤️ 💔 💜 💙 💚 💛 🖤 🎉 🎁 🎵 🎮 💻 📱 ☕ 🍕 🍔 🍺 🌙 ☀️ ⭐ 🌈 ❄️ ⚡ 🌊 🌲 🐱 🐶 🦊 🐸 🚀 ✈️ 🏠 📌 ✅ ❌ ⚠️ 💡 🔒 🔑 📦 🛠️ 🧠 💬 📷 🎧 🕹️ 🌍".split(" ")
    readonly property string calc: {
        if (mode !== "=") return "";
        const e = q.replace(/,/g, ".").replace(/×/g, "*").replace(/÷/g, "/").replace(/\^/g, "**").replace(/(\d+(?:\.\d+)?)%/g, "($1/100)");
        if (!e || !/^[\d+\-*/().\s]+$/.test(e)) return "—";
        try { const r = Function("\"use strict\";return (" + e + ")")(); if (Number.isFinite(r)) return (+r.toPrecision(12)).toLocaleString(Qt.locale("ru_RU"), "f", 10).replace(/[,.]?0+$/, ""); } catch (x) {}
        return "—";
    }
    readonly property int cols: mode === ":" ? 10 : mode === "@" ? 4 : mode === ">" || mode === "=" || !grid ? 1 : cats ? 5 : 6
    readonly property var items: {
        if (mode === ">") return acts.filter(a => a.n.toLowerCase().includes(q));
        if (mode === ":") return emoji;
        if (mode === "@") return Walls.list.filter(p => Walls.nameOf(p).toLowerCase().includes(q));
        if (mode === "=") return calc !== "—" ? [calc] : [];
        const l = Apps.search(q, cat);
        return grid ? l : l.slice(0, 6);
    }
    function run(i) {
        const it = items[i];
        if (it === undefined) return;
        if (mode === ">") { it.f(); return; }
        if (mode === ":" || mode === "=") { Quickshell.clipboardText = it; Ui.closeAll(); Notifs.toast(mode === ":" ? "mood" : "content_copy", mode === ":" ? "Эмодзи скопирован" : "Скопировано", mode === ":" ? it + " — вставьте куда нужно" : it); return; }
        if (mode === "@") { Walls.set(it); return; }
        Ui.closeAll(); Apps.launch(it);
    }
    function nextMode(back) {
        const ms = ["", ">", "=", ":", "@"], m = ms[(ms.indexOf(mode) + (back ? ms.length - 1 : 1)) % ms.length];
        field.text = m + field.text.replace(/^[>=@:]/, "");
    }

    // ---- the sheet ----
    Item {
        id: sheet
        width: root.pos === "bar" ? 760 : 900
        height: col.implicitHeight + 20 + (root.pos === "bottom" ? 26 : 20)
        readonly property bool atBottom: root.pos === "bottom"
        readonly property real by: root.bcfg.pos === "bottom" ? root.barT : 0
        x: root.pos === "bar" ? (root.bcfg.pos === "right" ? parent.width - root.barT - 10 - width : root.bcfg.pos === "left" ? root.barT + 10 : 12)
                              : (parent.width - width) / 2
        y: atBottom ? parent.height - height - by
         : root.pos === "center" ? 200
         : (root.bcfg.pos === "bottom" ? parent.height - root.barT - 10 - height : root.bcfg.pos === "top" ? root.barT + 10 : 12)
        transformOrigin: atBottom ? Item.Bottom : root.pos === "center" ? Item.Top : Item.TopLeft
        transform: Translate {
            y: root.shown ? 0 : sheet.atBottom ? sheet.height : root.pos === "center" ? 40 : -20
            Behavior on y { SpringAnim { ms: 500 } }
        }
        scale: root.shown ? 1 : .94
        Behavior on scale { SpringAnim { ms: 500 } }
        MouseArea { anchors.fill: parent; onWheel: w => w.accepted = true }

        RectangularShadow {
            anchors.fill: body
            radius: Theme.r; blur: 80; spread: -30; offset.y: sheet.atBottom ? -20 : 24
            color: Theme.shadow
        }
        Rectangle {
            id: body
            anchors.fill: parent
            topLeftRadius: Theme.r; topRightRadius: Theme.r
            bottomLeftRadius: sheet.atBottom ? 0 : Theme.r; bottomRightRadius: sheet.atBottom ? 0 : Theme.r
            color: sheet.atBottom ? Theme.surface : Theme.surfaceLow
            border.width: sheet.atBottom ? 0 : 1; border.color: Theme.alpha(Theme.fgSurface, .06)
        }
        // out of the edge: concave fillets where the sheet meets it
        Fillet { visible: sheet.atBottom; anchors.right: body.left; anchors.bottom: body.bottom; hole: "tl" }
        Fillet { visible: sheet.atBottom; anchors.left: body.right; anchors.bottom: body.bottom; hole: "tr" }

        Column {
            id: col
            x: 20; y: 20
            width: parent.width - 40
            // the search
            Rectangle {
                width: parent.width; height: 64
                radius: field.activeFocus ? 22 : 32
                color: field.activeFocus ? Theme.surfaceHighest : Theme.surfaceHigh
                Behavior on radius { SpringAnim { ms: 450 } }
                Behavior on color { ColorAnim { ms: 250 } }
                MIcon {
                    x: 22; anchors.verticalCenter: parent.verticalCenter
                    text: ({ "": "search", ">": "bolt", "=": "calculate", "@": "wallpaper", ":": "mood" })[root.mode]
                    size: 26; color: field.activeFocus ? Theme.fgSurface : Theme.fgSurfaceVar
                }
                TextInput {
                    id: field
                    x: 62; width: parent.width - 84; anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.font; font.pixelSize: 19; font.weight: 500; font.variableAxes: ({ wght: 500 })
                    color: Theme.fgSurface
                    selectionColor: Theme.primary; selectedTextColor: Theme.fgPrimary
                    clip: true
                    onTextChanged: root.raw = text
                    Keys.onTabPressed: root.nextMode(false)
                    Keys.onBacktabPressed: root.nextMode(true)
                    Keys.onDownPressed: root.sel = Math.min(root.items.length - 1, root.sel + root.cols)
                    Keys.onUpPressed: root.sel = Math.max(0, root.sel - root.cols)
                    Keys.onRightPressed: e => { if (root.cols > 1 && cursorPosition === text.length) root.sel = Math.min(root.items.length - 1, root.sel + 1); else e.accepted = false; }
                    Keys.onLeftPressed: e => { if (root.cols > 1 && cursorPosition === text.length && root.sel > 0) root.sel--; else e.accepted = false; }
                    Keys.onReturnPressed: root.run(root.sel)
                    Keys.onEscapePressed: Ui.closeAll()
                    Label { anchors.verticalCenter: parent.verticalCenter; visible: !parent.text; text: "Поиск"; size: 19; w: 500; dim: true }
                }
            }
            Item { width: 1; height: 16 }
            Row {
                spacing: 14
                // the categories
                Column {
                    id: catcol
                    visible: root.cats
                    opacity: root.mode ? 0 : 1
                    width: 168
                    spacing: 2
                    Repeater {
                        model: Apps.cats
                        Rectangle {
                            id: c
                            required property var modelData
                            readonly property bool on: root.cat === modelData.k
                            width: catcol.width; height: 44
                            radius: on ? 22 : cm.containsMouse ? 14 : 22
                            color: on ? Theme.secondaryContainer : cm.containsMouse ? Theme.surfaceHigh : "transparent"
                            Behavior on radius { SpringAnim { ms: 400 } }
                            Behavior on color { ColorAnim { ms: 200 } }
                            Row {
                                x: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                                MIcon { text: c.modelData.i; fill: c.on; size: 20; color: cl.color }
                                Label { id: cl; text: c.modelData.n; size: 14; w: 600; color: c.on ? Theme.fgSecondaryContainer : Theme.fgSurfaceVar; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onClicked: { root.cat = c.modelData.k; field.forceActiveFocus(); } }
                        }
                    }
                }
                // the results
                Item {
                    id: res
                    width: col.width - (root.cats ? 168 + 14 : 0)
                    height: 404
                    clip: true

                    // apps: a grid
                    GridView {
                        id: gv
                        visible: root.mode === "" && root.grid || root.mode === "@" || root.mode === ":"
                        anchors.fill: parent
                        model: visible ? root.items : []
                        cellWidth: width / root.cols
                        cellHeight: root.mode === ":" ? 68 : root.mode === "@" ? 116 : 130
                        currentIndex: root.sel
                        highlightFollowsCurrentItem: false
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: Item {
                            id: d
                            required property var modelData
                            required property int index
                            readonly property bool on: index === root.sel
                            readonly property bool hov: dm.containsMouse
                            width: gv.cellWidth; height: gv.cellHeight
                            Rectangle {
                                anchors.fill: parent; anchors.margins: 3
                                radius: root.mode === ":" ? (d.on || d.hov ? 32 : 20) : d.on || d.hov ? 36 : 28
                                color: d.on && root.mode === "" ? Theme.secondaryContainer : d.on || d.hov ? Theme.surfaceHigh : "transparent"
                                scale: dm.pressed ? .93 : root.mode === ":" && (d.on || d.hov) ? 1.1 : 1
                                Behavior on radius { SpringAnim { ms: 450 } }
                                Behavior on scale { SpringAnim { ms: 350 } }
                                Behavior on color { ColorAnim { ms: 200 } }
                            }
                            // an app
                            Column {
                                visible: root.mode === ""
                                anchors.centerIn: parent; spacing: 10
                                AppIcon {
                                    app: root.mode === "" ? d.modelData : null; size: 60
                                    r: d.on || d.hov ? 30 : 20
                                    scale: d.on || d.hov ? 1.06 : 1
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    Behavior on scale { SpringAnim { ms: 500 } }
                                }
                                Label {
                                    text: root.mode === "" ? d.modelData.name : ""
                                    size: 13; w: 600
                                    width: Math.min(110, implicitWidth); anchors.horizontalCenter: parent.horizontalCenter
                                    color: d.on ? Theme.fgSecondaryContainer : Theme.fgSurface
                                }
                            }
                            // an emoji
                            Text {
                                visible: root.mode === ":"
                                anchors.centerIn: parent
                                text: root.mode === ":" ? d.modelData : ""
                                font.pixelSize: 32
                            }
                            // a wallpaper
                            Column {
                                visible: root.mode === "@"
                                anchors.centerIn: parent; spacing: 8
                                RoundImage {
                                    width: gv.cellWidth - 22; height: 70; radius: 18
                                    bg: d.on || d.hov ? Theme.surfaceHigh : Theme.surface
                                    source: root.mode === "@" ? "file://" + d.modelData : ""
                                    sourceSize: Qt.size(192, 108)
                                }
                                Label { text: root.mode === "@" ? Walls.nameOf(d.modelData) : ""; size: 13; w: 600; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                            MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; onClicked: root.run(d.index) }
                        }
                    }

                    // apps as a list; the actions
                    Column {
                        visible: root.mode === "" && !root.grid || root.mode === ">"
                        width: parent.width
                        spacing: 2
                        Repeater {
                            model: parent.visible ? root.items : []
                            Rectangle {
                                id: ar
                                required property var modelData
                                required property int index
                                readonly property bool on: index === root.sel
                                readonly property bool first: index === 0
                                readonly property bool last: index === root.items.length - 1
                                readonly property real rr: on ? 30 : arm.containsMouse ? 20 : 0
                                width: parent.width; height: 60
                                topLeftRadius: rr || (first ? Theme.rm : 8); topRightRadius: rr || (first ? Theme.rm : 8)
                                bottomLeftRadius: rr || (last ? Theme.rm : 8); bottomRightRadius: rr || (last ? Theme.rm : 8)
                                color: on ? Theme.primaryContainer : arm.containsMouse ? Theme.surfaceHigh : Theme.surfaceMid
                                Behavior on color { ColorAnim { ms: 200 } }
                                Row {
                                    x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 14
                                    AppIcon { visible: root.mode === ""; app: root.mode === "" ? ar.modelData : null; size: 40; r: 14 }
                                    Rectangle {
                                        visible: root.mode === ">"
                                        width: 40; height: 40; radius: ar.on ? 20 : 14
                                        color: ar.modelData.danger ? Theme.errorContainer : ar.on ? Theme.primary : Theme.surfaceHighest
                                        MIcon { anchors.centerIn: parent; text: root.mode === ">" ? ar.modelData.i : ""; size: 22
                                                color: ar.modelData.danger ? Theme.error : ar.on ? Theme.fgPrimary : Theme.fgSurface }
                                    }
                                    Label { text: root.mode === ">" ? ar.modelData.n : ar.modelData.name; size: 15; w: 650; anchors.verticalCenter: parent.verticalCenter
                                            color: ar.on ? Theme.fgPrimaryContainer : Theme.fgSurface }
                                }
                                Label {
                                    anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                                    text: root.mode === ">" ? ar.modelData.s : Apps.catName(ar.modelData)
                                    size: 13; w: 500; color: ar.on ? Theme.fgPrimaryContainer : Theme.fgSurfaceVar; opacity: ar.on ? .8 : 1
                                }
                                MouseArea { id: arm; anchors.fill: parent; hoverEnabled: true; onClicked: root.run(ar.index) }
                            }
                        }
                    }

                    // the calculator
                    Rectangle {
                        visible: root.mode === "="
                        width: parent.width; height: cc.implicitHeight + 44
                        radius: 28
                        color: Theme.primaryContainer
                        Column {
                            id: cc
                            x: 26; y: 22; width: parent.width - 52
                            Label { text: root.q || "="; size: 14; w: 600; color: Theme.fgPrimaryContainer; opacity: .75 }
                            Label { text: root.calc; size: 56; w: 300; font.letterSpacing: -1.7; color: Theme.fgPrimaryContainer; width: parent.width; wrapMode: Text.WrapAnywhere }
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.run(0) }
                    }

                    Label {
                        visible: root.items.length === 0 && root.mode !== "="
                        anchors.horizontalCenter: parent.horizontalCenter; y: 40
                        text: root.mode === ">" ? "Нет такого действия" : "Ничего не найдено"
                        size: 14; w: 600; dim: true
                    }
                }
            }
        }
    }
}

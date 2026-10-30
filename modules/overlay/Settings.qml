import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.components
import qs.services

// The settings, the prototype's (settings.js, shell.css #settings): a side
// list of pages on the surface, a search, the page in groups of rows --
// icon tile, title, control. Every change applies at once and is kept.
Item {
    id: root
    property bool shown: false
    width: 1120
    height: 760

    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    scale: shown ? 1 : .94
    transform: Translate { y: root.shown ? 0 : 20; Behavior on y { SpringAnim { ms: 550 } } }
    Behavior on opacity { SmoothAnim { ms: 250 } }
    Behavior on scale { SpringAnim { ms: 550 } }
    onShownChanged: if (shown) q.text = ""

    readonly property var pages: [
        { k: "styles", n: "Стили", i: "auto_awesome_mosaic" }, { k: "look", n: "Оформление", i: "palette" },
        { k: "bar", n: "Панель", i: "toolbar" }, { k: "dock", n: "Док", i: "dock_to_bottom" },
        { k: "launcher", n: "Лаунчер", i: "apps" }, { k: "desk", n: "Рабочий стол", i: "widgets" },
        { k: "notif", n: "Уведомления", i: "notifications" }, { k: "about", n: "О системе", i: "info" }
    ]
    readonly property var cfg: Config.data
    readonly property string query: q.text.trim().toLowerCase()

    // the window: surface-low, a hairline, the shadow
    RectangularShadow { anchors.fill: bg; radius: bg.radius; blur: 90; offset.y: 30; spread: -24; color: Theme.shadow }
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.r
        color: Theme.surfaceLow
        border.width: 1; border.color: Theme.alpha(Theme.fgSurface, .06)
        Behavior on color { ColorAnim { ms: 900 } }
        MouseArea { anchors.fill: parent; onWheel: w => w.accepted = true }
    }
    Item {
        anchors.fill: parent

        // ---- the side: the logo, the search, the pages ----
        Rectangle {
            id: side
            width: 280; height: parent.height
            topLeftRadius: Theme.r; bottomLeftRadius: Theme.r
            color: Theme.surface
            Behavior on color { ColorAnim { ms: 900 } }
            Column {
                x: 12; y: 18
                width: parent.width - 24
                spacing: 2
                Row {
                    leftPadding: 8; topPadding: 4; bottomPadding: 14
                    spacing: 10
                    MShape {
                        width: 36; height: 36
                        shape: Theme.shCookie9; color: Theme.primary
                        XvletMark { anchors.centerIn: parent; width: 24; height: 24; ink: Theme.fgPrimary; ink2: Theme.mix(Theme.fgPrimary, Theme.primary, .35); ink3: Theme.mix(Theme.fgPrimary, Theme.primary, .6) }
                    }
                    Label { text: "Настройки"; size: 20; w: 750; font.letterSpacing: -.2; anchors.verticalCenter: parent.verticalCenter }
                }
                Rectangle {
                    width: parent.width; height: 44; radius: 22
                    color: Theme.surfaceHigh
                    Row {
                        x: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                        MIcon { text: "search"; size: 20; color: Theme.fgSurfaceVar; anchors.verticalCenter: parent.verticalCenter }
                        Item {
                            width: side.width - 24 - 28 - 30; height: 20
                            anchors.verticalCenter: parent.verticalCenter
                            TextInput {
                                id: q
                                anchors.fill: parent
                                font.family: Theme.font; font.pixelSize: 14
                                color: Theme.fgSurface; selectionColor: Theme.primary
                                clip: true
                            }
                            Label { visible: q.text === ""; text: "Поиск настроек"; size: 14; w: 400; dim: true }
                        }
                    }
                }
                Item { width: 1; height: 8 }
                Repeater {
                    model: root.pages
                    Rectangle {
                        id: pg
                        required property var modelData
                        readonly property bool on: root.query === "" && Ui.settingsPage === modelData.k
                        width: parent.width; height: 48
                        radius: on ? 24 : pm.containsMouse ? 16 : 24
                        color: on ? Theme.secondaryContainer : pm.containsMouse ? Theme.surfaceHigh : "transparent"
                        Behavior on radius { SpringAnim { ms: 400 } }
                        Behavior on color { ColorAnim { ms: 200 } }
                        Row {
                            x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 14
                            MIcon { text: pg.modelData.i; fill: pg.on; size: 22; color: lb.color }
                            Label { id: lb; text: pg.modelData.n; size: 14.5; w: 600; color: pg.on ? Theme.fgSecondaryContainer : Theme.fgSurfaceVar; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; onClicked: { q.text = ""; Ui.settingsPage = pg.modelData.k; } }
                    }
                }
            }
        }

        // ---- the page ----
        Flickable {
            id: fl
            x: side.width; width: parent.width - side.width; height: parent.height
            contentHeight: body.implicitHeight + 56
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            Column {
                id: body
                x: 30; y: 26
                width: fl.width - 60
                spacing: 12
                Label { text: root.query ? "Поиск: " + root.query : (root.pages.find(p => p.k === Ui.settingsPage) || {}).n || ""; size: 34; w: 700; font.letterSpacing: -.7; topPadding: 4; bottomPadding: 6 }
                Loader { width: parent.width; active: !root.query; sourceComponent: pageOf(Ui.settingsPage); onLoaded: fl.contentY = 0 }
                Repeater {
                    model: root.query ? root.pages : []
                    Loader { required property var modelData; width: body.width; sourceComponent: root.pageOf(modelData.k) }
                }
                Label {
                    visible: root.query !== "" && !body.anyRow
                    width: parent.width; topPadding: 40
                    horizontalAlignment: Text.AlignHCenter
                    text: "Ничего не нашлось"; dim: true; size: 14
                }
                // (found anything: a row is shown somewhere)
                property bool anyRow: true
            }
        }
    }
    IconButton { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; icon: "close"; onClicked: Ui.settings = false }

    function pageOf(k) { return ({ styles: styles, look: look, bar: bar, dock: dock, launcher: launcher, desk: desk, notif: notif, about: about })[k] || null; }

    // ---- the pieces (shell.css: .sgroup, .srow, .seg, .switch, .srange, .mini, .posmap) ----
    component Group: Rectangle {
        id: grp
        default property alias rows: gcol.data
        property string title: ""
        width: parent ? parent.width : 0
        implicitHeight: gcol.implicitHeight + 16
        radius: Theme.rm
        color: Theme.surfaceMid
        // searching: a group with nothing matching goes
        visible: { if (root.query === "") return true; for (let i = 0; i < gcol.children.length; i++) { const c = gcol.children[i]; if (c.kw !== undefined && c.visible) return true; } return false; }
        Behavior on color { ColorAnim { ms: 900 } }
        Column {
            id: gcol
            x: 8; y: 8
            width: parent.width - 16
            spacing: 2
            H4 { text: grp.title; visible: grp.title !== "" }
        }
    }
    component H4: Label {
        size: 12; w: 750
        font.capitalization: Font.AllUppercase; font.letterSpacing: 12 * .08
        color: Theme.primary
        leftPadding: 14; topPadding: 10; bottomPadding: 6
    }
    component SRow: Item {
        id: r
        default property alias control: ctl.data
        property string icon
        property string title
        property string kw: ""
        width: parent ? parent.width : 0
        height: Math.max(64, ctl.childrenRect.height + 20)
        visible: root.query === "" || (title + " " + kw).toLowerCase().includes(root.query)
        Rectangle { anchors.fill: parent; radius: 18; color: Theme.alpha(Theme.fgSurface, hov.hovered ? .04 : 0); Behavior on color { ColorAnim { ms: 200 } } }
        HoverHandler { id: hov }
        Rectangle {
            x: 14; anchors.verticalCenter: parent.verticalCenter
            width: 40; height: 40; radius: 14
            color: Theme.surfaceHigh
            MIcon { anchors.centerIn: parent; text: r.icon; size: 22; color: Theme.fgSurfaceVar }
        }
        Label {
            x: 70; anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 70 - ctl.width - 30
            text: r.title; size: 15; w: 650
        }
        Item {
            id: ctl
            anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width; height: childrenRect.height
        }
    }
    component Mini: Rectangle {
        id: mb
        property string icon
        property string text
        property bool pri: false
        signal clicked
        width: mbr.implicitWidth + 28; height: 36
        radius: mbm.containsMouse ? 18 : 12
        color: pri ? Theme.primary : Theme.surfaceHighest
        scale: mbm.pressed ? .92 : 1
        Behavior on radius { SpringAnim { ms: 350 } }
        Behavior on scale { SpringAnim { ms: 350 } }
        Row {
            id: mbr; anchors.centerIn: parent; spacing: 6
            MIcon { text: mb.icon; size: 18; visible: mb.icon !== ""; color: mbl.color; anchors.verticalCenter: parent.verticalCenter }
            Label { id: mbl; text: mb.text; size: 13; w: 650; color: mb.pri ? Theme.fgPrimary : Theme.fgSurfaceVar; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: mbm; anchors.fill: parent; hoverEnabled: true; onClicked: mb.clicked() }
    }
    component Range: MSlider {
        property string path
        property real lo
        property real hi
        property real step
        property string unit: ""
        readonly property real cur: Config.get(path)
        width: 280; thin: true
        value: (cur - lo) / (hi - lo)
        valueText: (Math.round(cur * 100) / 100).toLocaleString(Qt.locale("ru_RU"), "f", step < 1 ? 2 : 0).replace(/[,.]?0+$/, "") + unit
        valueWidth: 50
        onMoved: v => Config.set(path, Math.round((lo + v * (hi - lo)) / step) * step)
    }
    component Sw: Toggle {
        property string path
        checked: !!Config.get(path)
        onToggled: v => Config.set(path, v)
    }
    component Pick: Seg {
        property string path
        value: Config.get(path)
        onPicked: k => Config.set(path, k)
    }
    // where on the screen: a little screen, its edges or corners to click
    component PosMap: Rectangle {
        id: pmap
        property string path
        property var opts: []
        readonly property var places: ({
            top: [8, 6, 116, 8], bottom: [8, 66, 116, 8], left: [6, 8, 8, 64], right: [118, 8, 8, 64],
            tl: [8, 8, 34, 14], tc: [49, 8, 34, 14], tr: [90, 8, 34, 14], bl: [8, 58, 34, 14], bc: [49, 58, 34, 14], br: [90, 58, 34, 14]
        })
        width: 132; height: 80; radius: 12
        color: Theme.surfaceHigh
        Repeater {
            model: pmap.opts
            Rectangle {
                id: pb
                required property string modelData
                readonly property var g: pmap.places[modelData]
                readonly property bool on: Config.get(pmap.path) === modelData
                x: g[0]; y: g[1]; width: g[2]; height: g[3]; radius: 6
                color: on ? Theme.primary : Theme.outline
                opacity: on ? 1 : pbm.containsMouse ? .8 : .45
                Behavior on opacity { NumberAnimation { duration: 200 } }
                MouseArea { id: pbm; anchors.fill: parent; anchors.margins: -3; hoverEnabled: true; onClicked: Config.set(pmap.path, pb.modelData) }
            }
        }
    }

    // ---- Стили ----
    readonly property var presets: [
        { n: "xvlet", w: 0, c: { bar: { pos: "top", style: "islands", height: 52, ws: "pill", clock: "date", mods: mods({ logo: "start", ws: "start", media: "center", tray: "end", weather: "end", status: "end", bell: "end", clock: "end", power: "end" }) }, dock: { on: true, style: "attached", pos: "bottom", autohide: "off", labels: false }, launcher: { pos: "bottom" } } },
        { n: "Exo", w: 4, c: { bar: { pos: "top", style: "flush", height: 40, ws: "dots", clock: "date", mods: mods({ ws: "start", media: "start", clock: "center", tray: "end", status: "end", bell: "end" }) }, dock: { on: true, style: "strip", pos: "left", autohide: "off", labels: false, size: 40 }, launcher: { pos: "bar" }, theme: { shellCorners: true, screenCorners: true } } },
        { n: "Сегменты", w: 9, c: { bar: { pos: "top", style: "seg", height: 48, ws: "pill", clock: "date", mods: mods({ logo: "start", ws: "start", media: "center", tray: "end", status: "end", clock: "end", power: "end" }) }, dock: { on: true, style: "attached", pos: "bottom", autohide: "off", labels: false }, launcher: { pos: "bottom" } } },
        { n: "Классика", w: 7, c: { bar: { pos: "bottom", style: "solid", height: 52, ws: "numbers", clock: "date", mods: mods({ logo: "start", tasks: "start", media: "center", tray: "end", weather: "end", status: "end", bell: "end", clock: "end", power: "end" }) }, dock: { on: false }, launcher: { pos: "bar" } } },
        { n: "Вертикальная", w: 2, c: { bar: { pos: "left", style: "islands", height: 52, ws: "pill", clock: "date", mods: mods({ logo: "start", ws: "start", media: "center", status: "end", bell: "end", clock: "end", power: "end" }) }, dock: { on: true, style: "attached", pos: "bottom", autohide: "off", labels: false }, launcher: { pos: "bar" } } },
        { n: "Рабочая станция", w: 6, c: { bar: { pos: "top", style: "solid", height: 46, ws: "numbers", clock: "date", mods: mods({ logo: "start", ws: "start", tasks: "start", sysmon: "center", tray: "end", status: "end", bell: "end", clock: "end", power: "end" }) }, dock: { on: true, style: "attached", pos: "right", autohide: "off", labels: false, size: 44 }, launcher: { pos: "bar" } } },
        { n: "Минимум", w: 1, c: { bar: { pos: "top", style: "islands", height: 44, ws: "dots", clock: "time", mods: mods({ ws: "start", clock: "center", status: "end" }) }, dock: { on: true, style: "floating", pos: "bottom", autohide: "always", labels: false }, launcher: { pos: "center" } } }
    ]
    function mods(on) { const all = ["logo", "ws", "tasks", "media", "tray", "sysmon", "weather", "status", "bell", "clock", "power"], o = {}; for (const k of all) o[k] = on[k] || "off"; return o; }
    property int presetOn: -1

    // a strip along an edge of a preview: from s to e (fractions or px), th thick, g off the edge
    component Edge: Rectangle {
        property Item box: parent
        property string pos
        property var s
        property var e
        property real th
        property real g
        readonly property bool al: pos === "top" || pos === "bottom"
        function px(v, len) { return typeof v === "string" ? len * parseFloat(v) / 100 : v; }
        x: al ? px(s, box.width) : (pos === "left" ? g : box.width - g - th)
        y: al ? (pos === "top" ? g : box.height - g - th) : px(s, box.height)
        width: al ? box.width - px(s, box.width) - px(e, box.width) : th
        height: al ? th : box.height - px(s, box.height) - px(e, box.height)
    }
    // a preset's little picture: its wallpaper, the bar and the dock as on it
    component Preview: Item {
        id: pv
        property var c
        readonly property var b: c.bar
        readonly property var d: c.dock
        readonly property real t: Math.round(b.height / 4)
        readonly property bool along: b.pos === "top" || b.pos === "bottom"
        Edge { visible: pv.b.style === "flush" || pv.b.style === "solid"; pos: pv.b.pos; s: 0; e: 0; th: pv.t; g: 0; color: Theme.surface }
        Edge { visible: pv.b.style === "seg"; pos: pv.b.pos; s: 0; e: "62%"; th: pv.t; g: 0; color: Theme.surface; bottomRightRadius: 8 }
        Edge { visible: pv.b.style === "seg"; pos: pv.b.pos; s: "70%"; e: 0; th: pv.t; g: 0; color: Theme.surface; bottomLeftRadius: 8 }
        Edge { visible: pv.b.style === "islands"; pos: pv.b.pos; s: 6; e: "62%"; th: pv.t; g: 5; color: Theme.glass; radius: 6 }
        Edge { visible: pv.b.style === "islands"; pos: pv.b.pos; s: "55%"; e: 6; th: pv.t; g: 5; color: Theme.glass; radius: 6 }
        Edge {
            readonly property real dth: Math.round((pv.d.size || 52) / 3.4)
            readonly property bool fl: pv.d.style === "floating" || pv.d.pos === pv.b.pos
            readonly property bool strip: pv.d.style === "strip" && pv.d.pos !== pv.b.pos
            visible: pv.d.on !== false
            pos: pv.d.pos || "bottom"; s: strip ? 0 : "32%"; e: strip ? 0 : "32%"; th: dth
            g: strip ? 0 : fl ? (pv.d.pos === pv.b.pos ? pv.t + 8 : 5) : 0
            color: fl ? Theme.glass : Theme.surface
            radius: strip ? 0 : 7
        }
    }

    Component {
        id: styles
        Column {
            spacing: 12
            Rectangle {
                visible: root.query === ""
                width: parent.width; height: pcol.implicitHeight + 28
                radius: Theme.rm; color: Theme.surfaceMid
                Column {
                    id: pcol
                    x: 14; y: 14; width: parent.width - 28
                    H4 { text: "Готовые раскладки"; leftPadding: 2; topPadding: 0; bottomPadding: 10 }
                    Grid {
                        width: parent.width; columns: 2; spacing: 10
                        Repeater {
                            model: root.presets
                            Item {
                                id: ps
                                required property var modelData
                                required property int index
                                width: (pcol.width - 10) / 2; height: 150
                                scale: pm2.pressed ? .97 : 1
                                Behavior on scale { SpringAnim { ms: 350 } }
                                Rectangle {
                                    // the ring of the chosen one
                                    anchors.fill: parent; anchors.margins: -5
                                    radius: pclip.radius + 5
                                    color: "transparent"
                                    border.width: 2; border.color: Theme.primary
                                    visible: root.presetOn === ps.index
                                }
                                RoundImage {
                                    id: pclip
                                    anchors.fill: parent
                                    radius: pm2.containsMouse ? 36 : Theme.rm
                                    Behavior on radius { SpringAnim { ms: 450 } }
                                    source: Walls.list.length ? "file://" + Walls.list[Math.min(ps.modelData.w, Walls.list.length - 1)] : ""
                                    sourceSize: Qt.size(384, 216)
                                    Preview { anchors.fill: parent; c: ps.modelData.c }
                                    Label {
                                        x: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                                        text: ps.modelData.n; size: 16; w: 750; color: "white"
                                        style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, .35)
                                    }
                                }
                                MouseArea {
                                    id: pm2; anchors.fill: parent; hoverEnabled: true
                                    onClicked: { Config.data = Config.merge(Config.data, ps.modelData.c); Config.set("theme.radius", Config.data.theme.radius); root.presetOn = ps.index; }
                                }
                            }
                        }
                    }
                }
            }
            Group {
                SRow { icon: "restart_alt"; title: "Сбросить всё"; kw: "Вернуть настройки шелла по умолчанию"
                    Mini { icon: "restart_alt"; text: "Сбросить"; onClicked: { Config.data = Config.clone(Config.defaults); Config.set("theme.mode", "dark"); root.presetOn = -1; } } }
            }
        }
    }

    // ---- Оформление ----
    readonly property var accents: [285, 330, 15, 55, 95, 145, 190, 235]
    // a theme's colours, as swatches (the prototype's themeSwatches)
    function swatches(t) {
        const v = Theme.paletteOf(t), dark = (t.mode || root.cfg.theme.mode) === "dark";
        return {
            bg: dark ? Theme.oklch(22.5, v.cn, v.hn) : Theme.oklch(93.5, v.cn * .7, v.hn),
            fg: dark ? Theme.oklch(93, v.cn * .35, v.hn) : Theme.oklch(22, v.cn * .5, v.hn),
            strip: [dark ? Theme.oklch(80, v.cp, v.hp) : Theme.oklch(45, v.cp, v.hp), dark ? Theme.oklch(34, v.cs, v.hs) : Theme.oklch(90, v.cs * .75, v.hs),
                    dark ? Theme.oklch(80, v.ct, v.ht) : Theme.oklch(48, v.ct, v.ht), dark ? Theme.oklch(36, v.cp * .9, v.hp) : Theme.oklch(89, v.cp * .6, v.hp),
                    dark ? Theme.oklch(30, v.cn * 1.1, v.hn) : Theme.oklch(89, v.cn * .8, v.hn)]
        };
    }
    function setTheme(o) { let t = Config.clone(root.cfg.theme); for (const k in o) t[k] = o[k]; Config.set("theme", t); }
    readonly property var savedNow: cfg.theme.src === "saved" && cfg.theme.saved && cfg.theme.saved[cfg.theme.active] ? cfg.theme.saved[cfg.theme.active] : null

    Component {
        id: look
        Column {
            spacing: 12
            // the wallpaper: big, its name, choose or the next one
            RoundImage {
                visible: root.query === ""
                width: parent.width; height: 230
                radius: Theme.rm; bg: Theme.surfaceLow
                source: root.cfg.wall.path ? "file://" + root.cfg.wall.path : ""
                sourceSize: Qt.size(960, 540)
                Row {
                    x: 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 16; spacing: 8
                    Mini { pri: true; icon: "wallpaper"; text: "Выбрать обои"; onClicked: { Ui.settings = false; Ui.wallpick = true; } }
                    Mini { icon: "skip_next"; text: "Следующие"; onClicked: { const l = Walls.list; if (l.length) Walls.set(l[(l.indexOf(root.cfg.wall.path) + 1) % l.length]); } }
                }
                Column {
                    anchors.right: parent.right; anchors.rightMargin: 18; anchors.bottom: parent.bottom; anchors.bottomMargin: 16
                    Label { anchors.right: parent.right; text: Walls.nameOf(root.cfg.wall.path); size: 15; w: 700; color: "white"; style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, .35) }
                    Label { anchors.right: parent.right; text: "обои " + (Walls.list.indexOf(root.cfg.wall.path) + 1) + " из " + Walls.list.length; size: 12; w: 500; color: Qt.rgba(1, 1, 1, .8); visible: Walls.list.indexOf(root.cfg.wall.path) >= 0 }
                }
            }
            Group {
                title: "Обои"
                SRow { icon: "animation"; title: "Переход"; kw: "Как новые обои сменяют старые"
                    Pick { path: "wall.trans"; model: [{ k: "circle", n: "Круг" }, { k: "wipe", n: "Шторка" }, { k: "fade", n: "Растворение" }, { k: "zoom", n: "Приближение" }, { k: "blinds", n: "Жалюзи" }] } }
            }
            Group {
                title: "Динамические цвета Material 3"
                SRow { icon: "contrast"; title: "Тема"
                    Seg { model: [{ k: "dark", n: "Тёмная", i: "dark_mode" }, { k: "light", n: "Светлая", i: "light_mode" }]
                          value: root.savedNow ? root.savedNow.mode : root.cfg.theme.mode
                          onPicked: k => { if (root.savedNow) { const s = Config.clone(root.cfg.theme.saved); s[root.cfg.theme.active].mode = k; root.setTheme({ saved: s, mode: k }); } else root.setTheme({ mode: k }); } } }
                SRow { icon: "palette"; title: "Источник цвета"
                    Seg { model: [{ k: "wall", n: "Обои", i: "wallpaper" }, { k: "custom", n: "Свой цвет", i: "colorize" }].concat(root.savedNow ? [{ k: "saved", n: root.savedNow.n, i: "bookmark" }] : [])
                          value: root.cfg.theme.src; onPicked: k => root.setTheme({ src: k }) } }
                SRow { icon: "wallpaper"; title: "Цвета обоев"; kw: "обои цвет"; visible: root.cfg.theme.src === "wall" && (root.query === "" || "цвета обоев обои цвет".includes(root.query))
                    Row { spacing: 8
                        Repeater { model: Theme.wallSeeds
                            Item { id: sd; required property var modelData; required property int index
                                readonly property bool on: index === (root.cfg.theme.seed < Theme.wallSeeds.length ? root.cfg.theme.seed : 0)
                                width: 46; height: 46
                                Rectangle { anchors.centerIn: parent; width: 56; height: 56; radius: 28; color: "transparent"; border.width: 2; border.color: Theme.fgSurface; visible: sd.on }
                                Rectangle { anchors.fill: parent; radius: sd.on || sdm.containsMouse ? 23 : 16; color: Theme.oklch(70, Math.min(sd.modelData.c, .16), sd.modelData.h)
                                    scale: sdm.containsMouse ? 1.06 : 1
                                    Behavior on radius { SpringAnim { ms: 350 } } Behavior on scale { SpringAnim { ms: 350 } } }
                                MouseArea { id: sdm; anchors.fill: parent; hoverEnabled: true; onClicked: root.setTheme({ seed: sd.index }) } } } } }
                SRow { icon: "colorize"; title: "Цвет"; visible: root.cfg.theme.src === "custom" && (root.query === "" || "цвет".includes(root.query))
                    Row { spacing: 12
                        Flow { width: 4 * 46; spacing: 6; layoutDirection: Qt.RightToLeft; anchors.verticalCenter: parent.verticalCenter
                            Repeater { model: root.accents
                                Item { id: ac; required property real modelData
                                    readonly property bool on: root.cfg.theme.custom === modelData
                                    width: 40; height: 40
                                    Rectangle { anchors.centerIn: parent; width: 50; height: 50; radius: 25; color: "transparent"; border.width: 2; border.color: Theme.fgSurface; visible: ac.on }
                                    Rectangle { anchors.fill: parent; radius: ac.on || acm.containsMouse ? 20 : 14; color: Theme.oklch(72, .14, ac.modelData)
                                        Behavior on radius { SpringAnim { ms: 350 } } }
                                    MouseArea { id: acm; anchors.fill: parent; hoverEnabled: true; onClicked: root.setTheme({ custom: ac.modelData }) } } } }
                        MSlider { width: 200; thin: true; anchors.verticalCenter: parent.verticalCenter
                            value: root.cfg.theme.custom / 359; valueText: Math.round(root.cfg.theme.custom) + "°"
                            onMoved: v => root.setTheme({ custom: Math.round(v * 359) }) } } }
                H4 { text: "Схема"; visible: root.query === "" }
                Grid {
                    visible: root.query === ""
                    x: 10; width: parent.width - 20; columns: 4; spacing: 8; bottomPadding: 12; topPadding: 4
                    Repeater { model: Object.keys(Theme.schemes)
                        Rectangle { id: sc; required property string modelData
                            readonly property bool on: (Theme.now.scheme || "tonal") === modelData
                            readonly property var sw: root.swatches({ h: Theme.now.h, c: Theme.now.c, scheme: modelData, mode: root.cfg.theme.mode })
                            width: (parent.width - 24) / 4; height: 92
                            radius: on || scm.containsMouse ? 30 : 20
                            color: on ? Theme.secondaryContainer : Theme.surfaceHigh
                            scale: scm.pressed ? .95 : 1
                            Behavior on radius { SpringAnim { ms: 400 } } Behavior on scale { SpringAnim { ms: 300 } }
                            Column { anchors.centerIn: parent; spacing: 10
                                Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: -6
                                    Repeater { model: sc.sw.strip.slice(0, 4)
                                        Rectangle { required property color modelData; width: 26; height: 26; radius: 13; color: sc.color
                                            Rectangle { anchors.centerIn: parent; width: 22; height: 22; radius: 11; color: parent.modelData } } } }
                                Label { anchors.horizontalCenter: parent.horizontalCenter; text: Theme.schemes[sc.modelData].n; size: 12.5; w: 650; color: sc.on ? Theme.fgSecondaryContainer : Theme.fgSurface } }
                            MouseArea { id: scm; anchors.fill: parent; hoverEnabled: true
                                onClicked: { if (root.savedNow) { const s = Config.clone(root.cfg.theme.saved); s[root.cfg.theme.active].scheme = sc.modelData; root.setTheme({ saved: s, scheme: sc.modelData }); } else root.setTheme({ scheme: sc.modelData }); } } } }
                }
            }
            Group {
                title: "Мои темы"
                visible: root.query === ""
                Grid {
                    x: 10; width: parent.width - 20; columns: 3; spacing: 10; topPadding: 4; bottomPadding: 12
                    Repeater { model: root.cfg.theme.saved || []
                        Item { id: st; required property var modelData; required property int index
                            readonly property var sw: root.swatches(modelData)
                            readonly property bool on: root.cfg.theme.src === "saved" && root.cfg.theme.active === index
                            width: (parent.width - 20) / 3; height: 112
                            scale: stm.pressed ? .96 : 1
                            Behavior on scale { SpringAnim { ms: 300 } }
                            Rectangle { anchors.fill: parent; anchors.margins: -5; radius: stb.radius + 5; color: "transparent"; border.width: 2; border.color: Theme.primary; visible: st.on }
                            Rectangle { id: stb; anchors.fill: parent; radius: stm.containsMouse ? 32 : 22; color: st.sw.bg
                                Behavior on radius { SpringAnim { ms: 400 } }
                                Row { x: 14; y: 12; spacing: 6
                                    MIcon { text: st.modelData.mode === "light" ? "light_mode" : "dark_mode"; size: 16; color: st.sw.fg; anchors.verticalCenter: parent.verticalCenter }
                                    Label { text: st.modelData.n; size: 14; w: 750; color: st.sw.fg } }
                                Row { x: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; width: parent.width - 28; spacing: 4
                                    Repeater { model: st.sw.strip
                                        Rectangle { required property color modelData; width: (parent.width - 16) / 5; height: 26; radius: 9; color: modelData } } } }
                            MouseArea { id: stm; anchors.fill: parent; hoverEnabled: true
                                onClicked: root.setTheme({ src: "saved", active: st.index, mode: st.modelData.mode, scheme: st.modelData.scheme }) }
                            Rectangle { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8; width: 28; height: 28; radius: 14
                                color: Qt.rgba(0, 0, 0, .4); opacity: stm.containsMouse || xm.containsMouse ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                MIcon { anchors.centerIn: parent; text: "close"; size: 18; color: "white" }
                                MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true
                                    onClicked: { const T = root.cfg.theme, l = T.saved.filter((_, i) => i !== st.index);
                                        root.setTheme({ saved: l, active: T.active === st.index ? -1 : T.active > st.index ? T.active - 1 : T.active, src: T.active === st.index && T.src === "saved" ? "wall" : T.src }); } } } } }
                    // a new one: its name, save the colours in force
                    Item {
                        id: addc
                        width: (parent.width - 20) / 3; height: 112
                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: Theme.outline; strokeWidth: 2; strokeStyle: ShapePath.DashLine; dashPattern: [3, 3]
                                fillColor: Theme.surfaceHigh
                                PathRectangle { x: 1; y: 1; width: addc.width - 2; height: 110; radius: 21 }
                            }
                        }
                        Column { anchors.centerIn: parent; width: parent.width - 28; spacing: 8
                            Rectangle { width: parent.width; height: 34; radius: 12; color: Theme.surfaceHighest
                                TextInput { id: tname; anchors.fill: parent; leftPadding: 12; rightPadding: 12; verticalAlignment: TextInput.AlignVCenter; clip: true
                                    font.family: Theme.font; font.pixelSize: 13; font.weight: 600; font.variableAxes: ({ wght: 600 }); color: Theme.fgSurface }
                                Label { x: 12; anchors.verticalCenter: parent.verticalCenter; visible: tname.text === ""; text: "Тема " + ((root.cfg.theme.saved || []).length + 1); size: 13; w: 600; dim: true } }
                            Mini { anchors.horizontalCenter: parent.horizontalCenter; pri: true; icon: "bookmark_add"; text: "Сохранить текущую"
                                onClicked: { const T = root.cfg.theme, t = Theme.now, n = tname.text.trim() || "Тема " + ((T.saved || []).length + 1);
                                    const l = (T.saved || []).concat([{ n: n, h: t.h, c: Math.round(t.c * 1000) / 1000, scheme: t.scheme || T.scheme, mode: T.mode }]);
                                    tname.text = ""; root.setTheme({ saved: l, active: l.length - 1, src: "saved" }); } } }
                    }
                }
            }
            Group {
                title: "Форма и движение"
                SRow { icon: "rounded_corner"; title: "Скругление"; kw: "Радиус углов панелей и карточек"
                    Range { path: "theme.radius"; lo: .4; hi: 1.6; step: .05; unit: "×" } }
                SRow { icon: "motion_photos_on"; title: "Анимации"; kw: "Пружинные — с отскоком, как в M3 Expressive"
                    Pick { path: "theme.motion"; model: [{ k: "spring", n: "Пружинные" }, { k: "smooth", n: "Плавные" }, { k: "off", n: "Выключены" }] } }
                SRow { icon: "font_download"; title: "Шрифт"; kw: "Шрифт всего шелла"
                    Pick { path: "theme.font"; model: [{ k: "Roboto Flex", n: "Roboto Flex" }, { k: "Adwaita Sans", n: "Adwaita Sans" }, { k: "Adwaita Mono", n: "Adwaita Mono" }] } }
            }
            Group {
                title: "Углы"
                SRow { icon: "rounded_corner"; title: "Скруглённые углы оболочки"; kw: "Изгиб там, где прилегающая панель или док-полоса встречают экран (как в Exo)"
                    Sw { path: "theme.shellCorners" } }
                SRow { icon: "crop_free"; title: "Скруглённые углы экрана"; kw: "Чёрные скругления по углам самого экрана"
                    Sw { path: "theme.screenCorners" } }
            }
        }
    }

    // ---- Панель ----
    readonly property var modNames: [
        { k: "logo", n: "Меню приложений", d: "Кнопка лаунчера", i: "auto_awesome" },
        { k: "ws", n: "Рабочие столы", d: "Переключение столов, колёсико листает", i: "workspaces" },
        { k: "tasks", n: "Задачи", d: "Запущенные приложения прямо в панели", i: "view_week" },
        { k: "media", n: "Медиа", d: "Что играет; клик — плеер", i: "music_note" },
        { k: "tray", n: "Трей", d: "Значки фоновых приложений", i: "apps" },
        { k: "sysmon", n: "Ресурсы", d: "Загрузка процессора и памяти", i: "memory" },
        { k: "weather", n: "Погода", d: "Температура; клик — обзор", i: "partly_cloudy_day" },
        { k: "status", n: "Статус", d: "Сеть, звук, батарея — быстрые настройки", i: "wifi" },
        { k: "bell", n: "Уведомления", d: "Центр уведомлений", i: "notifications" },
        { k: "clock", n: "Часы", d: "Время и дата; клик — панель", i: "schedule" },
        { k: "power", n: "Питание", d: "Блокировка, выход, выключение", i: "power_settings_new" }
    ]
    Component {
        id: bar
        Column {
            spacing: 12
            readonly property bool vert: root.cfg.bar.pos === "left" || root.cfg.bar.pos === "right"
            Group {
                title: "Расположение"
                SRow { icon: "vertical_align_top"; title: "Положение"; kw: "К любому краю экрана — сверху, снизу, слева, справа"
                    PosMap { path: "bar.pos"; opts: ["top", "bottom", "left", "right"] } }
                SRow { icon: "view_agenda"; title: "Стиль"; kw: "Острова — плавают; сплошная — полоса; прилегающая — часть рамки экрана (Exo); сегменты — части свисают с края"
                    Pick { path: "bar.style"; model: [{ k: "islands", n: "Острова" }, { k: "solid", n: "Сплошная" }, { k: "flush", n: "Прилегающая" }, { k: "seg", n: "Сегменты" }] } }
                SRow { icon: "height"; title: "Толщина"
                    Range { path: "bar.height"; lo: 36; hi: 64; step: 2; unit: " px" } }
            }
            Group {
                title: "Модули"
                Repeater {
                    model: root.modNames
                    SRow { id: mr; required property var modelData; icon: modelData.i; title: modelData.n; kw: modelData.d + " модуль"
                        readonly property string zone: root.cfg.bar.mods[modelData.k] || "off"
                        Row { spacing: 14
                            Seg { anchors.verticalCenter: parent.verticalCenter
                                  model: root.cfg.bar.pos === "left" || root.cfg.bar.pos === "right" ? [{ k: "start", n: "Верх" }, { k: "center", n: "Центр" }, { k: "end", n: "Низ" }] : [{ k: "start", n: "Начало" }, { k: "center", n: "Центр" }, { k: "end", n: "Конец" }]
                                  value: mr.zone; onPicked: k => Config.set("bar.mods." + mr.modelData.k, k) }
                            Toggle { anchors.verticalCenter: parent.verticalCenter; checked: mr.zone !== "off"
                                     onToggled: v => Config.set("bar.mods." + mr.modelData.k, v ? "end" : "off") } } }
                }
            }
            Group {
                title: "Вид модулей"
                SRow { icon: "workspaces"; title: "Рабочие столы"; kw: "Как показывать рабочие столы"
                    Pick { path: "bar.ws"; model: [{ k: "pill", n: "Пилюля" }, { k: "dots", n: "Точки" }, { k: "numbers", n: "Цифры" }] } }
                SRow { icon: "schedule"; title: "Часы"; kw: "С датой или только время (сбоку — всегда только время)"
                    Pick { path: "bar.clock"; model: [{ k: "date", n: "С датой" }, { k: "time", n: "Только время" }] } }
            }
        }
    }

    // ---- Док ----
    Component {
        id: dock
        Column {
            spacing: 12
            Group {
                SRow { icon: "dock_to_bottom"; title: "Показывать док"; kw: "Закреплённые и запущенные приложения"
                    Sw { path: "dock.on" } }
            }
            Group {
                title: "Вид"
                SRow { icon: "crop_square"; title: "Стиль"; kw: "Прикреплённый — выступ у края; плавающий — плашка; полоса — во всю длину края, как вторая панель Exo"
                    Pick { path: "dock.style"; model: [{ k: "attached", n: "Прикреплённый" }, { k: "floating", n: "Плавающий" }, { k: "strip", n: "Полоса" }] } }
                SRow { icon: "dock_to_left"; title: "Положение"; kw: "К любому краю. На одном краю с панелью док встаёт рядом с ней"
                    PosMap { path: "dock.pos"; opts: ["bottom", "top", "left", "right"] } }
                SRow { icon: "photo_size_select_small"; title: "Размер значков"
                    Range { path: "dock.size"; lo: 24; hi: 72; step: 2; unit: " px" } }
                SRow { icon: "zoom_in"; title: "Увеличение при наведении"
                    Range { path: "dock.zoom"; lo: 1; hi: 1.4; step: .02; unit: "×" } }
                SRow { icon: "label"; title: "Подписи"; kw: "Названия рядом со значками"
                    Sw { path: "dock.labels" } }
                SRow { icon: "more_horiz"; title: "Индикаторы"; kw: "Точка под запущенными, полоска под активным"
                    Sw { path: "dock.inds" } }
                SRow { icon: "visibility_off"; title: "Автоскрытие"; kw: "Умное — прячется, когда под ним окно"
                    Pick { path: "dock.autohide"; model: [{ k: "off", n: "Нет" }, { k: "smart", n: "Умное" }, { k: "always", n: "Всегда" }] } }
            }
            Group {
                title: "Приложения в доке"
                visible: root.query === ""
                Column {
                    x: 6; width: parent.width - 12; spacing: 2; topPadding: 4; bottomPadding: 8
                    Repeater { model: root.cfg.dock.apps
                        Rectangle { id: da; required property string modelData; required property int index
                            readonly property var app: Apps.byId(modelData)
                            readonly property bool first: index === 0
                            readonly property bool last: index === root.cfg.dock.apps.length - 1
                            width: parent.width; height: 56
                            topLeftRadius: first ? 18 : 8; topRightRadius: first ? 18 : 8
                            bottomLeftRadius: last ? 18 : 8; bottomRightRadius: last ? 18 : 8
                            color: Theme.surfaceHigh
                            Row { x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                                AppIcon { app: da.app; size: 38; r: 12; anchors.verticalCenter: parent.verticalCenter }
                                Label { text: da.app ? da.app.name : da.modelData + " (не найдено)"; size: 14; w: 650; anchors.verticalCenter: parent.verticalCenter } }
                            IconButton { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                icon: "remove_circle"; size: 34; iconSize: 20
                                onClicked: Config.set("dock.apps", root.cfg.dock.apps.filter((_, i) => i !== da.index)) } } }
                    Label { visible: !root.cfg.dock.apps.length; width: parent.width; horizontalAlignment: Text.AlignHCenter; padding: 40; text: "Док пуст"; dim: true }
                }
                Flow {
                    x: 8; width: parent.width - 16; spacing: 8; bottomPadding: 8
                    Repeater { model: Apps.all.filter(a => !root.cfg.dock.apps.includes(a.id)).slice(0, 14)
                        Rectangle { id: ad; required property var modelData
                            width: adr.implicitWidth + 26; height: 36
                            radius: adm.containsMouse ? 18 : 12; color: Theme.surfaceHigh
                            Behavior on radius { SpringAnim { ms: 300 } }
                            Row { id: adr; anchors.centerIn: parent; spacing: 8
                                MIcon { text: "add"; size: 18; color: Theme.fgSurfaceVar; anchors.verticalCenter: parent.verticalCenter }
                                Label { text: ad.modelData.name; size: 13; w: 650; dim: true; anchors.verticalCenter: parent.verticalCenter } }
                            MouseArea { id: adm; anchors.fill: parent; hoverEnabled: true; onClicked: Config.set("dock.apps", root.cfg.dock.apps.concat([ad.modelData.id])) } } }
                }
            }
        }
    }

    // ---- Лаунчер ----
    Component {
        id: launcher
        Column {
            spacing: 12
            Group {
                SRow { icon: "vertical_align_bottom"; title: "Где открывается"; kw: "Снизу — выезжает из края экрана"
                    Row { spacing: 10
                        Pick { anchors.verticalCenter: parent.verticalCenter; path: "launcher.pos"; model: [{ k: "bottom", n: "Снизу" }, { k: "center", n: "По центру" }, { k: "bar", n: "Из панели" }] }
                        Mini { anchors.verticalCenter: parent.verticalCenter; icon: "open_in_new"; text: "Открыть"; onClicked: { Ui.settings = false; Ui.openLauncher(); } } } }
                SRow { icon: "grid_view"; title: "Вид"; kw: "Сетка значков или список"
                    Pick { path: "launcher.view"; model: [{ k: "grid", n: "Сетка", i: "grid_view" }, { k: "list", n: "Список", i: "list" }] } }
                SRow { icon: "category"; title: "Категории"; kw: "Список разделов слева"
                    Sw { path: "launcher.cats" } }
            }
        }
    }

    // ---- Рабочий стол ----
    Component {
        id: desk
        Column {
            spacing: 12
            Group {
                SRow { icon: "edit"; title: "Расположение виджетов"; kw: "Перетаскивайте виджеты, добавляйте и убирайте"
                    Mini { pri: true; icon: "widgets"; text: "Изменить"; onClicked: { Ui.settings = false; Ui.editing = true; } } }
                SRow { icon: "grid_4x4"; title: "Сетка привязки"; kw: "Виджеты встают по сетке в 24 px"
                    Sw { path: "desk.grid" } }
            }
            Group {
                title: "Готовые наборы"
                visible: root.query === ""
                Row { x: 10; spacing: 8; topPadding: 6; bottomPadding: 12
                    Repeater { model: Object.keys(Widgets.sets)
                        Mini { required property string modelData; text: modelData; onClicked: Config.set("desk.widgets", Config.clone(Widgets.sets[modelData])) } } }
            }
            Group {
                title: "Виджеты"
                Repeater { model: Object.keys(Widgets.types)
                    SRow { id: wr; required property string modelData; icon: Widgets.types[modelData].i; title: Widgets.types[modelData].n
                        Toggle { checked: root.cfg.desk.widgets.some(x => x.t === wr.modelData)
                            onToggled: v => {
                                if (!v) { Config.set("desk.widgets", root.cfg.desk.widgets.filter(x => x.t !== wr.modelData)); return; }
                                const f = Widgets.firstFace(wr.modelData), s = Widgets.sizeOf(wr.modelData, f);
                                Config.set("desk.widgets", root.cfg.desk.widgets.concat([{ t: wr.modelData, v: f, x: 912 - s[0] / 2 + 48, y: 528 - s[1] / 2, w: s[0], h: s[1] }]));
                            } } } }
            }
        }
    }

    // ---- Уведомления ----
    Component {
        id: notif
        Column {
            spacing: 12
            Group {
                SRow { icon: "picture_in_picture"; title: "Где появляются"; kw: "Угол или край экрана"
                    PosMap { path: "notif.pos"; opts: ["tl", "tc", "tr", "bl", "bc", "br"] } }
                SRow { icon: "do_not_disturb_on"; title: "Не беспокоить"; kw: "Уведомления копятся в центре, но не всплывают"
                    Sw { path: "notif.dnd" } }
                SRow { icon: "timer"; title: "Время показа"; kw: "Сколько висит всплывающее уведомление"
                    Range { path: "notif.secs"; lo: 3; hi: 12; step: 1; unit: " с" } }
                SRow { icon: "science"; title: "Проверить"; kw: "Показать тестовое уведомление"
                    Mini { icon: "notifications"; text: "Показать"; onClicked: Notifs.test("Тестовое уведомление", "Вот так оно выглядит и вот здесь появляется.") } }
            }
        }
    }

    // ---- О системе ----
    Process { id: uname; running: true; command: ["sh", "-c", "uname -sr; nproc; awk '/MemTotal/ {printf \"%.0f\", $2/1048576}' /proc/meminfo"]
        stdout: StdioCollector { onStreamFinished: root.sysInfo = text.trim().split("\n") } }
    property var sysInfo: []
    Component {
        id: about
        Column {
            spacing: 12
            Rectangle {
                visible: root.query === ""
                width: parent.width; height: acol.implicitHeight + 16
                radius: Theme.rm; color: Theme.surfaceMid
                Column {
                    id: acol
                    x: 8; y: 8; width: parent.width - 16
                    Row {
                        padding: 22; spacing: 22
                        MShape {
                            id: bigl
                            width: 110; height: 110
                            shape: Theme.shCookie9; color: Theme.primary
                            RotationAnimation on rotation { from: 0; to: 360; duration: 40000; loops: Animation.Infinite; running: root.shown && !Theme.still }
                            XvletMark {
                                id: aboutMark
                                anchors.centerIn: parent; width: 72; height: 72; rotation: -bigl.rotation
                                ink: Theme.fgPrimary
                                ink2: Theme.mix(Theme.fgPrimary, Theme.primary, .35)
                                ink3: Theme.mix(Theme.fgPrimary, Theme.primary, .6)
                                // the shards fly together when the page opens; then the wings breathe
                                scatter: 1
                                Component.onCompleted: scatter = 0
                                Behavior on scatter { NumberAnimation { duration: Theme.ms(1100); easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                                SequentialAnimation on flap {
                                    running: root.shown && !Theme.still; loops: Animation.Infinite
                                    NumberAnimation { to: 10; duration: 1400; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: -4; duration: 1400; easing.type: Easing.InOutSine }
                                }
                            }
                            }
                        Column { anchors.verticalCenter: parent.verticalCenter
                            Label { text: "xvlet"; size: 32; w: 750; font.letterSpacing: -.6 }
                            Label { text: "Оболочка Material 3 Expressive для Quickshell"; dim: true; size: 15; w: 550; topPadding: 4 } }
                    }
                    Grid {
                        columns: 2; columnSpacing: 20; rowSpacing: 10
                        leftPadding: 16; rightPadding: 16; topPadding: 6; bottomPadding: 14
                        Label { width: 180; text: "Система"; dim: true; w: 600 } Label { text: root.sysInfo[0] || "—"; w: 650 }
                        Label { width: 180; text: "Процессор"; dim: true; w: 600 } Label { text: root.sysInfo[1] ? root.sysInfo[1] + " ядер" : "—"; w: 650 }
                        Label { width: 180; text: "Память"; dim: true; w: 600 } Label { text: root.sysInfo[2] ? root.sysInfo[2] + " ГБ" : "—"; w: 650 }
                        Label { width: 180; text: "Цвет"; dim: true; w: 600 } Label { text: "семя " + Math.round(Theme.now.h) + "°, " + ((Theme.schemes[Theme.now.scheme] || {}).n || ""); w: 650 }
                        Label { width: 180; text: "Шрифты"; dim: true; w: 600 } Label { text: "Roboto Flex, Material Symbols Rounded"; w: 650 }
                        Label { width: 180; text: "Исходники"; dim: true; w: 600 } Label { text: "github.com/RedArtem39/xvlet-shell"; w: 650; color: Theme.primary }
                    }
                }
            }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.services

// The settings: a rail of pages and the page itself. Everything applies at
// once and is kept (Config). Ctrl+, opens it (Zerp's key), the gear in the
// quick settings too.
Item {
    id: root
    property bool shown: false
    width: 1120
    height: 760

    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    scale: shown ? 1 : .94
    Behavior on opacity { SmoothAnim { ms: 220 } }
    Behavior on scale { SpringAnim { ms: 480 } }

    readonly property var pages: [
        { k: "styles", n: "Стили", i: "auto_awesome_mosaic" }, { k: "look", n: "Оформление", i: "palette" },
        { k: "bar", n: "Панель", i: "toolbar" }, { k: "dock", n: "Док", i: "dock_to_bottom" },
        { k: "launcher", n: "Лаунчер", i: "apps" }, { k: "desk", n: "Рабочий стол", i: "widgets" },
        { k: "notif", n: "Уведомления", i: "notifications" }, { k: "about", n: "О системе", i: "info" }
    ]
    readonly property var cfg: Config.data

    Rectangle {
        anchors.fill: parent
        radius: Theme.r
        color: Theme.surfaceLow
        Behavior on color { ColorAnim {} }
        MouseArea { anchors.fill: parent; onWheel: w => w.accepted = true }
    }

    // the rail
    Column {
        id: rail
        x: 16; y: 16
        width: 236
        spacing: 4
        Item {
            width: parent.width; height: 64
            Label { x: 14; anchors.verticalCenter: parent.verticalCenter; text: "Настройки"; size: 24; w: Font.Bold }
        }
        Repeater {
            model: root.pages
            Rectangle {
                id: pg
                required property var modelData
                readonly property bool on: Ui.settingsPage === modelData.k
                width: rail.width; height: 52
                radius: on ? 26 : 16
                color: on ? Theme.secondaryContainer : pm.containsMouse ? Theme.surfaceHigh : "transparent"
                Behavior on radius { SpringAnim {} }
                Row {
                    x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 14
                    MIcon { text: pg.modelData.i; fill: pg.on; size: 22; color: pg.on ? Theme.fgSecondaryContainer : Theme.fgSurface }
                    Label { text: pg.modelData.n; size: 15; color: pg.on ? Theme.fgSecondaryContainer : Theme.fgSurface; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; onClicked: Ui.settingsPage = pg.modelData.k }
            }
        }
    }
    IconButton { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; icon: "close"; onClicked: Ui.settings = false }

    Rectangle {
        id: main
        x: rail.x + rail.width + 16; y: 16
        width: parent.width - x - 16; height: parent.height - 32
        radius: Theme.rm
        color: Theme.surface
        clip: true
        Flickable {
            id: fl
            anchors.fill: parent; anchors.margins: 24
            contentHeight: page.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            Loader {
                id: page
                width: fl.width
                sourceComponent: ({ styles: styles, look: look, bar: bar, dock: dock, launcher: launcher, desk: desk, notif: notif, about: about })[Ui.settingsPage]
                onLoaded: fl.contentY = 0
            }
        }
    }

    // ---- the pieces of a page ----
    component Head: Label { size: 26; w: Font.Bold; bottomPadding: 14 }
    component Group: Rectangle {
        default property alias rows: gcol.data
        property string title: ""
        width: parent ? parent.width : 0
        implicitHeight: gcol.implicitHeight + (title ? 46 : 12)
        radius: Theme.rm
        color: Theme.surfaceLow
        Label { x: 18; y: 14; visible: parent.title !== ""; text: parent.title; size: 13; w: Font.Bold; dim: true }
        Column { id: gcol; y: parent.title ? 40 : 6; width: parent.width; }
    }
    component Row2: Item {
        id: r
        default property alias control: ctl.data
        property string icon
        property string title
        property string sub: ""
        width: parent ? parent.width : 0
        height: Math.max(64, ctl.childrenRect.height + 20)
        MIcon { x: 18; anchors.verticalCenter: parent.verticalCenter; text: r.icon; size: 22; color: Theme.primary }
        Column {
            x: 56; anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 56 - ctl.width - 24
            Label { text: r.title; size: 15; width: parent.width }
            Label { text: r.sub; size: 12; dim: true; visible: text !== ""; width: parent.width; wrapMode: Text.WordWrap }
        }
        Item {
            id: ctl
            anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width; height: childrenRect.height
        }
    }
    component Pick: Seg {}
    component SmallBtn: Rectangle {
        id: sb
        property string icon
        property string text
        property bool primary: false
        signal clicked
        width: sbr.implicitWidth + 32; height: 40
        radius: sbm.containsMouse ? 14 : 20
        color: primary ? Theme.primary : Theme.surfaceHigh
        Behavior on radius { SpringAnim {} }
        Row { id: sbr; anchors.centerIn: parent; spacing: 8
            MIcon { text: sb.icon; size: 18; visible: sb.icon !== ""; color: sb.primary ? Theme.fgPrimary : Theme.fgSurface }
            Label { text: sb.text; size: 13; color: sb.primary ? Theme.fgPrimary : Theme.fgSurface; anchors.verticalCenter: parent.verticalCenter } }
        MouseArea { id: sbm; anchors.fill: parent; hoverEnabled: true; onClicked: sb.clicked() }
    }

    // ---- Стили: ready layouts ----
    readonly property var presets: [
        { n: "xvlet", d: "Острова сверху, док у края", c: { bar: { pos: "top", style: "islands", height: 52, ws: "pill", clock: "date", mods: mods({ logo: "start", ws: "start", media: "center", tray: "end", weather: "end", status: "end", bell: "end", clock: "end", power: "end" }) }, dock: { on: true, style: "attached", pos: "bottom", autohide: "smart", labels: false }, launcher: { pos: "bottom" } } },
        { n: "Exo", d: "Панель прилегает, док — полоса слева", c: { bar: { pos: "top", style: "flush", height: 40, ws: "dots", clock: "date", mods: mods({ ws: "start", media: "start", clock: "center", tray: "end", status: "end", bell: "end" }) }, dock: { on: true, style: "strip", pos: "left", autohide: "off", labels: false, size: 40 }, launcher: { pos: "center" }, theme: { shellCorners: true } } },
        { n: "Сегменты", d: "Части панели свисают с края", c: { bar: { pos: "top", style: "seg", height: 48, ws: "pill", clock: "date", mods: mods({ logo: "start", ws: "start", media: "center", tray: "end", status: "end", clock: "end", power: "end" }) }, dock: { on: true, style: "attached", pos: "bottom", autohide: "smart", labels: false }, launcher: { pos: "bottom" } } },
        { n: "Классика", d: "Сплошная снизу, задачи в панели", c: { bar: { pos: "bottom", style: "solid", height: 52, ws: "numbers", clock: "date", mods: mods({ logo: "start", tasks: "start", media: "center", tray: "end", weather: "end", status: "end", bell: "end", clock: "end", power: "end" }) }, dock: { on: false }, launcher: { pos: "bottom" } } },
        { n: "Вертикальная", d: "Панель слева, док снизу", c: { bar: { pos: "left", style: "islands", height: 52, ws: "pill", clock: "date", mods: mods({ logo: "start", ws: "start", media: "center", status: "end", bell: "end", clock: "end", power: "end" }) }, dock: { on: true, style: "attached", pos: "bottom", autohide: "smart", labels: false }, launcher: { pos: "center" } } },
        { n: "Рабочая станция", d: "Ресурсы в панели, док справа", c: { bar: { pos: "top", style: "solid", height: 46, ws: "numbers", clock: "date", mods: mods({ logo: "start", ws: "start", tasks: "start", sysmon: "center", tray: "end", status: "end", bell: "end", clock: "end", power: "end" }) }, dock: { on: true, style: "attached", pos: "right", autohide: "off", labels: false, size: 44 }, launcher: { pos: "center" } } },
        { n: "Минимум", d: "Тонкая панель, док прячется", c: { bar: { pos: "top", style: "islands", height: 44, ws: "dots", clock: "time", mods: mods({ ws: "start", clock: "center", status: "end" }) }, dock: { on: true, style: "floating", pos: "bottom", autohide: "always", labels: false }, launcher: { pos: "center" } } }
    ]
    function mods(on) { const all = ["logo", "ws", "tasks", "media", "tray", "sysmon", "weather", "status", "bell", "clock", "power"], o = {}; for (const k of all) o[k] = on[k] || "off"; return o; }
    function applyPreset(p) { Config.data = Config.merge(Config.data, p.c); Config.set("theme.radius", Config.data.theme.radius); }

    Component {
        id: styles
        Column {
            spacing: 16
            Head { text: "Стили" }
            Grid {
                width: parent.width; columns: 2; spacing: 12
                Repeater {
                    model: root.presets
                    Rectangle {
                        id: ps
                        required property var modelData
                        width: (parent.width - 12) / 2; height: 168
                        radius: pm2.containsMouse ? Theme.r : Theme.rm
                        color: Theme.surfaceLow
                        Behavior on radius { SpringAnim {} }
                        // a small picture of the layout: the bar and the dock
                        Rectangle {
                            x: 16; y: 16; width: parent.width - 32; height: 96; radius: 16
                            color: Theme.surfaceHighest
                            readonly property var b: ps.modelData.c.bar
                            readonly property var d: ps.modelData.c.dock
                            Rectangle {
                                readonly property bool v: parent.b.pos === "left" || parent.b.pos === "right"
                                color: parent.b.style === "islands" ? Theme.primary : Theme.primaryContainer
                                radius: parent.b.style === "islands" ? 5 : 0
                                width: v ? 10 : parent.width - (parent.b.style === "islands" ? 16 : 0)
                                height: v ? parent.height - (parent.b.style === "islands" ? 16 : 0) : 10
                                x: v ? (parent.b.pos === "left" ? 4 : parent.width - 14) : (parent.b.style === "islands" ? 8 : 0)
                                y: v ? (parent.b.style === "islands" ? 8 : 0) : (parent.b.pos === "top" ? 4 : parent.height - 14)
                            }
                            Rectangle {
                                visible: parent.d.on !== false
                                readonly property bool v: parent.d.pos === "left" || parent.d.pos === "right"
                                readonly property bool s: parent.d.style === "strip"
                                color: Theme.tertiary
                                radius: s ? 0 : 6
                                width: v ? 12 : (s ? parent.width : parent.width * .4)
                                height: v ? (s ? parent.height : parent.height * .5) : 12
                                x: v ? (parent.d.pos === "left" ? 0 : parent.width - 12) : (parent.width - width) / 2
                                y: v ? (parent.height - height) / 2 : (parent.d.pos === "bottom" ? parent.height - 12 : 0)
                            }
                        }
                        Column {
                            x: 18; y: 120
                            Label { text: ps.modelData.n; size: 15; w: Font.Bold }
                            Label { text: ps.modelData.d; size: 12; dim: true }
                        }
                        MouseArea { id: pm2; anchors.fill: parent; hoverEnabled: true; onClicked: root.applyPreset(ps.modelData) }
                    }
                }
            }
            Group {
                Row2 { icon: "restart_alt"; title: "Сбросить всё"; sub: "Все настройки оболочки — как при первом запуске"
                    SmallBtn { text: "Сбросить"; icon: "restart_alt"; onClicked: { Config.data = Config.clone(Config.defaults); Config.set("theme.mode", "dark"); } } }
            }
        }
    }

    // ---- Оформление: Material 3 dynamic colour, saved themes ----
    Component {
        id: look
        Column {
            spacing: 16
            Head { text: "Оформление" }
            Group {
                title: "Цвет"
                Row2 { icon: "palette"; title: "Источник цвета"
                    Seg { model: [{ k: "wall", n: "Обои" }, { k: "custom", n: "Свой" }, { k: "saved", n: "Сохранённая" }]; value: root.cfg.theme.src; onPicked: k => Config.set("theme.src", k) } }
                Row2 { icon: "wallpaper"; title: "Цвета обоев"; sub: "Цвета, найденные в пикселях обоев"; visible: root.cfg.theme.src === "wall"
                    Row { spacing: 8
                        Repeater { model: Theme.wallSeeds
                            Rectangle { id: sw; required property var modelData; required property int index
                                width: 44; height: 44; radius: root.cfg.theme.seed === index ? 14 : 22
                                color: Theme.oklch(72, modelData.c, modelData.h)
                                border.width: root.cfg.theme.seed === index ? 3 : 0; border.color: Theme.fgSurface
                                Behavior on radius { SpringAnim {} }
                                MouseArea { anchors.fill: parent; onClicked: Config.set("theme.seed", sw.index) } } } } }
                Row2 { icon: "colorize"; title: "Цвет"; sub: "Оттенок: " + Math.round(root.cfg.theme.custom) + "°"; visible: root.cfg.theme.src === "custom"
                    Row { spacing: 6
                        Repeater { model: [285, 330, 15, 55, 95, 145, 190, 235]
                            Rectangle { id: ac; required property real modelData
                                width: 34; height: 34; radius: Math.abs(root.cfg.theme.custom - modelData) < 1 ? 11 : 17
                                color: Theme.oklch(70, .15, modelData)
                                Behavior on radius { SpringAnim {} }
                                MouseArea { anchors.fill: parent; onClicked: Config.set("theme.custom", ac.modelData) } } } } }
                Row2 { icon: "tune"; title: "Схема"; sub: (Theme.schemes[root.cfg.theme.scheme] || {}).n || ""
                    Grid { columns: 4; spacing: 6
                        Repeater { model: Object.keys(Theme.schemes)
                            Rectangle { id: sc; required property string modelData
                                readonly property var p: Theme.paletteOf({ h: Theme.now.h, c: Theme.now.c, scheme: modelData })
                                width: 70; height: 40; radius: root.cfg.theme.scheme === modelData ? 20 : 12
                                color: root.cfg.theme.scheme === modelData ? Theme.secondaryContainer : Theme.surfaceHigh
                                Behavior on radius { SpringAnim {} }
                                Row { anchors.centerIn: parent; spacing: -6
                                    Rectangle { width: 22; height: 22; radius: 11; color: Theme.oklch(75, sc.p.cp, sc.p.hp) }
                                    Rectangle { width: 22; height: 22; radius: 11; color: Theme.oklch(70, sc.p.cs * 2, sc.p.hs) }
                                    Rectangle { width: 22; height: 22; radius: 11; color: Theme.oklch(75, sc.p.ct, sc.p.ht) } }
                                MouseArea { anchors.fill: parent; onClicked: Config.set("theme.scheme", sc.modelData) } } } } }
                Row2 { icon: "contrast"; title: "Тема"
                    Seg { model: [{ k: "dark", n: "Тёмная", i: "dark_mode" }, { k: "light", n: "Светлая", i: "light_mode" }]; value: root.cfg.theme.mode; onPicked: k => Config.set("theme.mode", k) } }
            }
            Group {
                title: "Мои темы"
                Row2 { icon: "bookmark_add"; title: "Сохранить текущую"; sub: "Цвета остаются с вами при любых обоях и раскладке"
                    SmallBtn { text: "Сохранить"; icon: "add"; primary: true
                        onClicked: { const t = Theme.now, s = (root.cfg.theme.saved || []).concat([{ n: "Тема " + ((root.cfg.theme.saved || []).length + 1), h: t.h, c: t.c, scheme: t.scheme, mode: t.mode }]); Config.set("theme.saved", s); } } }
                Flow {
                    width: parent.width; spacing: 10; padding: 14
                    Repeater { model: root.cfg.theme.saved || []
                        Rectangle { id: st; required property var modelData; required property int index
                            readonly property var p: Theme.paletteOf(modelData)
                            readonly property bool on: root.cfg.theme.src === "saved" && root.cfg.theme.active === index
                            width: 200; height: 96; radius: on ? 30 : 20
                            color: Theme.oklch(modelData.mode === "light" ? 95 : 22, p.cn, p.hn)
                            border.width: on ? 3 : 0; border.color: Theme.primary
                            Behavior on radius { SpringAnim {} }
                            Label { x: 14; y: 12; text: st.modelData.n; size: 14; w: Font.Bold; color: st.modelData.mode === "light" ? "#222" : "#eee" }
                            Row { x: 14; y: 56; spacing: 4
                                Repeater { model: [[st.p.cp, st.p.hp], [st.p.cs * 2, st.p.hs], [st.p.ct, st.p.ht]]
                                    Rectangle { required property var modelData; width: 52; height: 24; radius: 8; color: Theme.oklch(72, modelData[0], modelData[1]) } } }
                            MouseArea { anchors.fill: parent; onClicked: { Config.set("theme.active", st.index); Config.set("theme.src", "saved"); } }
                            IconButton { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 4; icon: "close"; size: 28; iconSize: 16
                                onClicked: { const s = root.cfg.theme.saved.filter((_, i) => i !== st.index); Config.set("theme.saved", s); if (root.cfg.theme.src === "saved") Config.set("theme.src", "wall"); } } } }
                }
            }
            Group {
                title: "Форма и движение"
                Row2 { icon: "rounded_corner"; title: "Скругление"; sub: Math.round(root.cfg.theme.radius * 100) + "%"
                    MSlider { width: 280; value: (root.cfg.theme.radius - .4) / 1.2; showValue: false; onMoved: v => Config.set("theme.radius", Math.round((.4 + v * 1.2) * 20) / 20) } }
                Row2 { icon: "motion_photos_on"; title: "Анимации"
                    Seg { model: [{ k: "spring", n: "Пружинные" }, { k: "smooth", n: "Плавные" }, { k: "off", n: "Без" }]; value: root.cfg.theme.motion; onPicked: k => Config.set("theme.motion", k) } }
                Row2 { icon: "rounded_corner"; title: "Скруглённые углы оболочки"; sub: "Когда панель прилегает к краю (стиль Exo)"
                    Toggle { checked: root.cfg.theme.shellCorners; onToggled: v => Config.set("theme.shellCorners", v) } }
            }
            Group {
                title: "Обои"
                Row2 { icon: "image"; title: "Обои"; sub: (root.cfg.wall.path || "").split("/").pop()
                    SmallBtn { text: "Выбрать"; icon: "wallpaper"; onClicked: { Ui.settings = false; Ui.wallpick = true; } } }
                Row2 { icon: "animation"; title: "Переход"
                    Seg { model: [{ k: "circle", n: "Круг" }, { k: "fade", n: "Наплыв" }, { k: "wipe", n: "Шторка" }, { k: "zoom", n: "Зум" }]; value: root.cfg.wall.trans; onPicked: k => Config.set("wall.trans", k) } }
            }
        }
    }

    // ---- Панель ----
    readonly property var modNames: [
        { k: "logo", n: "Меню приложений", i: "auto_awesome" }, { k: "ws", n: "Рабочие столы", i: "workspaces" },
        { k: "tasks", n: "Задачи", i: "view_week" }, { k: "media", n: "Медиа", i: "music_note" },
        { k: "tray", n: "Трей", i: "apps" }, { k: "sysmon", n: "Ресурсы", i: "memory" },
        { k: "weather", n: "Погода", i: "partly_cloudy_day" }, { k: "status", n: "Статус", i: "wifi" },
        { k: "bell", n: "Уведомления", i: "notifications" }, { k: "clock", n: "Часы", i: "schedule" },
        { k: "power", n: "Питание", i: "power_settings_new" }
    ]
    Component {
        id: bar
        Column {
            spacing: 16
            Head { text: "Панель" }
            Group {
                Row2 { icon: "vertical_align_top"; title: "Положение"
                    Seg { model: [{ k: "top", n: "Сверху" }, { k: "bottom", n: "Снизу" }, { k: "left", n: "Слева" }, { k: "right", n: "Справа" }]; value: root.cfg.bar.pos; onPicked: k => Config.set("bar.pos", k) } }
                Row2 { icon: "view_agenda"; title: "Стиль"
                    Seg { model: [{ k: "islands", n: "Острова" }, { k: "flush", n: "Прилегает" }, { k: "solid", n: "Сплошная" }, { k: "seg", n: "Сегменты" }]; value: root.cfg.bar.style; onPicked: k => Config.set("bar.style", k) } }
                Row2 { icon: "height"; title: "Толщина"; sub: root.cfg.bar.height + " px"
                    MSlider { width: 280; showValue: false; value: (root.cfg.bar.height - 36) / 28; onMoved: v => Config.set("bar.height", Math.round(36 + v * 28)) } }
                Row2 { icon: "workspaces"; title: "Рабочие столы"
                    Seg { model: [{ k: "pill", n: "Пилюля" }, { k: "numbers", n: "Цифры" }, { k: "dots", n: "Точки" }]; value: root.cfg.bar.ws; onPicked: k => Config.set("bar.ws", k) } }
                Row2 { icon: "schedule"; title: "Часы"
                    Seg { model: [{ k: "time", n: "Время" }, { k: "date", n: "Время и дата" }]; value: root.cfg.bar.clock; onPicked: k => Config.set("bar.clock", k) } }
            }
            Group {
                title: "Модули — где стоят"
                Repeater {
                    model: root.modNames
                    Row2 { id: mr; required property var modelData; icon: modelData.i; title: modelData.n
                        Seg { model: [{ k: "start", n: "Начало" }, { k: "center", n: "Центр" }, { k: "end", n: "Конец" }, { k: "off", n: "Нет" }]; value: root.cfg.bar.mods[mr.modelData.k] || "off"; onPicked: k => Config.set("bar.mods." + mr.modelData.k, k) } }
                }
            }
        }
    }

    // ---- Док ----
    Component {
        id: dock
        Column {
            spacing: 16
            Head { text: "Док" }
            Group {
                Row2 { icon: "dock_to_bottom"; title: "Показывать док"
                    Toggle { checked: root.cfg.dock.on; onToggled: v => Config.set("dock.on", v) } }
                Row2 { icon: "crop_square"; title: "Стиль"; sub: root.cfg.dock.pos === root.cfg.bar.pos ? "На краю панели док всегда плавающий" : ""
                    Seg { model: [{ k: "attached", n: "У края" }, { k: "floating", n: "Плавающий" }, { k: "strip", n: "Полоса" }]; value: root.cfg.dock.style; onPicked: k => Config.set("dock.style", k) } }
                Row2 { icon: "dock_to_left"; title: "Положение"
                    Seg { model: [{ k: "bottom", n: "Снизу" }, { k: "left", n: "Слева" }, { k: "right", n: "Справа" }, { k: "top", n: "Сверху" }]; value: root.cfg.dock.pos; onPicked: k => Config.set("dock.pos", k) } }
                Row2 { icon: "photo_size_select_small"; title: "Размер значков"; sub: root.cfg.dock.size + " px"
                    MSlider { width: 280; showValue: false; value: (root.cfg.dock.size - 24) / 48; onMoved: v => Config.set("dock.size", Math.round((24 + v * 48) / 2) * 2) } }
                Row2 { icon: "zoom_in"; title: "Увеличение при наведении"; sub: Math.round(root.cfg.dock.zoom * 100) + "%"
                    MSlider { width: 280; showValue: false; value: (root.cfg.dock.zoom - 1) / .5; onMoved: v => Config.set("dock.zoom", Math.round((1 + v * .5) * 20) / 20) } }
                Row2 { icon: "label"; title: "Подписи"
                    Toggle { checked: root.cfg.dock.labels; onToggled: v => Config.set("dock.labels", v) } }
                Row2 { icon: "more_horiz"; title: "Индикаторы запущенных"
                    Toggle { checked: root.cfg.dock.inds; onToggled: v => Config.set("dock.inds", v) } }
                Row2 { icon: "visibility_off"; title: "Автоскрытие"; sub: "«Умное» — прячется, когда на столе есть окна"
                    Seg { model: [{ k: "off", n: "Нет" }, { k: "smart", n: "Умное" }, { k: "always", n: "Всегда" }]; value: root.cfg.dock.autohide; onPicked: k => Config.set("dock.autohide", k) } }
            }
            Group {
                title: "Закреплённые"
                Flow {
                    width: parent.width; spacing: 8; padding: 14
                    Repeater { model: root.cfg.dock.apps
                        Rectangle { id: pa; required property string modelData; required property int index
                            readonly property var app: Apps.byId(modelData)
                            width: par.implicitWidth + 24; height: 52; radius: 18; color: Theme.surfaceHigh
                            Row { id: par; anchors.centerIn: parent; spacing: 10
                                AppIcon { app: pa.app; size: 32; anchors.verticalCenter: parent.verticalCenter }
                                Label { text: pa.app ? pa.app.name : pa.modelData + " (нет)"; size: 13; anchors.verticalCenter: parent.verticalCenter }
                                IconButton { icon: "close"; size: 28; iconSize: 16; onClicked: Config.set("dock.apps", root.cfg.dock.apps.filter(x => x !== pa.modelData)) } } } }
                }
                Label { x: 18; text: "Закрепить: правый клик по значку в доке"; size: 12; dim: true; bottomPadding: 14 }
            }
        }
    }

    // ---- Лаунчер ----
    Component {
        id: launcher
        Column {
            spacing: 16
            Head { text: "Лаунчер" }
            Group {
                Row2 { icon: "vertical_align_bottom"; title: "Где открывается"
                    Seg { model: [{ k: "bottom", n: "Снизу" }, { k: "center", n: "В центре" }, { k: "top", n: "Сверху" }]; value: root.cfg.launcher.pos; onPicked: k => Config.set("launcher.pos", k) } }
                Row2 { icon: "grid_view"; title: "Вид"
                    Seg { model: [{ k: "grid", n: "Сетка" }, { k: "list", n: "Список" }]; value: root.cfg.launcher.view; onPicked: k => Config.set("launcher.view", k) } }
                Row2 { icon: "apps"; title: "Приложений"; sub: Apps.all.length + " — из *.desktop в системе и у вас"
                    SmallBtn { text: "Открыть"; icon: "open_in_new"; onClicked: { Ui.settings = false; Ui.openLauncher(); } } }
            }
        }
    }

    // ---- Рабочий стол ----
    Component {
        id: desk
        Column {
            spacing: 16
            Head { text: "Рабочий стол" }
            Group {
                Row2 { icon: "edit"; title: "Расположение виджетов"; sub: "Перетаскивайте, тяните за угол, вращайте; вид — на панели виджета"
                    SmallBtn { text: Ui.editing ? "Готово" : "Изменить"; icon: Ui.editing ? "check" : "edit"; primary: true; onClicked: { Ui.editing = !Ui.editing; Ui.settings = false; } } }
                Row2 { icon: "grid_4x4"; title: "Сетка"; sub: "Виджеты встают по сетке 24 px"
                    Toggle { checked: root.cfg.desk.grid; onToggled: v => Config.set("desk.grid", v) } }
                Row2 { icon: "dashboard_customize"; title: "Наборы"
                    Row { spacing: 8
                        SmallBtn { text: "Обзор"; onClicked: Config.set("desk.widgets", Widgets.sets["Обзор"]) }
                        SmallBtn { text: "Медиа"; onClicked: Config.set("desk.widgets", Widgets.sets["Медиа"]) }
                        SmallBtn { text: "Минимум"; onClicked: Config.set("desk.widgets", Widgets.sets["Минимум"]) }
                        SmallBtn { text: "Очистить"; onClicked: Config.set("desk.widgets", []) } } }
            }
        }
    }

    // ---- Уведомления ----
    Component {
        id: notif
        Column {
            spacing: 16
            Head { text: "Уведомления" }
            Group {
                Row2 { icon: "picture_in_picture"; title: "Где появляются"
                    Seg { model: [{ k: "tl", n: "↖" }, { k: "tc", n: "↑" }, { k: "tr", n: "↗" }, { k: "bl", n: "↙" }, { k: "bc", n: "↓" }, { k: "br", n: "↘" }]; value: root.cfg.notif.pos; onPicked: k => Config.set("notif.pos", k) } }
                Row2 { icon: "do_not_disturb_on"; title: "Не беспокоить"; sub: "Всплывают только срочные"
                    Toggle { checked: root.cfg.notif.dnd; onToggled: v => Config.set("notif.dnd", v) } }
                Row2 { icon: "timer"; title: "Время показа"; sub: root.cfg.notif.secs + " с"
                    MSlider { width: 280; showValue: false; value: (root.cfg.notif.secs - 3) / 12; onMoved: v => Config.set("notif.secs", Math.round(3 + v * 12)) } }
                Row2 { icon: "science"; title: "Проверить"
                    SmallBtn { text: "Прислать"; icon: "send"; onClicked: Notifs.test("Тестовое уведомление", "Всплывает и уходит через " + root.cfg.notif.secs + " с") } }
            }
        }
    }

    // ---- О системе ----
    Process { id: uname; running: true; command: ["uname", "-srm"]; stdout: StdioCollector { onStreamFinished: root.osText = text.trim() } }
    property string osText: ""
    Component {
        id: about
        Column {
            spacing: 16
            Head { text: "О системе" }
            Group {
                Item {
                    width: parent.width; height: 140
                    MShape { x: 24; anchors.verticalCenter: parent.verticalCenter; width: 92; height: 92; shape: Theme.shFlower; color: Theme.primary
                        MIcon { anchors.centerIn: parent; text: "auto_awesome"; fill: true; size: 40; color: Theme.fgPrimary } }
                    Column { x: 136; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                        Label { text: "xvlet"; size: 28; w: Font.Bold }
                        Label { text: "Оболочка Material 3 Expressive для Quickshell"; size: 14; dim: true }
                        Label { text: "github.com/RedArtem39/xvlet-shell"; size: 13; color: Theme.primary } }
                }
                Row2 { icon: "computer"; title: "Система"; sub: root.osText || "—" }
                Row2 { icon: "palette"; title: "Палитра"; sub: "Семя " + Math.round(Theme.now.h) + "°, " + ((Theme.schemes[Theme.now.scheme] || {}).n || "") }
                Row2 { icon: "font_download"; title: "Шрифты"; sub: "Roboto Flex (OFL), Material Symbols Rounded" }
            }
        }
    }
}

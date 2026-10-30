import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.services

// The dashboard (the prototype's #dash, from the clock): three tabs -- the
// overview (the user, the weather, the month, what plays), the media, the
// system (four gauges, the processor's last minutes).
Popout {
    id: root
    width: 860
    height: tabs.height + 14 + pages.height + 36

    property string uptime: ""
    Cat {
        id: up
        path: "/proc/uptime"
        onLoaded: t => { const x = parseFloat(t), h = Math.floor(x / 3600), m = Math.floor(x % 3600 / 60); root.uptime = (h ? h + " ч " : "") + m + " мин"; }
    }
    onShownChanged: if (shown) { up.reload(); rise(); }

    // the cards of the tab on show come in one after another (opening,
    // or another tab)
    readonly property var rises: ({ ov: [r1, r2, r3, r4], md: [r5], pf: [r6, r7, r8, r9, r10] })
    function rise() { for (const r of rises[Ui.dashTab] || []) r.restart(); }
    Connections { target: Ui; function onDashTabChanged() { if (root.shown) root.rise(); } }
    Rise { id: r1; target: rUser; index: 0 }
    Rise { id: r2; target: wcard; index: 1 }
    Rise { id: r3; target: rCal; index: 2 }
    Rise { id: r4; target: rMedia; index: 3 }
    Rise { id: r5; target: md; index: 0 }
    Rise { id: r6; target: g1; index: 0 }
    Rise { id: r7; target: g2; index: 1 }
    Rise { id: r8; target: g3; index: 2 }
    Rise { id: r9; target: g4; index: 3 }
    Rise { id: r10; target: rGraph; index: 4 }

    // the tabs: a connected group, the chosen one round
    Row {
        id: tabs
        width: parent.width; height: 44
        spacing: 2
        Repeater {
            model: [{ k: "ov", n: "Обзор", i: "dashboard" }, { k: "md", n: "Медиа", i: "album" }, { k: "pf", n: "Система", i: "monitoring" }]
            Item {
                id: tab
                required property var modelData
                required property int index
                readonly property bool on: Ui.dashTab === modelData.k
                readonly property real rl: on || index === 0 ? 22 : 8
                readonly property real rr: on || index === 2 ? 22 : 8
                width: (tabs.width - 4) / 3; height: 44
                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: tab.rl; bottomLeftRadius: tab.rl; topRightRadius: tab.rr; bottomRightRadius: tab.rr
                    color: tab.on ? Theme.secondaryContainer : ma.containsMouse ? Theme.surfaceHighest : Theme.surfaceHigh
                    Behavior on color { ColorAnim { ms: 250 } }
                    Behavior on topLeftRadius { SpringAnim { ms: 400 } }
                    Behavior on bottomLeftRadius { SpringAnim { ms: 400 } }
                    Behavior on topRightRadius { SpringAnim { ms: 400 } }
                    Behavior on bottomRightRadius { SpringAnim { ms: 400 } }
                }
                Row {
                    anchors.centerIn: parent; spacing: 8
                    MIcon { text: tab.modelData.i; size: 20; color: tl.color }
                    Label { id: tl; text: tab.modelData.n; size: 14; w: 650; color: tab.on ? Theme.fgSecondaryContainer : Theme.fgSurfaceVar; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: Ui.dashTab = tab.modelData.k }
            }
        }
    }

    Item {
        id: pages
        y: tabs.height + 14
        width: parent.width
        height: Ui.dashTab === "ov" ? ov.implicitHeight : Ui.dashTab === "md" ? md.implicitHeight : pf.implicitHeight

        // ---- the overview: 300 px and the rest ----
        Grid {
            id: ov
            visible: Ui.dashTab === "ov"
            width: parent.width
            columns: 2
            spacing: 10
            // the user
            Card {
                id: rUser
                width: 300; height: Math.max(prof.implicitHeight, wth.implicitHeight) + 36
                Row {
                    id: prof
                    x: 18; anchors.verticalCenter: parent.verticalCenter; spacing: 16
                    MShape {
                        width: 72; height: 72; shape: am.containsMouse ? Theme.shFlower : Theme.shCookie9; color: Theme.tertiaryContainer
                        anchors.verticalCenter: parent.verticalCenter
                        Label { anchors.centerIn: parent; text: (Quickshell.env("USER") || "?")[0].toUpperCase(); size: 30; w: 750; color: Theme.fgTertiaryContainer }
                        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Label { text: Quickshell.env("USER") || "user"; size: 20; w: 700 }
                        Label { text: "WynlandOS"; size: 13; w: 550; dim: true; topPadding: 3 }
                        Item { width: 1; height: 8 }
                        Rectangle {
                            width: upRow.implicitWidth + 24; height: 28; radius: 14
                            color: Theme.secondaryContainer
                            Row { id: upRow; anchors.centerIn: parent; spacing: 6
                                MIcon { text: "schedule"; size: 16; color: Theme.fgSecondaryContainer; anchors.verticalCenter: parent.verticalCenter }
                                Label { text: "работает " + root.uptime; size: 12; w: 650; color: Theme.fgSecondaryContainer; anchors.verticalCenter: parent.verticalCenter } }
                        }
                    }
                }
            }
            // the weather: the gradient card
            Rectangle {
                id: wcard
                width: ov.width - 310; height: Math.max(prof.implicitHeight, wth.implicitHeight) + 36
                radius: Theme.rm
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.primaryContainer }
                    GradientStop { position: 1; color: Theme.tertiaryContainer }
                }
                Row {
                    id: wth
                    x: 18; anchors.verticalCenter: parent.verticalCenter; spacing: 18
                    MShape {
                        width: 84; height: 84; shape: Theme.shSunny
                        color: Weather.ok ? Theme.oklch(85, .14, 85) : Theme.alpha(Theme.fgPrimaryContainer, .15)
                        anchors.verticalCenter: parent.verticalCenter
                        RotationAnimation on rotation { from: 0; to: 360; duration: 30000; loops: Animation.Infinite; running: root.shown && Weather.ok && !Theme.still }
                        MIcon { anchors.centerIn: parent; visible: !Weather.ok; text: "cloud_off"; size: 32; color: Theme.fgPrimaryContainer }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Label { text: Weather.ok ? Weather.sign(Weather.temp) : "Нет данных"; size: Weather.ok ? 54 : 26; w: Weather.ok ? 300 : 650; font.letterSpacing: Weather.ok ? -2 : 0; color: Theme.fgPrimaryContainer }
                        Label { text: Weather.ok ? Weather.desc + " · ощущается как " + Weather.sign(Weather.feels) : "погода появится, когда будет сеть"; size: 14; w: 600; color: Theme.fgPrimaryContainer; opacity: .85; topPadding: 4
                                width: wcard.width - 18 - 84 - 18 - (Weather.ok ? fc.width + 18 : 0) - 18 }
                    }
                }
                Row {
                    id: fc
                    visible: Weather.ok
                    anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Repeater {
                        model: Weather.days
                        Rectangle {
                            id: day
                            required property var modelData
                            width: 54; height: dcol.implicitHeight + 20; radius: 27; color: Qt.rgba(1, 1, 1, .12)
                            Column { id: dcol; anchors.centerIn: parent; spacing: 6
                                Label { text: day.modelData.d; size: 12; w: 650; color: Theme.fgPrimaryContainer; anchors.horizontalCenter: parent.horizontalCenter }
                                MIcon { text: day.modelData.icon; fill: true; size: 22; color: Theme.fgPrimaryContainer; anchors.horizontalCenter: parent.horizontalCenter }
                                Label { text: Weather.sign(day.modelData.t); size: 12; w: 650; color: Theme.fgPrimaryContainer; anchors.horizontalCenter: parent.horizontalCenter } }
                        }
                    }
                }
            }
            // the month
            Card {
                id: rCal
                width: 300; height: Math.max(cal.implicitHeight, 280) + 36
                Calendar { id: cal; x: 18; y: 18; width: parent.width - 36 }
            }
            // what plays
            Card {
                id: rMedia
                width: ov.width - 310; height: Math.max(cal.implicitHeight, 280) + 36
                MediaCard { x: 18; width: parent.width - 36; anchors.verticalCenter: parent.verticalCenter; art: 132 }
            }
        }

        // ---- the media ----
        Card {
            id: md
            visible: Ui.dashTab === "md"
            width: parent.width; implicitHeight: 256
            height: implicitHeight
            MediaCard { x: 18; width: parent.width - 36; anchors.verticalCenter: parent.verticalCenter; art: 220; big: true }
        }

        // ---- the system: four gauges, the processor's history ----
        Column {
            id: pf
            visible: Ui.dashTab === "pf"
            width: parent.width
            spacing: 10
            Row { spacing: 10
            Gauge { id: g1; name: "Процессор"; sub: Sys.cores + " ядер"; v: Sys.cpu }
            Gauge { id: g2; name: "Память"; sub: Sys.ramUsedGb.toFixed(1).replace(".", ",") + " из " + Sys.ramTotalGb.toFixed(0) + " ГБ"; v: Sys.ram }
            Gauge { id: g3; name: "Диск"; sub: Sys.diskText || "—"; v: Sys.disk }
            Gauge { id: g4; name: "Температура"; sub: Sys.temp >= 0 ? "процессор" : "датчика нет"; v: Sys.temp >= 0 ? Sys.temp / 100 : 0; label: Sys.temp >= 0 ? Math.round(Sys.temp) + "°" : "нет" }
            }
            Card {
                id: rGraph
                width: pf.width; height: 126
                Row {
                    x: 18; anchors.verticalCenter: parent.verticalCenter; spacing: 18
                    Column {
                        width: 150; anchors.verticalCenter: parent.verticalCenter
                        Label { text: "Процессор"; size: 15; w: 700 }
                        Label { text: "последние 3 минуты"; size: 12; w: 600; dim: true }
                    }
                    Canvas {
                        id: graph
                        width: pf.width - 36 - 150 - 18; height: 90
                        property var h: Sys.history
                        property color c: Theme.primary
                        onHChanged: requestPaint()
                        onCChanged: requestPaint()
                        onPaint: {
                            const g = getContext("2d"), W = width, H = height, n = Math.max(2, h.length);
                            g.reset();
                            const pts = h.map((v, i) => [i / (n - 1) * W, H - 6 - v * (H - 12)]);
                            if (pts.length < 2) return;
                            const path = () => { g.moveTo(pts[0][0], pts[0][1]); for (let i = 1; i < pts.length; i++) { const [px, py] = pts[i - 1], [x, y] = pts[i]; g.bezierCurveTo((px + x) / 2, py, (px + x) / 2, y, x, y); } };
                            const gr = g.createLinearGradient(0, 0, 0, H); gr.addColorStop(0, Qt.rgba(c.r, c.g, c.b, .35)); gr.addColorStop(1, Qt.rgba(c.r, c.g, c.b, 0));
                            g.beginPath(); path(); g.lineTo(pts[pts.length - 1][0], H); g.lineTo(pts[0][0], H); g.closePath(); g.fillStyle = gr; g.fill();
                            g.beginPath(); path(); g.strokeStyle = c; g.lineWidth = 4; g.stroke();
                        }
                    }
                }
            }
        }
    }

    // one of the system tab's gauges (.gauge)
    component Gauge: Card {
        id: g
        property string name
        property string sub
        property real v
        property string label: Math.round(v * 100) + "%"
        width: (pf.width - 30) / 4; height: gcol.implicitHeight + 38
        Column {
            id: gcol
            y: 20; anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
            Ring { width: 150; height: 150; anchors.horizontalCenter: parent.horizontalCenter; value: g.v; label: g.label }
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                Label { text: g.name; size: 15; w: 700; anchors.horizontalCenter: parent.horizontalCenter }
                Label { text: g.sub; size: 12; w: 600; dim: true; anchors.horizontalCenter: parent.horizontalCenter; topPadding: 2 }
            }
        }
    }
}

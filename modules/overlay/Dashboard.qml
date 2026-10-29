import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.services

// The dashboard (from the clock): three tabs -- the overview (the user, the
// weather, the month, what plays), the media, the system (four gauges, the
// processor's last minutes). Cards come in one after another.
Popout {
    id: root
    width: 900
    height: 560

    // one of the system tab's gauges
    component Gauge: Card {
        id: g
        property string name
        property string sub
        property real v
        property string label: Math.round(v * 100) + "%"
        width: (pages.width - 36) / 4; height: 250
        Column {
            anchors.centerIn: parent; spacing: 4
            Ring { width: 150; height: 150; anchors.horizontalCenter: parent.horizontalCenter; value: g.v; label: g.label }
            Label { text: g.name; size: 15; w: Font.Bold; anchors.horizontalCenter: parent.horizontalCenter }
            Label { text: g.sub; size: 12; dim: true; anchors.horizontalCenter: parent.horizontalCenter }
        }
    }

    property string uptime: ""
    Cat {
        id: up
        path: "/proc/uptime"
        onLoaded: t => { const x = parseFloat(t), h = Math.floor(x / 3600), m = Math.floor(x % 3600 / 60); root.uptime = (h ? h + " ч " : "") + m + " мин"; }
    }
    onShownChanged: if (shown) up.reload()

    Row {
        id: tabs
        width: parent.width
        spacing: 6
        Repeater {
            model: [{ k: "ov", n: "Обзор", i: "dashboard" }, { k: "md", n: "Медиа", i: "album" }, { k: "pf", n: "Система", i: "monitoring" }]
            Rectangle {
                id: tab
                required property var modelData
                readonly property bool on: Ui.dashTab === modelData.k
                width: (tabs.width - 12) / 3; height: 44
                radius: on ? 22 : 14
                color: on ? Theme.secondaryContainer : ma.containsMouse ? Theme.surfaceHigh : "transparent"
                Behavior on radius { SpringAnim {} }
                Row {
                    anchors.centerIn: parent; spacing: 8
                    MIcon { text: tab.modelData.i; fill: tab.on; size: 20; color: tab.on ? Theme.fgSecondaryContainer : Theme.fgSurface }
                    Label { text: tab.modelData.n; size: 14; color: tab.on ? Theme.fgSecondaryContainer : Theme.fgSurface; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: Ui.dashTab = tab.modelData.k }
            }
        }
    }

    Item {
        id: pages
        y: tabs.height + 14
        width: parent.width
        height: parent.height - y

        // ---- the overview ----
        Grid {
            visible: Ui.dashTab === "ov"
            anchors.fill: parent
            columns: 2
            spacing: 12
            readonly property real cw: (width - 12) / 2
            Card {
                width: parent.cw * .7 - 6; height: 120
                Row {
                    anchors.fill: parent; anchors.margins: 18; spacing: 16
                    MShape { width: 72; height: 72; shape: Theme.shCookie9; color: Theme.tertiaryContainer; anchors.verticalCenter: parent.verticalCenter
                        Label { anchors.centerIn: parent; text: (Quickshell.env("USER") || "?")[0].toUpperCase(); size: 30; w: Font.Bold; color: Theme.fgTertiaryContainer } }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 4
                        Label { text: Quickshell.env("USER") || "user"; size: 20; w: Font.Bold }
                        Label { text: "WynlandOS"; size: 13; dim: true }
                        Rectangle {
                            width: upRow.implicitWidth + 20; height: 26; radius: 13; color: Theme.surfaceHighest
                            Row { id: upRow; anchors.centerIn: parent; spacing: 6
                                MIcon { text: "schedule"; size: 15 }
                                Label { text: "работает " + root.uptime; size: 12 } }
                        }
                    }
                }
            }
            Rectangle {
                width: parent.cw * 1.3 - 6; height: 120
                radius: Theme.rm
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.primaryContainer }
                    GradientStop { position: 1; color: Theme.mix(Theme.tertiaryContainer, Theme.surfaceHigh, .3) }
                }
                Row {
                    anchors.fill: parent; anchors.margins: 18; spacing: 16
                    MShape { width: 72; height: 72; shape: Theme.shSunny; color: Weather.ok ? Theme.oklch(85, .14, 85) : Theme.surfaceHighest; anchors.verticalCenter: parent.verticalCenter
                        RotationAnimation on rotation { from: 0; to: 360; duration: 30000; loops: Animation.Infinite; running: root.shown && !Theme.still }
                        MIcon { anchors.centerIn: parent; visible: !Weather.ok; text: "cloud_off"; size: 30 } }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Label { text: Weather.ok ? Weather.sign(Weather.temp) : "нет данных"; size: Weather.ok ? 44 : 22; w: Font.Light; color: Theme.fgPrimaryContainer }
                        Label { text: Weather.ok ? Weather.desc + " · ощущается как " + Weather.sign(Weather.feels) : "погода появится, когда будет сеть"; size: 13; color: Theme.fgPrimaryContainer; opacity: .85 }
                    }
                    Row {
                        visible: Weather.ok
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: Weather.days
                            Rectangle {
                                id: day
                                required property var modelData
                                width: 52; height: 80; radius: 26; color: Qt.rgba(1, 1, 1, .12)
                                Column { anchors.centerIn: parent; spacing: 4
                                    Label { text: day.modelData.d; size: 12; color: Theme.fgPrimaryContainer; anchors.horizontalCenter: parent.horizontalCenter }
                                    MIcon { text: day.modelData.icon; fill: true; size: 22; color: Theme.fgPrimaryContainer; anchors.horizontalCenter: parent.horizontalCenter }
                                    Label { text: Weather.sign(day.modelData.t); size: 12; color: Theme.fgPrimaryContainer; anchors.horizontalCenter: parent.horizontalCenter } }
                            }
                        }
                    }
                }
            }
            Card {
                width: parent.cw * .7 - 6; height: pages.height - 132
                Calendar { anchors.fill: parent; anchors.margins: 18 }
            }
            Card {
                width: parent.cw * 1.3 - 6; height: pages.height - 132
                MediaCard { anchors.fill: parent; anchors.margins: 22; art: 140 }
            }
        }

        // ---- the media ----
        Card {
            visible: Ui.dashTab === "md"
            anchors.fill: parent
            MediaCard { anchors.fill: parent; anchors.margins: 32; art: 260; big: true }
        }

        // ---- the system ----
        Grid {
            visible: Ui.dashTab === "pf"
            anchors.fill: parent
            columns: 4
            spacing: 12
            readonly property real cw: (width - 36) / 4
            Gauge { name: "Процессор"; sub: Sys.cores + " ядер"; v: Sys.cpu }
            Gauge { name: "Память"; sub: Sys.ramUsedGb.toFixed(1) + " из " + Sys.ramTotalGb.toFixed(0) + " ГБ"; v: Sys.ram }
            Gauge { name: "Диск"; sub: Sys.diskText || "—"; v: Sys.disk }
            Gauge { name: "Температура"; sub: Sys.temp >= 0 ? "" : "датчика нет"; v: Sys.temp >= 0 ? Sys.temp / 100 : 0; label: Sys.temp >= 0 ? Math.round(Sys.temp) + "°" : "нет" }
            Card {
                width: parent.width; height: pages.height - 262
                Label { x: 18; y: 14; text: "Процессор, последние 3 минуты"; size: 15; w: Font.Bold }
                Canvas {
                    id: graph
                    x: 18; y: 44; width: parent.width - 36; height: parent.height - 58
                    property var h: Sys.history
                    property color c: Theme.primary
                    onHChanged: requestPaint()
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

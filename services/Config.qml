pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The settings, as the prototype's cfg: kept in ~/.config/xvlet/config.json,
// read at start, written a moment after each change. Config.data is the
// whole tree (bind to it: every change makes a new object); set("bar.pos",
// "left") changes one leaf.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/xvlet"
    readonly property var defaults: ({
        theme: { mode: "dark", src: "wall", seed: 0, custom: 285, scheme: "tonal", saved: [], active: -1,
                 radius: 1, motion: "spring", font: "Roboto Flex", shellCorners: true, screenCorners: false },
        wall: { path: Qt.resolvedUrl("../assets/walls/01-dusk.png").toString().replace("file://", ""), trans: "circle" },
        bar: { pos: "top", style: "islands", height: 52, ws: "pill", clock: "date",
               mods: { logo: "start", ws: "start", tasks: "off", media: "center", tray: "end", sysmon: "off",
                       weather: "end", status: "end", bell: "end", clock: "end", power: "end" } },
        dock: { on: true, style: "attached", pos: "bottom", size: 52, zoom: 1.15, labels: false, inds: true, autohide: "off",
                apps: ["wynland-terminal", "wynland-files", "wynland-web", "foot"] },
        launcher: { pos: "bottom", view: "grid", cats: true },
        desk: { grid: true, note: "", widgets: [
            { t: "clock", v: "lumen", x: 1608, y: 96, w: 264, h: 264 }, { t: "weather", v: "full", x: 1536, y: 384, w: 336, h: 216 },
            { t: "music", v: "vinyl", x: 72, y: 96, w: 312, h: 312 }, { t: "cpu", v: "wave", x: 1392, y: 744, w: 144, h: 144 },
            { t: "ram", v: "wave", x: 1560, y: 744, w: 144, h: 144 }, { t: "temp", v: "wave", x: 1728, y: 744, w: 144, h: 144 },
            { t: "clock", v: "digital", x: 72, y: 600, w: 288, h: 312 }] },
        notif: { pos: "tr", dnd: false, secs: 6 }
    })
    property var data: clone(defaults)
    property bool loaded: false

    function clone(o) { return JSON.parse(JSON.stringify(o)); }
    function merge(d, s) {
        const out = clone(d);
        if (!s || typeof s !== "object") return out;
        for (const k in s) {
            if (out[k] && typeof out[k] === "object" && !Array.isArray(out[k]) && s[k] && typeof s[k] === "object" && !Array.isArray(s[k]))
                out[k] = merge(out[k], s[k]);
            else out[k] = s[k];
        }
        return out;
    }
    function get(path) { return path.split(".").reduce((o, k) => o === undefined ? undefined : o[k], data); }
    function set(path, v) {
        const d = clone(data), ks = path.split(".");
        let o = d;
        while (ks.length > 1) { const k = ks.shift(); if (typeof o[k] !== "object" || o[k] === null) o[k] = {}; o = o[k]; }
        o[ks[0]] = v;
        data = d;
        saveLater.restart();
    }
    function reset(path) { set(path, clone(path.split(".").reduce((o, k) => o[k], defaults))); }

    Timer { id: saveLater; interval: 400; onTriggered: file.setText(JSON.stringify(root.data, null, 2)) }

    Process { id: mkdir; running: true; command: ["mkdir", "-p", root.dir]; onExited: file.reload() }
    FileView {
        id: file
        path: root.dir + "/config.json"
        blockLoading: false
        onLoaded: { try { root.data = root.merge(root.defaults, JSON.parse(text())); } catch (e) {} root.loaded = true; }
        onLoadFailed: { root.loaded = true; saveLater.restart(); }
    }
}

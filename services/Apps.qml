pragma Singleton

import QtQuick
import Quickshell
import qs.services
import Quickshell.Hyprland

// The applications (desktop entries) and the windows open now (Zerp's
// answers as Hyprland's): what the launcher, the dock and the bar's task
// list show.
Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values.filter(a => !a.noDisplay)
        .slice().sort((a, b) => a.name.localeCompare(b.name))
    readonly property var cats: [
        { k: "", n: "Все", i: "apps" }, { k: "fav", n: "Избранное", i: "star" },
        { k: "Network", n: "Интернет", i: "public" }, { k: "AudioVideo", n: "Мультимедиа", i: "play_circle" },
        { k: "Development", n: "Разработка", i: "code" }, { k: "Utility", n: "Утилиты", i: "construction" },
        { k: "System", n: "Система", i: "memory" }
    ]
    readonly property var windows: Hyprland.toplevels.values
    function byId(id) { return all.find(a => a.id === id) || DesktopEntries.byId(id) || null; }
    function classOf(w) { return w && w.lastIpcObject ? (w.lastIpcObject.class || "") : ""; }
    // the entry a window belongs to: its class against the entries' ids,
    // names and programs
    function entryOf(w) {
        const c = classOf(w).toLowerCase();
        if (!c) return null;
        return all.find(a => a.id.toLowerCase() === c || a.id.toLowerCase().endsWith(c) || (a.startupClass || "").toLowerCase() === c
                       || a.name.toLowerCase() === c || (a.command && a.command[0] && a.command[0].toLowerCase().endsWith(c))) || null;
    }
    function running(a) { return windows.some(w => { const e = entryOf(w); return e && e.id === a.id; }); }
    function search(q, cat) {
        q = (q || "").toLowerCase().trim();
        const fav = Config.data.dock.apps;
        return all.filter(a => {
            if (cat === "fav" && !fav.includes(a.id)) return false;
            if (cat && cat !== "fav" && !(a.categories || []).includes(cat)) return false;
            if (!q) return true;
            return a.name.toLowerCase().includes(q) || (a.genericName || "").toLowerCase().includes(q)
                || (a.keywords || []).some(k => k.toLowerCase().includes(q)) || a.id.toLowerCase().includes(q);
        });
    }
    function launch(a) {
        if (!a) return;
        const w = windows.find(x => { const e = entryOf(x); return e && e.id === a.id; });
        if (w && w.address) Hyprland.dispatch("focuswindow address:0x" + w.address);
        else a.execute();
    }
    function icon(a) { return a && a.icon ? Quickshell.iconPath(a.icon, true) : ""; }
    // a colour for an app that has no icon: its name's hue
    // the first of the launcher's categories an app is in
    function catName(a) { const c = cats.find(c => c.k && c.k !== "fav" && (a.categories || []).includes(c.k)); return c ? c.n : ""; }
    function hue(a) { let h = 0; for (const ch of (a ? a.name : "?")) h = (h * 31 + ch.charCodeAt(0)) % 360; return h; }
}

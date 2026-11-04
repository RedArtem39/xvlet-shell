pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// The wallpapers: the shell's own (assets/walls), the system's
// (/usr/share/wynland/wallpapers) and the
// user's own (~/Pictures/Wallpapers); pictures only. Listed at start and
// each time the picker opens.
Singleton {
    id: root

    property var list: []
    Process {
        id: ls
        running: true
        command: ["sh", "-c", "for d in \"$0\" /usr/share/wynland/wallpapers \"$HOME/Pictures/Wallpapers\"; do ls -1 \"$d\" 2>/dev/null | grep -iE '\\.(png|jpe?g|webp)$' | sed \"s|^|$d/|\"; done", Qt.resolvedUrl("../assets/walls").toString().replace("file://", "")]
        // (the same picture in two places -- a link to the system's folder
        // in ~/Pictures/Wallpapers -- once: by its file name)
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                root.list = text.split("\n").filter(l => {
                    const f = l.trim().split("/").pop();
                    if (!f || seen[f]) return false;
                    seen[f] = true;
                    return true;
                });
            }
        }
    }
    function refresh() { ls.running = true; }
    // the shell's own default where the system left them out (an image
    // with only its owner's pictures): the first wallpaper there is
    function fallback() {
        const p = Config.data.wall.path || "";
        if (Config.loaded && list.length && list.indexOf(p) < 0 && p.indexOf("/assets/walls/") >= 0) set(list[0]);
    }
    onListChanged: fallback()
    Connections { target: Config; function onLoadedChanged() { root.fallback(); } }
    function set(path) { Config.set("wall.path", path); }
    // the shell's own have names (the prototype's), the rest their file's
    readonly property var names: ({ dusk: "Сумерки", mint: "Мята", amber: "Янтарь", ocean: "Океан", sakura: "Сакура", forest: "Лес",
                                    night: "Ночь", mountains: "Горы", desert: "Пустыня", waves: "Волны", lava: "Лава", lavender: "Лаванда" })
    // their hues (the prototype's WALLS[].h), for the picker's colours
    readonly property var hues: ({ dusk: 285, mint: 165, amber: 55, ocean: 235, sakura: 350, forest: 135, night: 265, mountains: 220, desert: 40, waves: 200, lava: 25, lavender: 300 })
    // any other's hue: its own pixels' (a small quantizer each, once), the
    // hue weighted by chroma most of it has; -1 while not known yet
    property var seen: ({})
    Instantiator {
        model: root.list.filter(p => { const k = p.split("/").pop().replace(/\.[^.]+$/, "").replace(/^\d+-/, ""); return root.hues[k] === undefined; })
        ColorQuantizer {
            required property string modelData
            source: "file://" + modelData
            depth: 3
            rescaleSize: 48
            onColorsChanged: {
                const bins = new Array(36).fill(0), hs = new Array(36).fill(0);
                for (const c of colors) {
                    const o = Theme.toOklch(c.r, c.g, c.b);
                    if (o[1] < .03 || o[0] < .15) continue;
                    const w = Math.pow(o[1], 1.5), k = Math.floor(o[2] / 10) % 36;
                    bins[k] += w; hs[k] += o[2] * w;
                }
                let best = -1;
                for (let k = 0; k < 36; k++) if (bins[k] > 0 && (best < 0 || bins[k] > bins[best])) best = k;
                const m = Object.assign({}, root.seen);
                m[modelData] = best < 0 ? -1 : Math.round(hs[best] / bins[best]);
                root.seen = m;
            }
        }
    }
    function hueOf(path) {
        const k = (path || "").split("/").pop().replace(/\.[^.]+$/, "").replace(/^\d+-/, "");
        return hues[k] !== undefined ? hues[k] : seen[path] !== undefined ? seen[path] : -1;
    }
    function nameOf(path) {
        const f = (path || "").split("/").pop().replace(/\.[^.]+$/, ""), k = f.replace(/^\d+-/, "");
        return names[k] || f;
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How this account looks on the login screen (wynlogin's xvlet skin): the
// scene, the clock's style and place, the date. Each account its own:
// /var/lib/wynlogin/looks/<name>.json (a sticky, world-writable folder --
// Zerp takes a file there only when its owner is that account), which the
// login screen shows while this account is the one chosen.
Singleton {
    id: root

    readonly property string user: Quickshell.env("USER") || ""
    readonly property var defaults: ({ scene: "sakura-katana", clock: "big", clockPos: "left", date: true })
    property var data: defaults
    readonly property string sceneDir: Qt.resolvedUrl("../wynlogin/scenes/").toString().replace("file://", "")

    function set(k, v) {
        const d = Object.assign({}, data);
        d[k] = v;
        data = d;
        saveLater.restart();
    }
    Timer { id: saveLater; interval: 300; onTriggered: file.setText(JSON.stringify(root.data, null, 2) + "\n") }

    FileView {
        id: file
        path: root.user ? "/var/lib/wynlogin/looks/" + root.user + ".json" : ""
        blockLoading: false
        onLoaded: { try { root.data = Object.assign({}, root.defaults, JSON.parse(text())); } catch (e) {} }
    }

    // the scenes there are: [{ id, title, hue }] (each one's meta.json)
    property var scenes: []
    Process {
        running: true
        command: ["sh", "-c", "for m in \"$0\"/*/meta.json; do cat \"$m\"; echo; done", root.sceneDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const l of text.split("\n")) { try { if (l.trim()) out.push(JSON.parse(l)); } catch (e) {} }
                out.sort((a, b) => a.id === "sakura-katana" ? -1 : b.id === "sakura-katana" ? 1 : a.title.localeCompare(b.title));
                root.scenes = out;
            }
        }
    }
    function sceneUrl(id) { return "file://" + sceneDir + id + "/"; }
}

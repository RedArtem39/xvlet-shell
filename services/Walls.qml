pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// The wallpapers: the system's (/usr/share/wynland/wallpapers) and the
// user's own (~/Pictures/Wallpapers); pictures only. Listed at start and
// each time the picker opens.
Singleton {
    id: root

    property var list: []
    Process {
        id: ls
        running: true
        command: ["sh", "-c", "for d in /usr/share/wynland/wallpapers \"$HOME/Pictures/Wallpapers\"; do ls -1 \"$d\" 2>/dev/null | grep -iE '\\.(png|jpe?g|webp)$' | sed \"s|^|$d/|\"; done"]
        stdout: StdioCollector { onStreamFinished: root.list = text.split("\n").filter(l => l.trim() !== "") }
    }
    function refresh() { ls.running = true; }
    function set(path) { Config.set("wall.path", path); }
}

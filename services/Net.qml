pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// The network, as far as the shell can tell: is there a way out (a default
// route -- the wire, a phone's USB tethering), and Wi-Fi and Bluetooth --
// which WynlandOS has no stack for yet: "нет", never pretended.
Singleton {
    id: root

    property bool online: false
    property string via: ""            // the interface of the default route
    readonly property bool wifi: false
    readonly property bool bluetooth: false
    readonly property string icon: online ? (via.startsWith("usb") || via.startsWith("rndis") ? "phone_android" : "lan") : "signal_disconnected"

    Cat {
        id: route
        path: "/proc/net/route"
        onLoaded: t => {
            let up = false, dev = "";
            for (const l of t.split("\n").slice(1)) {
                const f = l.trim().split(/\s+/);
                if (f.length > 2 && f[1] === "00000000") { up = true; dev = f[0]; break; }
            }
            root.online = up; root.via = dev;
        }
        onFailed: probe.running = true
    }
    // no /proc/net/route: ask ip(8)
    Process {
        id: probe
        command: ["sh", "-c", "ip route 2>/dev/null | awk '/^default/ {print $5; exit}'"]
        stdout: StdioCollector { onStreamFinished: { root.via = text.trim(); root.online = root.via !== ""; } }
    }
    Timer { interval: 8000; running: true; repeat: true; triggeredOnStart: true; onTriggered: route.reload() }
}

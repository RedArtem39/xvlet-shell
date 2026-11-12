pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wi-Fi through wifid (WynlandOS's: the `wifi` command, `wifi raw REQUEST`
// answers in tab-separated lines). The link's state every few seconds; the
// networks around when someone looks (quick settings' list). A password
// goes on the command's stdin, never in its arguments.
Singleton {
    id: root

    property bool present: false          // wifid answers
    property string state: "idle"         // idle, scanning, connecting, connected
    property string ssid: ""
    property int signal: 0
    property int channel: 0
    property string reason: ""
    property bool auto: true
    property var networks: []             // { ssid, signal, channel, sec, known (0 / 1 / 2 refused), active }
    property bool watching: false         // the list is on screen: scan now and then
    property string pending: ""           // the network being joined from here
    property string lastTried: ""         // the last one joined with a typed password (refused: the page asks again)
    property bool scanning: false

    readonly property bool connected: state === "connected"
    readonly property bool busy: scanning || state === "connecting"
    function bars(s) { return s >= -55 ? 4 : s >= -67 ? 3 : s >= -75 ? 2 : 1 }
    readonly property string icon: !present ? "wifi_off" : connected ? ["", "network_wifi_1_bar", "network_wifi_2_bar", "network_wifi_3_bar", "signal_wifi_4_bar"][bars(signal)] : busy ? "wifi_find" : "wifi_off"

    function parse(text) {
        const o = {};
        for (const l of text.split("\n")) { const t = l.indexOf("\t"); if (t > 0) o[l.slice(0, t)] = l.slice(t + 1); }
        return o;
    }

    Process {
        id: st
        command: ["wifi", "raw", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = root.parse(text);
                root.present = o.state !== undefined;
                if (!root.present) return;
                root.state = o.state;
                root.ssid = o.ssid || "";
                root.signal = parseInt(o.signal || "0");
                root.channel = parseInt(o.channel || "0");
                root.reason = o.reason || "";
                root.auto = o.auto === "1";
                root.scanning = o.scanning === "1";
                if (root.pending && (root.connected || root.state === "idle")) root.pending = "";
            }
        }
        onExited: code => { if (code !== 0) root.present = false; }
    }
    Process {
        id: ls
        command: ["wifi", "raw", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const l of text.split("\n")) {
                    const f = l.split("\t");
                    if (f.length >= 7 && f[0] === "net")
                        out.push({ ssid: f[1], signal: parseInt(f[2]), channel: parseInt(f[3]), sec: f[4], known: parseInt(f[5]), active: f[6] === "1" });
                }
                root.networks = out;
            }
        }
    }
    // one request at a time on stdin ("connect NAME<TAB>PASSWORD" and the like)
    Process {
        id: req
        property string line: ""
        command: ["wifi", "raw", "-"]
        stdinEnabled: true
        onStarted: { write(line + "\n"); line = ""; stdinEnabled = false; }
        onExited: { stdinEnabled = true; poll.restart(); root.refresh(); }
    }
    function send(l) { if (req.running) return; req.line = l; req.running = true; }

    function refresh() { if (!st.running) st.running = true; if (watching && !ls.running) ls.running = true; }
    function scan() { send("scan"); }
    function enable() { send("enable"); }
    function connect(name, password) { pending = name; if (password) lastTried = name; send("connect " + name + (password ? "\t" + password : "")); }
    function forget(name) { send("forget " + name); }
    function disconnect() { send("disconnect"); }

    onWatchingChanged: if (watching) { scan(); refresh(); }
    Timer { id: poll; interval: root.busy || root.pending ? 1000 : 4000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { interval: 20000; running: root.watching; repeat: true; onTriggered: root.scan() }
}

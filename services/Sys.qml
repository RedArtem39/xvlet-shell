pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// The machine's load: the processor (/proc/stat), memory (/proc/meminfo),
// the root disk (df), the temperature (the first thermal zone; none: -1).
// Read every 2 s; `history` keeps the CPU's last 90 samples for the graph.
Singleton {
    id: root

    property real cpu: 0
    property real ram: 0
    property real ramUsedGb: 0
    property real ramTotalGb: 0
    property real disk: 0
    property string diskText: ""
    property real temp: -1
    property int cores: 0
    property var history: []
    property var _prev: null

    Cat {
        id: stat
        path: "/proc/stat"
        onLoaded: t => {
            const lines = t.split("\n"), f = lines[0].trim().split(/\s+/).slice(1).map(Number);
            root.cores = lines.filter(l => /^cpu\d/.test(l)).length;
            const idle = f[3] + (f[4] || 0), total = f.reduce((a, b) => a + b, 0);
            if (root._prev) {
                const dt = total - root._prev.t, di = idle - root._prev.i;
                if (dt > 0) root.cpu = Math.max(0, Math.min(1, 1 - di / dt));
            }
            root._prev = { t: total, i: idle };
            root.history = root.history.concat([root.cpu]).slice(-90);
        }
    }
    Cat {
        id: mem
        path: "/proc/meminfo"
        onLoaded: t => {
            const v = k => { const m = t.match(new RegExp("^" + k + ":\\s+(\\d+)", "m")); return m ? +m[1] : 0; };
            const total = v("MemTotal"), avail = v("MemAvailable") || (v("MemFree") + v("Cached"));
            root.ramTotalGb = total / 1048576; root.ramUsedGb = (total - avail) / 1048576;
            root.ram = total ? (total - avail) / total : 0;
        }
    }
    Cat { id: therm; path: "/sys/class/thermal/thermal_zone0/temp"; onLoaded: t => root.temp = (parseInt(t) || 0) / 1000; onFailed: root.temp = -1 }
    Process {
        id: df
        command: ["df", "-P", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = (text.trim().split("\n")[1] || "").split(/\s+/);
                if (f.length > 4) { root.disk = (+f[2]) / Math.max(1, +f[1]); root.diskText = (f[2] / 1048576).toFixed(0) + " из " + (f[1] / 1048576).toFixed(0) + " ГБ"; }
            }
        }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { stat.reload(); mem.reload(); therm.reload(); }
    }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: df.running = true }
}

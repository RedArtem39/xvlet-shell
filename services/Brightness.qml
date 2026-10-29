pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// The panel's backlight: /sys/class/backlight/intel_backlight (WynlandOS's
// i915 driver; Linux's sysfs). No such file: no backlight -- "нет".
Singleton {
    id: root

    readonly property string base: "/sys/class/backlight/intel_backlight/"
    property int max: 0
    property int cur: 0
    readonly property bool present: max > 0
    readonly property real value: present ? cur / max : 0
    signal changed

    Cat { id: fmax; running: true; path: root.base + "max_brightness"; onLoaded: t => { root.max = parseInt(t) || 0; fcur.reload(); } onFailed: root.max = 0 }
    Cat { id: fcur; path: root.base + "brightness"; onLoaded: t => root.cur = parseInt(t) || 0 }
    Process { id: write }

    function set(v) {
        if (!present) return;
        cur = Math.max(Math.round(max / 100), Math.min(max, Math.round(v * max)));
        write.command = ["sh", "-c", "echo " + cur + " > " + base + "brightness"];
        write.running = true;
        changed();
    }
    function step(d) { set(value + d); }
}

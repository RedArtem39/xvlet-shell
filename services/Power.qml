pragma Singleton

import QtQuick
import Quickshell
import qs.services
import Quickshell.Io
import Quickshell.Hyprland

// The battery (sysfs: BAT0's capacity and status) and the session's power
// actions. No battery: present is false and the bar shows nothing for it.
Singleton {
    id: root

    property int capacity: -1
    property string status: ""
    readonly property bool present: capacity >= 0
    readonly property bool charging: status === "Charging" || status === "Full"
    readonly property string icon: !present ? "battery_unknown" : charging ? "battery_charging_full"
        : capacity > 90 ? "battery_full" : "battery_" + Math.max(0, Math.min(6, Math.round(capacity / 100 * 6))) + "_bar"
    // what this system can do: no suspend in WynlandOS yet
    readonly property bool canSleep: false

    Cat { id: cap; path: "/sys/class/power_supply/BAT0/capacity"; onLoaded: t => root.capacity = parseInt(t); onFailed: root.capacity = -1 }
    Cat { id: st; path: "/sys/class/power_supply/BAT0/status"; onLoaded: t => root.status = t.trim() }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { cap.reload(); st.reload(); } }

    Process { id: run }
    // lock, logout (Zerp's "exit"), reboot and poweroff (power(1), a
    // person's own at the machine)
    function act(what) {
        if (what === "lock") { Ui.lock(); return; }
        if (what === "logout") { Hyprland.dispatch("exit"); return; }
        if (what === "reboot") run.command = ["reboot"];
        else if (what === "off") run.command = ["poweroff"];
        else return;
        run.running = true;
    }
}

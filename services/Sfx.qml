pragma Singleton

import QtQuick
import Quickshell
import qs.services

// The shell's sounds (Serpantinum's, assets/sounds: see its CREDITS): the
// interface's -- clicks, switches, the slider's ticks, typing -- and the
// events' -- a notification, the network up or down. Settings: Звук.
//   Sfx.ui("click")    a control was used (if interface sounds are on)
//   Sfx.event("connect")
//   Sfx.notify()       the chosen notification sound (not in Do not disturb,
//                      unless urgent); Sfx.preview("Sine") one to listen to
Singleton {
    id: root

    readonly property var cfg: Config.data.sound || {}
    readonly property bool uiOn: cfg.ui !== false
    readonly property bool eventsOn: cfg.events !== false
    readonly property real volume: (cfg.volume === undefined ? 70 : cfg.volume) / 100
    readonly property string dir: Qt.resolvedUrl("../assets/sounds/").toString()

    // key -> [file, its own loudness] (as Serpantinum plays them)
    readonly property var sounds: ({
        click:      ["reusables/clickbutton/click.wav", 1],
        icon:       ["reusables/iconbutton/click.wav", 1],
        quick:      ["system/quick_click.wav", 1],
        toggle:     ["reusables/toggle/sfx.wav", 1],
        "switch":   ["reusables/switch/sfx.wav", 1],
        tick:       ["reusables/draggable/tick.wav", .6],
        type:       ["reusables/input/type.wav", 1],
        list:       ["reusables/dropdown/list.wav", 1],
        press:      ["reusables/fillbutton/button.wav", 1],
        swoosh:     ["musicpopup/swoosh.wav", .75],
        dragIn:     ["guide/barconfig/in.wav", 1],
        dragOut:    ["guide/barconfig/out.wav", 1],
        connect:    ["network/connect.wav", 1],
        disconnect: ["network/disconnect.wav", 1],
        powerOn:    ["network/power_on.wav", 1],
        powerOff:   ["network/power_off.wav", 1]
    })
    readonly property var notifSounds: ["Progress", "Botanica", "Curious", "Sine", "Sneak", "WakeUp", "Wobbly"]

    // Qt Multimedia when there is one; without it only the events sound
    // (pw-play, a program each: too slow for clicks)
    property var player: null
    Component.onCompleted: {
        const c = Qt.createComponent("SfxPlayer.qml");
        if (c.status === Component.Ready) {
            player = c.createObject(root, { dir: dir });
            for (const k of ["click", "icon", "quick", "toggle", "switch", "tick", "type"]) player.load(k, sounds[k][0]);
        } else console.warn("xvlet: no Qt Multimedia, only event sounds (pw-play):", c.errorString());
    }

    function play(key, file, loud, event) {
        const v = volume * loud;
        if (v <= 0) return;
        if (player) player.play(key, file, v);
        else if (event) Quickshell.execDetached(["pw-play", "--volume=" + v.toFixed(2), dir.replace("file://", "") + file]);
    }
    property real lastTick: 0
    function ui(key) {
        if (!uiOn || !sounds[key]) return;
        // the ticks of a dragged slider: at most one in 50 ms
        if (key === "tick" || key === "type") { const now = Date.now(); if (now - lastTick < 50) return; lastTick = now; }
        play(key, sounds[key][0], sounds[key][1], false);
    }
    function event(key) { if (eventsOn && sounds[key]) play(key, sounds[key][0], sounds[key][1], true); }
    function notify(urgent) {
        const n = cfg.notif || "Progress";
        if (!eventsOn || n === "off" || (Notifs.dnd && !urgent)) return;
        play("n:" + n, "notifications/" + n + ".wav", 1, true);
    }
    function preview(n) { if (n !== "off") play("n:" + n, "notifications/" + n + ".wav", 1, true); }

    // the network coming and going (not its first answer at start)
    readonly property real born: Date.now()
    Connections {
        target: Net
        function onOnlineChanged() { if (Date.now() - root.born > 8000) root.event(Net.online ? "connect" : "disconnect"); }
    }
}

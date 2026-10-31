//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded

// xvlet: a Material 3 Expressive desktop shell. On each screen: the
// wallpaper, the desktop's widgets, the frame, the bar, the dock, the
// overlay (popouts, launcher, settings, wallpapers), the notices (toasts,
// OSD) and the lock screen. Keys (Zerp's, as Hyprland's global shortcuts)
// and `quickshell ipc call xvlet ...` open its parts.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import "modules/background"
import "modules/desk"
import "modules/frame"
import "modules/bar"
import "modules/dock"
import "modules/overlay"
import "modules/notices"
import "modules/lock"

ShellRoot {
    // no watching of its own files for a live reload: where the system has
    // no inotify (WynlandOS) Qt polls every file, over and over
    settings.watchFiles: false

    FontLoader { source: Qt.resolvedUrl("assets/fonts/RobotoFlex.ttf") }
    FontLoader { source: Qt.resolvedUrl("assets/fonts/MaterialSymbolsRounded.ttf") }

    // what Zerp has to say (its events on Hyprland's socket): the canvas
    // on or off, a place marked -- the compositor shows nothing itself
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            const d = ev.data;
            if (ev.name === "canvas")
                Notifs.toast(d === "1" ? "view_quilt" : "grid_view", d === "1" ? "Бесконечный холст" : "Тайлинг",
                             d === "1" ? "Alt+G — обратно · Alt+мышь — окна · Ctrl+колёсико — масштаб" : "Alt+G — холст");
            else if (ev.name === "canvashome")
                Notifs.toast("home", d === "home" ? "Начало холста" : "Обратно", "Alt+A");
            else if (ev.name === "canvasmark") {
                const [what, n] = d.split(",");
                Notifs.toast("bookmark", what === "set" ? "Место " + n + " запомнено" : what === "go" ? "Место " + n : "Место " + n + " пусто",
                             what === "set" ? "Ctrl+Alt+" + n + " — сюда" : what === "empty" ? "Ctrl+Alt+Shift+" + n + " — запомнить" : "");
            }
        }
    }

    // the lock screen: one session lock for every screen
    Lock {}

    // made at start: the sounds (they load ahead, and hear the network),
    // the wallpapers (a missing default is replaced at once)
    Component.onCompleted: { Sfx.volume; Walls.list; }

    // the canvas's settings, to Zerp once the shell's own are read
    Connections {
        target: Config
        function onLoadedChanged() {
            if (!Config.loaded) return;
            const c = Config.data.canvas || {};
            for (const k in c) Hyprland.dispatch("canvas opt " + k + " " + c[k]);
        }
    }

    Variants {
        model: Quickshell.screens
        Scope {
            id: s
            required property var modelData
            Wallpaper { screen: s.modelData }
            Desktop { screen: s.modelData }
            Frame { screen: s.modelData }
            Bar { screen: s.modelData }
            Dock { screen: s.modelData }
            Overlay { screen: s.modelData }
            Notices { screen: s.modelData }
        }
    }

    // Zerp's keys (apps/zerp2/keybinds.conf) are bound to Caelestia's
    // names; one shell runs at a time, so xvlet answers to them: Super
    // alone the launcher, Ctrl+Alt+Del the session menu, Super+N quick
    // settings, Super+K the dashboard, Super+L the lock
    GlobalShortcut { appid: "caelestia"; name: "launcher"; onReleased: Ui.openLauncher() }
    GlobalShortcut { appid: "caelestia"; name: "session"; onPressed: Ui.toggle("session") }
    GlobalShortcut { appid: "caelestia"; name: "sidebar"; onPressed: Ui.toggle("qs", 1800) }
    GlobalShortcut { appid: "caelestia"; name: "showall"; onPressed: Ui.toggle("dash", 960) }
    GlobalShortcut { appid: "caelestia"; name: "lock"; onPressed: Ui.lock() }
    GlobalShortcut { appid: "caelestia"; name: "clearNotifs"; onPressed: Notifs.clear() }

    // quickshell ipc -p /usr/share/xvlet call xvlet <function> [args]
    IpcHandler {
        target: "xvlet"
        function launcher(): void { Ui.openLauncher(); }
        function settings(page: string): void { Ui.openSettings(page || "look"); }
        function dash(tab: string): void { Ui.closeAll(); Ui.dashTab = tab || "ov"; Ui.toggle("dash", 1700); }
        function qs(): void { Ui.closeAll(); Ui.toggle("qs", 1800); }
        function session(): void { Ui.toggle("session"); }
        function wallpapers(): void { Ui.closeAll(); Ui.wallpick = true; }
        function lock(): void { Ui.lock(); }
        function ws(n: int): void { Hyprland.dispatch("workspace " + n); }
        function edit(): void { Ui.editing = !Ui.editing; }
        function close(): void { Ui.closeAll(); Ui.settings = false; }
        function set(path: string, value: string): void { let v = value; try { v = JSON.parse(value); } catch (e) {} Config.set(path, v); }
        function notify(summary: string, body: string): void { Notifs.test(summary, body); }
    }
}

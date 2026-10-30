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
    FontLoader { source: Qt.resolvedUrl("assets/fonts/RobotoFlex.ttf") }
    FontLoader { source: Qt.resolvedUrl("assets/fonts/MaterialSymbolsRounded.ttf") }

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
            Lock { screen: s.modelData }
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

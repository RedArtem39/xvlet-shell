pragma Singleton

import QtQuick
import Quickshell
import qs.services

// What is open: one popout at a time (the dashboard, quick settings, the
// session menu), the launcher, the settings, the wallpaper picker, the
// lock, the widget editor. The overlay windows follow it.
Singleton {
    id: root

    property string pop: ""          // "dash", "qs", "session", "" -- the bar's popouts
    property string dashTab: "ov"
    property real popX: 0            // where the bar's button is (the popout comes from there)
    property bool launcher: false
    property bool settings: false
    property string settingsPage: "styles"
    property bool wallpick: false
    property bool locked: false
    property bool editing: false
    property string osd: ""          // "volume", "brightness"
    readonly property bool anyOpen: pop !== "" || launcher || settings || wallpick

    function toggle(p, x) { if (pop === p) pop = ""; else { pop = p; if (x !== undefined) popX = x; launcher = false; } }
    function closeAll() { pop = ""; launcher = false; wallpick = false; }
    function openLauncher() { pop = ""; launcher = !launcher; }
    function openSettings(page) { closeAll(); if (page) settingsPage = page; settings = true; }
    function lock() { closeAll(); settings = false; locked = true; }
    function showOsd(k) { osd = k; osdHide.restart(); }
    Timer { id: osdHide; interval: 1600; onTriggered: root.osd = "" }

    Connections { target: Audio; function onChanged() { root.showOsd("volume"); } }
    Connections { target: Brightness; function onChanged() { root.showOsd("brightness"); } }
}

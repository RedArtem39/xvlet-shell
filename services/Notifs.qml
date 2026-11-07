pragma Singleton

import QtQuick
import Quickshell
import qs.services
import Quickshell.Services.Notifications

// The notification server: every notification is kept for the centre
// (quick settings) and shown as a toast for a few seconds -- not in "Do not
// disturb". `badge`: something new since the centre was last opened.
Singleton {
    id: root

    // the centre's: the apps' (D-Bus) and the shell's own that are kept
    // (a test, "copied"); the canvas's notices are toasts only
    readonly property var list: own.concat(server.trackedNotifications.values)
    property var own: []
    // the toasts on screen: { n, t0, until } -- each its own deadline, kept
    // here: the cards are made again whenever one comes, and their own
    // timers started over (Zerp's tiling notices, coming often, kept every
    // toast up for good), and a hover pause held for ever when the
    // compositor never said the pointer left
    property var toasts: []
    readonly property int life: Math.max(2, Config.data.notif.secs) * 1000
    Timer {
        interval: 250; repeat: true
        running: root.toasts.length > 0
        onTriggered: { const t = Date.now(); if (root.toasts.some(x => x.until <= t)) root.toasts = root.toasts.filter(x => x.until > t); }
    }
    // ms: its own (short) time; a short one takes the place of the short
    // ones before it (Zerp's notices: one at a time, not a pile)
    function push(n, ms) {
        const t = Date.now(), d = ms || life;
        toasts = toasts.filter(x => !(ms && x.short)).concat([{ n: n, t0: t, until: t + d, short: !!ms }]);
    }
    // the pointer on a toast: a little longer -- 15 s past its time at most
    function hold(n) {
        const t = Date.now();
        // (in place: a new list would make every card again)
        for (const x of toasts) if (same(x.n, n)) x.until = Math.min(x.t0 + (x.short ? 3000 : life + 15000), Math.max(x.until, t + 1500));
    }
    property bool badge: false
    readonly property bool dnd: Config.data.notif.dnd

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: false
        onNotification: n => {
            n.tracked = true;
            root.arrivals = root.arrivals.filter(a => a.n).concat([{ n: n, t: Date.now() }]);
            root.badge = true;
            if (!root.dnd || n.urgency === NotificationUrgency.Critical) { root.push(n); Sfx.notify(n.urgency === NotificationUrgency.Critical); }
        }
    }
    // when each came: "сейчас", "14 мин", "1 ч"
    property var arrivals: []
    property real now: Date.now()
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = Date.now() }
    function ago(n) {
        const a = arrivals.find(a => same(a.n, n));
        if (!a) return "";
        const m = Math.floor((now - a.t) / 60000);
        return m < 1 ? "сейчас" : m < 60 ? m + " мин" : Math.floor(m / 60) + " ч";
    }
    // the same notification? a card's `n` is a copy when it is one of our
    // own (a JS object through modelData): compared by the number given
    // it, not by identity -- by identity, a card never found its toast and
    // a click (or, before, the end of its time) took nothing away
    property int seq: 0
    function same(a, b) { return a === b || (!!a && !!b && a.key !== undefined && a.key === b.key); }
    function dropToast(n) { toasts = toasts.filter(t => !same(t.n, n)); }
    function dismiss(n) { dropToast(n); if (n.dismiss) n.dismiss(); else own = own.filter(o => !same(o, n)); }
    // the settings' "Проверить": a toast of our own (no notify-send here)
    function test(summary, body) { toast("notifications", summary, body, true); Sfx.notify(false); }
    // keep: into the centre as well (a notification); else a toast only
    function toast(icon, summary, body, keep, ms) {
        const n = { key: ++seq, summary: summary, body: body, appName: "xvlet", actions: [], image: "", appIcon: "", icon: icon };
        push(n, keep ? 0 : ms);
        if (keep) {
            own = own.concat([n]);
            arrivals = arrivals.concat([{ n: n, t: Date.now() }]);
            badge = true;
        }
    }
    function clear() { for (const n of server.trackedNotifications.values.slice()) n.dismiss(); own = []; toasts = []; }
    // an app's icon for a notification: its image, its app icon, a symbol
    function symbol(n) {
        if (n.icon) return n.icon;
        const a = (n.appName || "").toLowerCase();
        return a.includes("telegram") ? "send" : a.includes("mail") ? "mail" : a.includes("leaf") ? "eco" : a.includes("download") ? "download_done" : "notifications";
    }
}

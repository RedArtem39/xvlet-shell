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

    readonly property var list: server.trackedNotifications.values
    property var toasts: []
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
            root.badge = true;
            if (!root.dnd || n.urgency === NotificationUrgency.Critical) root.toasts = root.toasts.concat([n]);
        }
    }
    function dropToast(n) { toasts = toasts.filter(t => t !== n); }
    function dismiss(n) { dropToast(n); if (n.dismiss) n.dismiss(); }
    // the settings' "Проверить": a toast of our own (no notify-send here)
    function test(summary, body) { toasts = toasts.concat([{ summary: summary, body: body, appName: "xvlet", actions: [], image: "", appIcon: "" }]); }
    function clear() { for (const n of list.slice()) n.dismiss(); toasts = []; }
    // an app's icon for a notification: its image, its app icon, a symbol
    function symbol(n) {
        const a = (n.appName || "").toLowerCase();
        return a.includes("telegram") ? "send" : a.includes("mail") ? "mail" : a.includes("leaf") ? "eco" : a.includes("download") ? "download_done" : "notifications";
    }
}

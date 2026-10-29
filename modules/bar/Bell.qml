import QtQuick
import qs.components
import qs.services

// The notification centre (the quick settings' lower half); a dot while
// something new waits
IconButton {
    property bool vert: false
    icon: Notifs.dnd ? "notifications_off" : "notifications"
    badge: Notifs.badge
    on: Ui.pop === "qs"
    onClicked: { const p = mapToItem(null, width / 2, height / 2); Ui.toggle("qs", vert ? p.y : p.x); Notifs.badge = false; }
}

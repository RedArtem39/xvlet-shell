import QtQuick
import qs.components
import qs.services

// The session menu: lock, log out, restart, power off
IconButton {
    property bool vert: false
    icon: "power_settings_new"
    tint: Theme.error
    on: Ui.pop === "session"
    onClicked: Ui.toggle("session")
}

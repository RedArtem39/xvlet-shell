//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded

// xvlet: a Material 3 Expressive desktop shell. One wallpaper and one bar
// per screen; the rest (dock, launcher, widgets, settings) comes in stages.
import QtQuick
import Quickshell
import "modules/background"
import "modules/bar"

ShellRoot {
    FontLoader { source: Qt.resolvedUrl("assets/fonts/RobotoFlex.ttf") }

    Variants {
        model: Quickshell.screens
        Scope {
            required property var modelData
            Wallpaper { screen: modelData }
            Bar { screen: modelData }
        }
    }
}

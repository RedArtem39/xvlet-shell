pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// The default output (PipeWire): its volume and mute, set from the bar's
// wheel, the quick settings, the keys. `changed` brings up the OSD.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool present: !!(sink && sink.audio)
    readonly property real volume: present ? sink.audio.volume : 0
    readonly property bool muted: present ? sink.audio.muted : false
    readonly property string icon: !present ? "volume_off" : muted || volume <= 0 ? "volume_off" : volume < .34 ? "volume_mute" : volume < .67 ? "volume_down" : "volume_up"
    signal changed

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    function setVolume(v) {
        if (!present) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
        changed();
    }
    function step(d) { setVolume(volume + d); }
    function toggleMute() { if (present) { sink.audio.muted = !sink.audio.muted; changed(); } }
}

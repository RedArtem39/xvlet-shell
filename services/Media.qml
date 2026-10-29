pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// What plays: the MPRIS players, the one playing first. Nothing: the
// media pieces say so.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var player: {
        for (const p of players) if (p.isPlaying) return p;
        return players.length ? players[0] : null;
    }
    readonly property bool present: !!player
    readonly property bool playing: present && player.isPlaying
    readonly property string title: present ? (player.trackTitle || "Без названия") : "Ничего не играет"
    readonly property string artist: present ? [player.trackArtist, player.trackAlbum].filter(x => x).join(" · ") : ""
    readonly property string art: present ? (player.trackArtUrl || "") : ""
    readonly property real length: present ? Math.max(0, player.length) : 0
    property real position: 0

    // the position moves by itself; MPRIS reports it only when asked
    Timer {
        interval: 500; repeat: true; running: root.present
        onTriggered: { if (root.player) root.position = root.player.position; }
    }
    function toggle() { if (present && player.canTogglePlaying) player.togglePlaying(); }
    function next() { if (present && player.canGoNext) player.next(); }
    function prev() { if (present && player.canGoPrevious) player.previous(); }
    function seek(frac) { if (present && player.canSeek && length > 0) { player.position = frac * length; position = frac * length; } }
    function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0"); }
}

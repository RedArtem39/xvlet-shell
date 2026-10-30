import QtQuick
import QtMultimedia

// The sounds themselves (Qt Multimedia): each one loaded once and kept, so
// a click plays at once. Made by Sfx; on a system without Qt Multimedia
// this file does not load and Sfx goes on without it.
QtObject {
    id: p
    property string dir
    property var effects: ({})
    property Component kind: Component { SoundEffect {} }

    function load(key, file) {
        if (effects[key]) return effects[key];
        const e = kind.createObject(p, { source: dir + file });
        const m = Object.assign({}, effects); m[key] = e; effects = m;
        return e;
    }
    function play(key, file, vol) {
        const e = load(key, file);
        e.volume = Math.max(0, Math.min(1, vol));
        if (e.status === SoundEffect.Ready) e.play();
        else e.statusChanged.connect(function go() { if (e.status === SoundEffect.Ready) { e.play(); e.statusChanged.disconnect(go); } });
    }
}

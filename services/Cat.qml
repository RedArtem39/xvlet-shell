import QtQuick
import Quickshell.Io

// A file read by cat(1): for /proc and /sys, which a FileView takes for
// missing when stat(2) does not know them (WynlandOS's procfs). `loaded`
// with the text; `failed` when there is no such file.
Process {
    id: root
    property string path
    property string text: ""
    signal loaded(string text)
    signal failed

    command: ["cat", path]
    function reload() { if (!running) running = true; }
    stdout: StdioCollector {
        onStreamFinished: { root.text = text; if (text.length) root.loaded(text); }
    }
    onExited: code => { if (code !== 0) root.failed(); }
}

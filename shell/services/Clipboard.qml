pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Cronologia appunti tramite cliphist.
Singleton {
    id: root

    property var entries: []   // [{ id, text, line, isImage }]
    property bool loading: false
    readonly property string cacheDir: Quickshell.cachePath("clip")

    function refresh() {
        loading = true;
        listProc.running = true;
    }
    function copy(e) {
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "_", e.id]);
    }
    function remove(e) {
        Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "_", e.line]);
        entries = entries.filter(x => x !== e);
    }
    function wipe() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        entries = [];
    }
    function imagePath(e) {
        return cacheDir + "/" + e.id + ".png";
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(l => l.length > 0).slice(0, 300).map(l => {
                    const tab = l.indexOf("\t");
                    const id = l.slice(0, tab);
                    const content = l.slice(tab + 1);
                    return { id: id, text: content, line: l, isImage: /^\[\[ binary data .*(png|jpg|jpeg|webp|bmp|gif)/i.test(content) };
                });
                root.loading = false;
            }
        }
    }
}

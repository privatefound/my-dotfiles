import QtQuick
import Quickshell
import Quickshell.Io

// Selettore di file per i plugin DMS (stessa interfaccia di qs.Modals.FileBrowser di DMS),
// implementato con il selettore nativo di sistema (zenity).
Item {
    id: root

    property string browserTitle: "Seleziona un file"
    property string browserIcon: "folder_open"
    property string browserType: "generic"
    property var fileExtensions: []
    property alias filterExtensions: root.fileExtensions
    property bool showHiddenFiles: false
    property bool saveMode: false
    property bool folderMode: false
    property bool multiple: false
    property string defaultFileName: ""
    property string revealPath: ""
    property var parentPopout: null
    property var parentModal: null
    readonly property bool shouldBeVisible: dialog.running

    signal accepted(var paths)
    signal rejected
    signal fileSelected(string path)
    signal dialogClosed

    visible: false
    width: 0
    height: 0

    function open() {
        if (dialog.running)
            return;
        const args = ["zenity", "--file-selection", "--title=" + browserTitle];
        if (folderMode)
            args.push("--directory");
        if (saveMode) {
            args.push("--save", "--confirm-overwrite");
            if (defaultFileName)
                args.push("--filename=" + (revealPath ? revealPath.replace(/\/?$/, "/") : "") + defaultFileName);
        } else if (revealPath) {
            args.push("--filename=" + revealPath.replace(/\/?$/, "/"));
        }
        if (multiple)
            args.push("--multiple", "--separator=\n");
        const exts = (fileExtensions || []).filter(e => e && e !== "*" && e !== "*.*");
        if (exts.length > 0 && !folderMode)
            args.push("--file-filter=" + exts.join(" "), "--file-filter=Tutti i file | *");
        dialog.command = args;
        dialog.running = true;
    }

    function close() {
        if (dialog.running)
            dialog.signal(15);
    }

    function toggle() {
        dialog.running ? close() : open();
    }

    Process {
        id: dialog
        stdout: StdioCollector {
            id: out
        }
        onExited: code => {
            const paths = out.text.split("\n").map(s => s.trim()).filter(s => s);
            if (code === 0 && paths.length > 0) {
                root.accepted(paths);
                for (const p of paths)
                    root.fileSelected(p);
            } else {
                root.rejected();
            }
            root.dialogClosed();
        }
    }
}

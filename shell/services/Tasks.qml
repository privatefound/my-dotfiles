pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Impegni (pulsante accanto a caffeine). Stato in state/tasks.json, screenshot in state/tasks/.
// prio: 0 alta  · 1 media · 2 bassa · due: "YYYY-MM-DD" o ""
Singleton {
    id: root

    readonly property string imageDir: Settings.rootDir + "/state/tasks"
    readonly property var priorities: [
        { label: "Alta", color: Theme.error },
        { label: "Media", color: Theme.warning },
        { label: "Bassa", color: "#5ab0ff" }
    ]

    // da fare prima, poi priorità, scadenza (senza scadenza in fondo), creazione
    readonly property var sorted: store.items.slice().sort((a, b) => (a.done - b.done) || (a.prio - b.prio) || ((a.due || "9999") < (b.due || "9999") ? -1 : (a.due || "9999") > (b.due || "9999") ? 1 : 0) || (a.created - b.created))
    readonly property int pending: store.items.filter(t => !t.done).length
    readonly property bool overdue: store.items.some(t => !t.done && isOverdue(t))

    function today() {
        return Qt.formatDate(Time.now, "yyyy-MM-dd");
    }
    function isOverdue(t) {
        return !!t.due && t.due < today();
    }
    function get(id) {
        return store.items.find(t => t.id === id) ?? null;
    }

    function add(title) {
        title = title.trim();
        if (!title)
            return "";
        const id = Date.now().toString(36);
        store.items = store.items.concat([{ id: id, title: title, desc: "", due: "", prio: 1, done: false, images: [], created: Date.now() }]);
        return id;
    }
    function update(id, patch) {
        store.items = store.items.map(t => t.id === id ? Object.assign({}, t, patch) : t);
    }
    function toggle(id) {
        const t = get(id);
        if (t)
            update(id, { done: !t.done });
    }
    function remove(id) {
        const t = get(id);
        if (!t)
            return;
        for (const img of t.images)
            Quickshell.execDetached(["rm", "-f", "--", imageDir + "/" + img]);
        store.items = store.items.filter(x => x.id !== id);
    }
    function removeImage(id, img) {
        const t = get(id);
        if (!t)
            return;
        Quickshell.execDetached(["rm", "-f", "--", imageDir + "/" + img]);
        update(id, { images: t.images.filter(x => x !== img) });
    }

    // data ISO a `days` giorni da oggi
    function dueIn(days) {
        const d = new Date(Time.now);
        d.setDate(d.getDate() + days);
        return Qt.formatDate(d, "yyyy-MM-dd");
    }
    // accetta gg/mm, gg/mm/aa, gg/mm/aaaa; "" se non valida
    function parseDate(s) {
        const m = s.trim().match(/^(\d{1,2})[\/.-](\d{1,2})(?:[\/.-](\d{2,4}))?$/);
        if (!m)
            return "";
        let y = m[3] ? +m[3] : Time.now.getFullYear();
        if (y < 100)
            y += 2000;
        const d = new Date(y, +m[2] - 1, +m[1]);
        return d.getMonth() === +m[2] - 1 ? Qt.formatDate(d, "yyyy-MM-dd") : "";
    }
    function dueLabel(due) {
        if (!due)
            return "";
        if (due === today())
            return I18n.tr("oggi");
        if (due === dueIn(1))
            return I18n.tr("domani");
        const p = due.split("-");
        const d = new Date(+p[0], +p[1] - 1, +p[2]);
        return Qt.formatDate(d, d.getFullYear() === Time.now.getFullYear() ? "d MMM" : "d MMM yy");
    }

    // Incolla l'immagine degli appunti (se c'è) come screenshot del task
    function pasteImage(id) {
        const name = id + "-" + Date.now().toString(36) + ".png";
        const p = pasteComp.createObject(root, { taskId: id, name: name, command: ["sh", "-c", "wl-paste --list-types | grep -qx 'image/png' || exit 1; mkdir -p \"$1\" && wl-paste --type image/png > \"$1/$2\"", "_", imageDir, name] });
        p.running = true;
    }

    Component {
        id: pasteComp
        Process {
            id: p
            property string taskId
            property string name
            onExited: code => {
                const t = root.get(taskId);
                if (code === 0 && t)
                    root.update(taskId, { images: t.images.concat([name]) });
                p.destroy();
            }
        }
    }

    FileView {
        path: Settings.rootDir + "/state/tasks.json"
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }
        JsonAdapter {
            id: store
            property var items: []
        }
    }
}

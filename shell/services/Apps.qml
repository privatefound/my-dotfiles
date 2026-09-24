pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// App installate (.desktop) con ricerca fuzzy e ordinamento per frequenza d'uso.
Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values.filter(a => !a.noDisplay).slice().sort((a, b) => a.name.localeCompare(b.name))

    function score(app, q) {
        const name = (app.name || "").toLowerCase();
        const generic = (app.genericName || "").toLowerCase();
        const extra = ((app.keywords || []).join(" ") + " " + (app.id || "") + " " + (app.comment || "")).toLowerCase();
        let s = 0;
        if (name === q)
            s = 1000;
        else if (name.startsWith(q))
            s = 800;
        else if (name.split(/[\s\-_.]/).some(w => w.startsWith(q)))
            s = 600;
        else if (name.includes(q))
            s = 450;
        else if (generic.includes(q))
            s = 300;
        else if (extra.includes(q))
            s = 200;
        else {
            // sottosequenza (es. "fz" → "FileZilla")
            let i = 0;
            for (const c of name)
                if (c === q[i])
                    i++;
            if (i === q.length)
                s = 100 - (name.length - q.length);
        }
        return s;
    }

    function usage(app) {
        return state.counts[app.id] ?? 0;
    }

    function search(query) {
        const q = query.trim().toLowerCase();
        if (q === "")
            return all.slice().sort((a, b) => usage(b) - usage(a) || a.name.localeCompare(b.name));
        return all.map(a => ({ a, s: score(a, q) })).filter(x => x.s > 0).sort((x, y) => (y.s + Math.min(usage(y.a), 50) * 3) - (x.s + Math.min(usage(x.a), 50) * 3)).map(x => x.a);
    }

    function launch(app) {
        const c = Object.assign({}, state.counts);
        c[app.id] = (c[app.id] ?? 0) + 1;
        state.counts = c;
        if (app.runInTerminal)
            Quickshell.execDetached([Settings.terminal, "-e"].concat(app.command));
        else
            app.execute();
    }

    function iconFor(app) {
        return Quickshell.iconPath(app?.icon ?? "", "application-x-executable");
    }

    FileView {
        path: Settings.rootDir + "/state/apps.json"
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: state
            property var counts: ({})
        }
    }
}

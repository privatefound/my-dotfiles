pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import qs.config

// Server notifiche integrato (sostituisce swaync): popup + centro notifiche + Non disturbare.
Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values.slice().reverse()
    readonly property int count: list.length
    property var popups: []
    property var times: ({})

    readonly property bool dnd: Settings.dnd

    // Raggruppamento per app per il centro notifiche
    readonly property var groups: {
        const map = {};
        const order = [];
        for (const n of list) {
            const key = n.appName || "Sistema";
            if (!map[key]) {
                map[key] = { app: key, icon: n.appIcon, items: [] };
                order.push(key);
            }
            map[key].items.push(n);
        }
        return order.map(k => map[k]);
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            const t = Object.assign({}, root.times);
            t[n.id] = Date.now();
            root.times = t;

            const critical = n.urgency === NotificationUrgency.Critical;
            if (!root.dnd || critical) {
                root.popups = [n].concat(root.popups.filter(p => p !== n)).slice(0, 5);
                if (Settings.notifSound && n.urgency !== NotificationUrgency.Low)
                    sound.running = true;
            } else if (n.transient) {
                n.expire();
            }
        }
    }

    Process {
        id: sound
        command: ["pw-play", "--volume", "0.6", Quickshell.shellPath("assets/notification.ogg")]
    }

    function hidePopup(n) {
        popups = popups.filter(p => p !== n);
        if (n && n.transient)
            n.expire();
    }
    function dismiss(n) {
        hidePopup(n);
        n.dismiss();
    }
    function dismissGroup(g) {
        for (const n of g.items)
            dismiss(n);
    }
    function clearAll() {
        popups = [];
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }
    function invoke(n, action) {
        action.invoke();
        if (!n.resident)
            dismiss(n);
        else
            hidePopup(n);
    }
    function invokeDefault(n) {
        const a = n.actions.find(x => x.identifier === "default");
        if (a)
            invoke(n, a);
        else
            hidePopup(n);
    }
    function toggleDnd() {
        Settings.dnd = !Settings.dnd;
        if (Settings.dnd)
            popups = popups.filter(p => p.urgency === NotificationUrgency.Critical);
    }

    function timeAgo(n) {
        const t = times[n.id];
        if (!t)
            return "";
        const s = Math.floor((Time.now.getTime() - t) / 1000);
        if (s < 60)
            return "ora";
        if (s < 3600)
            return Math.floor(s / 60) + " min fa";
        if (s < 86400)
            return Math.floor(s / 3600) + " h fa";
        return Math.floor(s / 86400) + " g fa";
    }

    function iconFor(n) {
        const img = n.image || "";
        if (img)
            return img.startsWith("/") ? "file://" + img : img;
        const ic = n.appIcon || "";
        if (ic.startsWith("/"))
            return "file://" + ic;
        if (ic.startsWith("file://") || ic.startsWith("image://"))
            return ic;
        if (ic)
            return Quickshell.iconPath(ic, true);
        const entry = n.desktopEntry ? DesktopEntries.byId(n.desktopEntry) : null;
        return entry ? Quickshell.iconPath(entry.icon, true) : "";
    }

    function appIconFor(n) {
        const ic = n.appIcon || "";
        if (ic && !ic.startsWith("/") && !ic.includes("://"))
            return Quickshell.iconPath(ic, true);
        const entry = n.desktopEntry ? DesktopEntries.byId(n.desktopEntry) : DesktopEntries.heuristicLookup(n.appName);
        return entry ? Quickshell.iconPath(entry.icon, true) : "";
    }
}

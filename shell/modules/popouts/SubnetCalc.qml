import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

// Calcolatore di sottoreti IPv4 (tutto in JS, niente ipcalc).
// Accetta: 192.168.1.10/24 · 10.0.0.1 255.255.0.0 · 172.16.0.0/255.240.0.0
Item {
    id: root

    property var result: null
    property string error: ""
    property int splitPrefix: 0

    implicitWidth: 540
    implicitHeight: col.implicitHeight + 32

    Component.onCompleted: {
        input.focusInput();
        if (input.text === "")
            input.text = "192.168.1.10/24";
        calc();
    }

    function ipToInt(s) {
        const p = s.split(".");
        if (p.length !== 4)
            return null;
        let n = 0;
        for (const x of p) {
            if (!/^\d+$/.test(x) || parseInt(x) > 255)
                return null;
            n = n * 256 + parseInt(x);
        }
        return n >>> 0;
    }
    function intToIp(n) {
        return [n >>> 24, (n >>> 16) & 255, (n >>> 8) & 255, n & 255].join(".");
    }
    function maskFromPrefix(p) {
        return p === 0 ? 0 : (0xFFFFFFFF << (32 - p)) >>> 0;
    }
    function prefixFromMask(m) {
        let p = 0;
        let seenZero = false;
        for (let i = 31; i >= 0; i--) {
            if ((m >>> i) & 1) {
                if (seenZero)
                    return -1;
                p++;
            } else
                seenZero = true;
        }
        return p;
    }
    function bin(n) {
        return [n >>> 24, (n >>> 16) & 255, (n >>> 8) & 255, n & 255].map(o => o.toString(2).padStart(8, "0")).join(".");
    }

    function calc() {
        error = "";
        const raw = input.text.trim().replace(/\s+/g, " ");
        if (raw === "") {
            result = null;
            return;
        }
        let ipStr, maskPart;
        if (raw.includes("/"))
            [ipStr, maskPart] = raw.split("/");
        else if (raw.includes(" "))
            [ipStr, maskPart] = raw.split(" ");
        else {
            ipStr = raw;
            maskPart = "24";
        }
        const ip = ipToInt(ipStr.trim());
        if (ip === null) {
            error = "Indirizzo IP non valido";
            result = null;
            return;
        }
        let prefix;
        maskPart = maskPart.trim();
        if (/^\d+$/.test(maskPart))
            prefix = parseInt(maskPart);
        else {
            const m = ipToInt(maskPart);
            prefix = m === null ? -1 : prefixFromMask(m);
        }
        if (prefix < 0 || prefix > 32) {
            error = "Netmask / prefisso non valido";
            result = null;
            return;
        }
        const mask = maskFromPrefix(prefix);
        const net = (ip & mask) >>> 0;
        const bc = (net | (~mask >>> 0)) >>> 0;
        const total = Math.pow(2, 32 - prefix);
        const hosts = prefix >= 31 ? total : total - 2;
        const first = prefix >= 31 ? net : net + 1;
        const last = prefix >= 31 ? bc : bc - 1;
        const o1 = ip >>> 24;
        const cls = o1 < 128 ? "A" : o1 < 192 ? "B" : o1 < 224 ? "C" : o1 < 240 ? "D (multicast)" : "E";
        const priv = (o1 === 10) || (o1 === 172 && ((ip >>> 16) & 255) >= 16 && ((ip >>> 16) & 255) <= 31) || (o1 === 192 && ((ip >>> 16) & 255) === 168);
        const special = o1 === 127 ? "Loopback" : (o1 === 169 && ((ip >>> 16) & 255) === 254) ? "Link-local" : (o1 === 100 && ((ip >>> 16) & 255) >= 64 && ((ip >>> 16) & 255) <= 127) ? "CGNAT" : priv ? "Privata (RFC1918)" : "Pubblica";
        result = {
            ip: intToIp(ip), prefix, mask: intToIp(mask), wildcard: intToIp(~mask >>> 0),
            network: intToIp(net), broadcast: intToIp(bc), first: intToIp(first), last: intToIp(last),
            hosts, total, cls, type: special, binMask: bin(mask), binIp: bin(ip), net, bc
        };
        if (splitPrefix <= prefix || splitPrefix > 32)
            splitPrefix = Math.min(32, prefix + 2);
    }

    readonly property var subnets: {
        if (!result || splitPrefix <= result.prefix)
            return [];
        const size = Math.pow(2, 32 - splitPrefix);
        const count = Math.pow(2, splitPrefix - result.prefix);
        const out = [];
        for (let i = 0; i < Math.min(count, 64); i++) {
            const n = result.net + i * size;
            out.push({ net: intToIp(n) + "/" + splitPrefix, range: intToIp(splitPrefix >= 31 ? n : n + 1) + " – " + intToIp(splitPrefix >= 31 ? n + size - 1 : n + size - 2), bc: intToIp(n + size - 1) });
        }
        return out;
    }

    component Field: StyledRect {
        property string label
        property string value
        property bool accent: false
        Layout.fillWidth: true
        implicitHeight: 52
        radius: Theme.radius.normal
        color: Theme.surfaceContainer
        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 0
            StyledText {
                text: parent.parent.label
                font.pixelSize: Theme.font.tiny
                color: Theme.textFaint
            }
            StyledText {
                Layout.fillWidth: true
                text: parent.parent.value
                font.family: Theme.font.mono
                font.pixelSize: Theme.font.body
                font.weight: Font.DemiBold
                color: parent.parent.accent ? Theme.primary : Theme.text
            }
        }
        StateLayer {
            tint: Theme.primary
            onClicked: Quickshell.clipboardText = parent.value
        }
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Icon {
                text: Icons.ipNetwork
                size: 20
                color: Theme.primary
            }
            StyledText {
                Layout.fillWidth: true
                text: "Calcolatore subnet"
                font.pixelSize: Theme.font.title
                font.weight: Font.DemiBold
            }
            StyledText {
                text: "click su un campo = copia"
                font.pixelSize: Theme.font.tiny
                color: Theme.textFaint
            }
        }

        TextField {
            id: input
            Layout.fillWidth: true
            icon: Icons.lan
            placeholder: "192.168.1.10/24  ·  10.0.0.1 255.255.0.0"
            input.font.family: Theme.font.mono
            error: root.error !== ""
            onTextChanged: root.calc()
        }

        StyledText {
            visible: root.error !== ""
            text: root.error
            color: Theme.error
            font.pixelSize: Theme.font.small
        }

        GridLayout {
            Layout.fillWidth: true
            visible: root.result !== null
            columns: 3
            rowSpacing: 6
            columnSpacing: 6

            Field { label: "Rete"; value: root.result ? root.result.network + "/" + root.result.prefix : ""; accent: true }
            Field { label: "Netmask"; value: root.result?.mask ?? "" }
            Field { label: "Wildcard"; value: root.result?.wildcard ?? "" }
            Field { label: "Primo host"; value: root.result?.first ?? "" }
            Field { label: "Ultimo host"; value: root.result?.last ?? "" }
            Field { label: "Broadcast"; value: root.result?.broadcast ?? "" }
            Field { label: "Host utilizzabili"; value: root.result ? root.result.hosts.toLocaleString(Qt.locale("it_IT"), "f", 0) : ""; accent: true }
            Field { label: "Classe"; value: root.result?.cls ?? "" }
            Field { label: "Tipo"; value: root.result?.type ?? "" }
        }

        StyledRect {
            Layout.fillWidth: true
            visible: root.result !== null
            implicitHeight: binCol.implicitHeight + 16
            radius: Theme.radius.normal
            color: Theme.surfaceContainer
            ColumnLayout {
                id: binCol
                anchors.fill: parent
                anchors.margins: 8
                anchors.leftMargin: 12
                spacing: 2
                StyledText {
                    text: "IP    " + (root.result?.binIp ?? "")
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.small
                    color: Theme.textDim
                }
                StyledText {
                    text: "MASK  " + (root.result?.binMask ?? "")
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.small
                    color: Theme.primary
                }
            }
        }

        // Suddivisione in sottoreti
        RowLayout {
            Layout.fillWidth: true
            visible: root.result !== null && root.result.prefix < 32
            spacing: 6
            SectionHeader {
                text: "Suddividi in /" + root.splitPrefix + "  (" + (root.result ? Math.pow(2, root.splitPrefix - root.result.prefix) : 0) + " subnet)"
                icon: Icons.grid
            }
            IconButton {
                size: 30
                icon: Icons.minus
                disabled: !root.result || root.splitPrefix <= root.result.prefix + 1
                onClicked: root.splitPrefix--
            }
            IconButton {
                size: 30
                icon: Icons.plus
                disabled: root.splitPrefix >= 32
                onClicked: root.splitPrefix++
            }
        }

        ScrollColumn {
            visible: root.subnets.length > 0
            maxHeight: 180
            Repeater {
                model: root.subnets
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 12
                    StyledText {
                        Layout.preferredWidth: 150
                        text: modelData.net
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.small
                        color: Theme.primary
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.range
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.small
                    }
                    StyledText {
                        text: "bc " + modelData.bc
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.tiny
                        color: Theme.textFaint
                    }
                }
            }
        }
    }
}

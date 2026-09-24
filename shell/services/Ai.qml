pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Chat con modelli locali (Ollama e llama.cpp), con cronologia della conversazione.
Singleton {
    id: root

    property var models: []          // [{ label, id, backend }]
    property bool busy: false
    property string error: ""
    readonly property string modelLabel: (Settings.aiBackend === "llamacpp" ? "llama.cpp · " : "ollama · ") + Settings.aiModel

    // role: "user" | "assistant", content
    readonly property ListModel messages: ListModel {}

    function refreshModels() {
        models = [];
        ollamaList.running = true;
        llamaList.running = true;
    }

    function selectModel(m) {
        Settings.aiModel = m.id;
        Settings.aiBackend = m.backend;
    }

    function history() {
        const out = [{ role: "system", content: Settings.aiSystemPrompt }];
        for (let i = 0; i < messages.count; i++) {
            const m = messages.get(i);
            if (m.content !== "")
                out.push({ role: m.role, content: m.content });
        }
        return out;
    }

    function send(text) {
        text = text.trim();
        if (text === "" || busy)
            return;
        error = "";
        messages.append({ role: "user", content: text });
        const body = history();
        messages.append({ role: "assistant", content: "" });
        busy = true;

        if (Settings.aiBackend === "llamacpp") {
            chatProc.command = ["curl", "-sN", "http://localhost:8080/v1/chat/completions", "-H", "Content-Type: application/json", "-d", JSON.stringify({ model: Settings.aiModel, messages: body, stream: true })];
        } else {
            chatProc.command = ["curl", "-sN", "http://localhost:11434/api/chat", "-d", JSON.stringify({ model: Settings.aiModel, messages: body, stream: true })];
        }
        chatProc.running = true;
    }

    function stop() {
        chatProc.running = false;
        busy = false;
    }

    function clear() {
        stop();
        messages.clear();
        error = "";
    }

    function appendChunk(s) {
        const i = messages.count - 1;
        if (i < 0)
            return;
        messages.setProperty(i, "content", messages.get(i).content + s);
    }

    // Markdown minimale → rich text
    function markdown(text) {
        const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        const accent = Theme.primary.toString();
        const blocks = [];
        text = text.replace(/```[\w+-]*\n?([\s\S]*?)(```|$)/g, (m, code) => {
            blocks.push(`<pre style="background:${Theme.surfaceContainerHighest};color:${accent};">${esc(code.replace(/\n$/, ""))}</pre>`);
            return `\u0000${blocks.length - 1}\u0000`;
        });
        text = esc(text);
        text = text.replace(/`([^`\n]+)`/g, `<code style="color:${accent};">$1</code>`);
        text = text.replace(/^### (.+)$/gm, `<b style="color:${accent};">$1</b>`);
        text = text.replace(/^## (.+)$/gm, `<b style="color:${accent};font-size:15px;">$1</b>`);
        text = text.replace(/^# (.+)$/gm, `<b style="color:${accent};font-size:16px;">$1</b>`);
        text = text.replace(/\*\*([^*]+)\*\*/g, "<b>$1</b>");
        text = text.replace(/(^|[^*])\*([^*\n]+)\*/g, "$1<i>$2</i>");
        text = text.replace(/^\s*[-*] (.+)$/gm, "&nbsp;&nbsp;• $1");
        text = text.replace(/^---$/gm, "<hr>");
        text = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g, `<a href="$2" style="color:${accent};">$1</a>`);
        text = text.replace(/\n/g, "<br>");
        text = text.replace(/\u0000(\d+)\u0000/g, (m, i) => blocks[parseInt(i)]);
        return text;
    }

    Process {
        id: chatProc
        stdout: SplitParser {
            onRead: data => {
                let line = data.trim();
                if (line === "")
                    return;
                if (line.startsWith("data:"))
                    line = line.slice(5).trim();
                if (line === "[DONE]") {
                    root.busy = false;
                    return;
                }
                try {
                    const j = JSON.parse(line);
                    if (j.error) {
                        root.error = typeof j.error === "string" ? j.error : (j.error.message ?? I18n.tr("Errore"));
                        return;
                    }
                    const c = j.message?.content ?? j.choices?.[0]?.delta?.content ?? "";
                    if (c)
                        root.appendChunk(c);
                    if (j.done)
                        root.busy = false;
                } catch (e) {}
            }
        }
        onExited: code => {
            root.busy = false;
            if (code !== 0 && code !== 15 && code !== 9)
                root.error = I18n.tr("Impossibile contattare ") + (Settings.aiBackend === "llamacpp" ? "llama.cpp (localhost:8080)" : "Ollama (localhost:11434)");
            const i = root.messages.count - 1;
            if (i >= 0 && root.messages.get(i).role === "assistant" && root.messages.get(i).content === "")
                root.messages.remove(i);
        }
    }

    Process {
        id: ollamaList
        command: ["sh", "-c", "ollama list 2>/dev/null | tail -n +2 | awk '{print $1}'"]
        stdout: SplitParser {
            onRead: line => {
                const n = line.trim();
                if (n)
                    root.models = root.models.concat([{ label: "ollama · " + n, id: n, backend: "ollama" }]);
            }
        }
    }

    Process {
        id: llamaList
        command: ["curl", "-s", "--max-time", "2", "http://localhost:8080/v1/models"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    const arr = j.data || j.models || [];
                    const add = [];
                    for (const m of arr) {
                        const id = m.id || m.model || m.name;
                        if (id)
                            add.push({ label: "llama.cpp · " + id.split("/").pop().replace(/\.gguf$/i, ""), id: id, backend: "llamacpp" });
                    }
                    root.models = root.models.concat(add);
                } catch (e) {}
            }
        }
    }
}

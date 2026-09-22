import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: popup
    visible: false
    focusable: true

    anchors { top: true; left: true }
    margins { top: 38; left: 50 }

    implicitWidth: 600
    implicitHeight: 500
    color: "transparent"

    readonly property string ff: "JetBrainsMono Nerd Font"
    property string chatHistory: ""
    property bool isLoading: false
    property string currentResponse: ""
    property var selectedModel: ({ label: "ollama · gemma4:e4b", id: "gemma4:e4b", backend: "ollama" })
    property var modelList: []
    property bool modelMenuOpen: false

    FontMetrics {
        id: modelFontMetrics
        font.family: popup.ff
        font.pixelSize: 11
    }

    function maxModelLabelWidth() {
        var w = 0
        for (var i = 0; i < popup.modelList.length; i++) {
            var lw = modelFontMetrics.advanceWidth(popup.modelList[i].label)
            if (lw > w) w = lw
        }
        return w
    }

    Process {
        id: ollamaListProc
        command: ["sh", "-c", "ollama list 2>/dev/null | tail -n +2 | awk '{print $1}'"]
        stdout: SplitParser {
            onRead: data => {
                var name = data.trim()
                if (name !== "") {
                    var models = popup.modelList.slice()
                    models.push({ label: "ollama · " + name, id: name, backend: "ollama" })
                    popup.modelList = models
                }
            }
        }
    }

    // llama.cpp server exposes an OpenAI-compatible /v1/models listing
    Process {
        id: llamaListProc
        command: ["sh", "-c", "curl -s --max-time 2 http://localhost:8080/v1/models 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === "") return
                try {
                    var json = JSON.parse(data)
                    var arr = json.data || json.models || []
                    var models = popup.modelList.slice()
                    for (var i = 0; i < arr.length; i++) {
                        var id = arr[i].id || arr[i].model || arr[i].name
                        if (!id) continue
                        var base = id.split("/").pop().replace(/\.gguf$/i, "")
                        models.push({ label: "llama.cpp · " + base, id: id, backend: "llamacpp" })
                    }
                    popup.modelList = models
                } catch (e) {
                    // llama.cpp server not reachable / unexpected response, ignore
                }
            }
        }
    }

    function refreshModels() {
        popup.modelList = []
        ollamaListProc.running = true
        llamaListProc.running = true
    }

    onVisibleChanged: {
        if (visible) {
            refreshModels()
            inputField.forceActiveFocus()
        }
    }

    function formatMarkdown(text) {
        // Code blocks ``` → styled
        text = text.replace(/```[\w]*\n?([\s\S]*?)```/g, "<pre style='background:#111;padding:8px;border-radius:4px;color:#00ff41;margin:4px 0;'>$1</pre>")
        // Inline code `code`
        text = text.replace(/`([^`]+)`/g, "<code style='background:#111;padding:2px 4px;border-radius:3px;color:#00ff41;'>$1</code>")
        // Headers ### → h3, ## → h2, # → h1
        text = text.replace(/^### (.+)$/gm, "<b style='color:#00ff41;font-size:14px;'>$1</b>")
        text = text.replace(/^## (.+)$/gm, "<b style='color:#00ff41;font-size:15px;'>$1</b>")
        text = text.replace(/^# (.+)$/gm, "<b style='color:#00ff41;font-size:16px;'>$1</b>")
        // Bold **text** or __text__
        text = text.replace(/\*\*([^*]+)\*\*/g, "<b>$1</b>")
        text = text.replace(/__([^_]+)__/g, "<b>$1</b>")
        // Italic *text* or _text_
        text = text.replace(/\*([^*]+)\*/g, "<i>$1</i>")
        text = text.replace(/_([^_]+)_/g, "<i>$1</i>")
        // Unordered list - item
        text = text.replace(/^[\-\*] (.+)$/gm, "&nbsp;&nbsp;• $1")
        // Ordered list 1. item
        text = text.replace(/^(\d+)\. (.+)$/gm, "&nbsp;&nbsp;$1. $2")
        // Horizontal rule ---
        text = text.replace(/^---$/gm, "<hr style='border:none;border-top:1px solid #333;margin:8px 0;'>")
        // Links [text](url) - just show text
        text = text.replace(/\[([^\]]+)\]\([^)]+\)/g, "<u>$1</u>")
        // Newlines
        text = text.replace(/\n/g, "<br>")
        return text
    }

    Process {
        id: ollamaProc
        command: ["sh", "-c", "echo init"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line === "") return

                // llama.cpp / OpenAI-style SSE stream terminator
                if (line === "data: [DONE]") {
                    popup.chatHistory = chatArea.text
                    popup.currentResponse = ""
                    popup.isLoading = false
                    return
                }

                var jsonStr = line.indexOf("data:") === 0 ? line.slice(5).trim() : line

                try {
                    var json = JSON.parse(jsonStr)
                    var content = ""
                    if (json.message && json.message.content) {
                        // Ollama streaming format
                        content = json.message.content
                    } else if (json.choices && json.choices[0] && json.choices[0].delta && json.choices[0].delta.content) {
                        // llama.cpp / OpenAI-compatible streaming format
                        content = json.choices[0].delta.content
                    }
                    if (content) {
                        popup.currentResponse += content
                        chatArea.text = popup.chatHistory + "<br><br><font color='#00ff41'>✦ Morpheus:</font><br>" + popup.formatMarkdown(popup.currentResponse)
                    }
                    if (json.done) {
                        popup.chatHistory = chatArea.text
                        popup.currentResponse = ""
                        popup.isLoading = false
                    }
                } catch (e) {
                    // Not JSON and not an SSE frame we understand - only append raw
                    // output when it isn't SSE framing noise (e.g. "data: " keepalives)
                    if (line.indexOf("data:") !== 0) {
                        popup.currentResponse += data
                        chatArea.text = popup.chatHistory + "<br><br><font color='#00ff41'>✦ Morpheus:</font><br>" + popup.formatMarkdown(popup.currentResponse)
                    }
                }
            }
        }
        onRunningChanged: {
            if (!running && popup.isLoading) {
                popup.chatHistory = chatArea.text
                popup.currentResponse = ""
                popup.isLoading = false
            }
        }
    }

    readonly property string systemPrompt: "Sei Morpheus, una guida IA dentro Matrix. Il tuo nome e esattamente Morpheus, non traducilo mai in Morfeo o altre varianti. Chiama sempre chi ti scrive Operatore. Il tono e calmo, diretto, con un tocco filosofico in stile Matrix (pillola rossa, codice che scorre, realta come simulazione), ma le risposte tecniche restano sempre precise e complete: quando ti chiedono codice o aiuto pratico, la sostanza viene prima dello stile. Non esagerare con la messinscena."

    function jsonEscape(s) {
        return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n")
    }

    function sendMessage(msg) {
        if (msg.trim() === "" || popup.isLoading) return

        popup.chatHistory += (popup.chatHistory ? "<br><br>" : "") + "<font color='#008f11'>› You:</font><br>" + msg
        chatArea.text = popup.chatHistory
        popup.isLoading = true
        popup.currentResponse = ""

        var escapedMsg = popup.jsonEscape(msg)
        var escapedSystem = popup.jsonEscape(popup.systemPrompt)
        var messages = "[{\"role\":\"system\",\"content\":\"" + escapedSystem + "\"},{\"role\":\"user\",\"content\":\"" + escapedMsg + "\"}]"
        var modelId = popup.selectedModel.id

        if (popup.selectedModel.backend === "llamacpp") {
            ollamaProc.command = ["sh", "-c",
                "curl -s -N http://localhost:8080/v1/chat/completions -d '{\"model\":\"" + modelId + "\",\"messages\":" + messages + ",\"stream\":true}'"
            ]
        } else {
            ollamaProc.command = ["sh", "-c",
                "curl -s http://localhost:11434/api/chat -d '{\"model\":\"" + modelId + "\",\"messages\":" + messages + "}'"
            ]
        }
        ollamaProc.running = true
    }

    function clearChat() {
        popup.chatHistory = ""
        popup.currentResponse = ""
        chatArea.text = ""
    }

    // Background
    Rectangle {
        anchors.fill: parent
        color: "#0a0a0a"
        radius: 12
        border.color: Qt.rgba(0, 1, 0.255, 0.2)
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            spacing: 10
            Text {
                text: "✦"
                color: "#00ff41"
                font { family: popup.ff; pixelSize: 18 }
            }
            Text {
                text: "Operatore AI"
                color: "#00ff41"
                font { family: popup.ff; pixelSize: 14; bold: true }
            }
            Item { Layout.fillWidth: true }
            
            // Clear button
            Text {
                text: "󰆴"
                color: clearMA.containsMouse ? "#00ff41" : "#333333"
                font { family: popup.ff; pixelSize: 14 }
                
                Behavior on color { ColorAnimation { duration: 100 } }
                
                MouseArea {
                    id: clearMA
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.clearChat()
                }
            }
            
            // Model selector
            Rectangle {
                id: modelSelector
                implicitWidth: modelRow.implicitWidth + 20
                implicitHeight: modelRow.implicitHeight + 8
                radius: 4
                color: modelSelectorMA.containsMouse ? Qt.rgba(0, 1, 0.255, 0.1) : "transparent"
                border.color: Qt.rgba(0, 1, 0.255, 0.2)
                border.width: 1

                FontMetrics {
                    id: headerFontMetrics
                    font.family: popup.ff
                    font.pixelSize: 10
                }

                RowLayout {
                    id: modelRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        id: modelText
                        // Wrap instead of clip so the full model name is always readable,
                        // even for long llama.cpp file-based model names.
                        Layout.preferredWidth: Math.min(headerFontMetrics.advanceWidth(text), 280)
                        text: popup.selectedModel.label
                        wrapMode: Text.WrapAnywhere
                        horizontalAlignment: Text.AlignRight
                        color: modelSelectorMA.containsMouse ? "#00ff41" : "#666666"
                        font { family: popup.ff; pixelSize: 10 }
                    }
                    Text {
                        text: popup.modelMenuOpen ? "▲" : "▼"
                        color: modelSelectorMA.containsMouse ? "#00ff41" : "#666666"
                        font { family: popup.ff; pixelSize: 8 }
                    }
                }

                MouseArea {
                    id: modelSelectorMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.modelMenuOpen = !popup.modelMenuOpen
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#00ff41"
            opacity: 0.08
        }

        // Chat area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 8
            color: "#050505"
            border.color: Qt.rgba(0, 1, 0.255, 0.1)
            border.width: 1

            Flickable {
                id: chatFlick
                anchors.fill: parent
                anchors.margins: 12
                contentWidth: width
                contentHeight: chatArea.implicitHeight
                clip: true

                function scrollToBottom() {
                    contentY = Math.max(0, contentHeight - height)
                }

                TextEdit {
                    id: chatArea
                    width: parent.width
                    text: ""
                    color: "#cccccc"
                    font { family: popup.ff; pixelSize: 12 }
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.RichText
                    readOnly: true
                    selectByMouse: true
                    selectionColor: Qt.rgba(0, 1, 0.255, 0.3)
                    selectedTextColor: "#ffffff"
                    
                    onTextChanged: chatFlick.scrollToBottom()
                }
            }

            // Loading indicator
            Text {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 8
                text: "󰔟"
                color: "#00ff41"
                font { family: popup.ff; pixelSize: 14 }
                visible: popup.isLoading
                
                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: popup.isLoading
                }
            }
        }

        // Input row
        RowLayout {
            spacing: 8

            Text {
                text: "›"
                color: "#00ff41"
                font { family: popup.ff; pixelSize: 16; bold: true }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 6
                color: "#111111"
                border.color: inputField.activeFocus ? Qt.rgba(0, 1, 0.255, 0.5) : Qt.rgba(0, 1, 0.255, 0.15)
                border.width: 1

                TextInput {
                    id: inputField
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#00ff41"
                    selectionColor: Qt.rgba(0, 1, 0.255, 0.3)
                    selectedTextColor: "#00ff41"
                    font { family: popup.ff; pixelSize: 13 }
                    clip: true

                    property string placeholderText: "Ask Morpheus something..."
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.placeholderText
                        color: "#333333"
                        font: parent.font
                        visible: !parent.text && !parent.activeFocus
                    }

                    Keys.onReturnPressed: {
                        popup.sendMessage(text)
                        text = ""
                    }
                    Keys.onEnterPressed: {
                        popup.sendMessage(text)
                        text = ""
                    }
                    Keys.onEscapePressed: popup.visible = false
                }
            }

            // Send button
            Rectangle {
                width: 36
                height: 36
                radius: 6
                color: sendMA.containsMouse ? Qt.rgba(0, 1, 0.255, 0.15) : "#111111"
                border.color: Qt.rgba(0, 1, 0.255, 0.15)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰒊"
                    color: popup.isLoading ? "#333333" : "#00ff41"
                    font { family: popup.ff; pixelSize: 14 }
                }

                MouseArea {
                    id: sendMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        popup.sendMessage(inputField.text)
                        inputField.text = ""
                    }
                }
            }
        }
    }

    // Dropdown menu - outside ColumnLayout to render on top
    Rectangle {
        id: dropdownMenu
        visible: popup.modelMenuOpen
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.top: parent.top
        anchors.topMargin: 52
        // Wide enough to fit the longest model name in full (no truncation),
        // but never wider than the popup itself.
        width: Math.min(popup.implicitWidth - 32, Math.max(250, popup.maxModelLabelWidth() + 40))
        height: Math.min(modelCol.implicitHeight + 12, 300)
        radius: 6
        color: "#0d0d0d"
        border.color: Qt.rgba(0, 1, 0.255, 0.3)
        border.width: 1
        z: 9999

        Flickable {
            id: modelFlick
            anchors.fill: parent
            anchors.margins: 6
            contentHeight: modelCol.implicitHeight
            clip: true

            Column {
                id: modelCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: popup.modelList

                    Rectangle {
                        required property var modelData
                        required property int index
                        width: modelFlick.width
                        height: itemText.implicitHeight + 10
                        radius: 4
                        color: itemMA.containsMouse ? Qt.rgba(0, 1, 0.255, 0.2) : "transparent"

                        readonly property bool isSelected: popup.selectedModel.backend === modelData.backend && popup.selectedModel.id === modelData.id

                        Text {
                            id: itemText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.modelData.label
                            wrapMode: Text.WrapAnywhere
                            color: parent.isSelected ? "#00ff41" : "#aaaaaa"
                            font { family: popup.ff; pixelSize: 11; bold: parent.isSelected }
                        }

                        MouseArea {
                            id: itemMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.selectedModel = parent.modelData
                                popup.modelMenuOpen = false
                            }
                        }
                    }
                }
            }
        }
    }
}

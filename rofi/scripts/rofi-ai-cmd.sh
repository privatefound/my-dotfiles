#!/bin/bash

# Configurazione
ROFI_CONF="$HOME/.config/hypr/rofi/config.rasi"
# Usiamo un array per gestire correttamente gli argomenti con spazi
ROFI_THEME=(-theme-str 'window { width: 800px; }')
MODEL="gemma3:1b"

# Prompt dell'utente
PROMPT=$(echo "" | rofi -dmenu -p "󰂶 Describe task:" -config "$ROFI_CONF" "${ROFI_THEME[@]}" -i)

if [ -z "$PROMPT" ]; then
    exit 0
fi

# Chiamata a Ollama
COMMAND=$(curl -s -X POST http://localhost:11434/api/generate -d "{
  \"model\": \"$MODEL\",
  \"prompt\": \"Convert to a single Linux command: $PROMPT. Return ONLY the command.\",
  \"stream\": false
}" | jq -r '.response // empty' | xargs)

# Menu Azioni
ACTION=$(echo -e "󰅍 Copy: $COMMAND\n󰆍 Run in Terminal\n󰈆 Exit" | rofi -dmenu -p "AI CMD Output" -config "$ROFI_CONF" "${ROFI_THEME[@]}" -i)

case "$ACTION" in
    "󰅍 Copy"*)
        echo -n "$COMMAND" | wl-copy
        notify-send "AI CMD" "Copied!"
        ;;
    "󰆍 Run in Terminal")
        kitty -e bash -c "$COMMAND; echo ''; echo 'Done. Press Enter...'; read"
        ;;
    *)
        exit 0
        ;;
esac

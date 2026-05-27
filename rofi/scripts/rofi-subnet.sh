#!/bin/bash

# Configurazione
ROFI_CONF="$HOME/.config/hypr/rofi/config.rasi"
ROFI_THEME=(-theme-str 'window { width: 650px; } listview { lines: 12; }')
MODEL="gemma3:1b"

# Prompt per l'input
INPUT=$(echo "" | rofi -dmenu -p "󰈀 IPv4 Subnet (e.g. 10.0.0.0/24):" -config "$ROFI_CONF" -theme "$HOME/.config/hypr/rofi/theme.rasi" "${ROFI_THEME[@]}" -i)

if [ -z "$INPUT" ]; then exit 0; fi

# Controllo se ipcalc è presente
if command -v ipcalc >/dev/null 2>&1; then
    RESULT=$(ipcalc -n -b "$INPUT" | grep -v "color")
else
    # Prompt AI più aggressivo e strutturato per evitare errori di calcolo
    RESULT=$(curl -s -X POST http://localhost:11434/api/generate -d "{
      \"model\": \"$MODEL\",
      \"prompt\": \"Act as a network engineer. Calculate the following for IPv4 subnet $INPUT: Network Address, Netmask (CIDR/Decimal), Wildcard Mask, Broadcast Address, First Usable Host, Last Usable Host, and Total Usable Hosts. Return ONLY the list, one per line. No conversation.\",
      \"stream\": false
    }" | jq -r '.response // empty' | xargs -0)
    
    # Aggiunge un suggerimento per installare ipcalc in fondo
    RESULT="${RESULT}\n\n---\nTip: Install 'ipcalc' for 100% accurate math."
fi

# Visualizzazione
echo -e "$RESULT" | rofi -dmenu -p "Subnet Analysis" -config "$ROFI_CONF" -theme "$HOME/.config/hypr/rofi/theme.rasi" "${ROFI_THEME[@]}" -i

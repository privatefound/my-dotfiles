#!/bin/bash

# File temporaneo per salvare l'indice dell'interfaccia corrente
STATE_FILE="/tmp/waybar_network_ip_index"

# Ottiene la lista delle interfacce attive con un indirizzo IPv4 (escludendo 'lo')
get_interfaces() {
    ip -o -4 addr show | awk '{print $2}' | grep -v "lo" | sort -u
}

# Ottiene l'indirizzo IP per un'interfaccia specifica
get_ip() {
    local iface=$1
    ip -o -4 addr show "$iface" | awk '{print $4}' | cut -d/ -f1 | head -n1
}

# Ottiene l'icona in base al tipo di interfaccia
get_icon() {
    local iface=$1
    if [[ "$iface" =~ ^wl ]]; then
        echo "󰤨" # Wi-Fi
    elif [[ "$iface" =~ ^en || "$iface" =~ ^eth ]]; then
        echo "󰈀" # Ethernet
    else
        echo "󰈀" # Altro (VPN, etc.)
    fi
}

interfaces=($(get_interfaces))
count=${#interfaces[@]}

# Se non ci sono interfacce attive
if [ "$count" -eq 0 ]; then
    echo '{"text": "󰤮 Offline", "tooltip": "Nessuna connessione attiva", "class": "disconnected"}'
    exit 0
fi

# Legge l'indice corrente o lo inizializza a 0
if [ ! -f "$STATE_FILE" ]; then
    echo 0 > "$STATE_FILE"
fi
index=$(cat "$STATE_FILE")

# Se l'indice è fuori range (interfacce rimosse), resetta a 0
if [ "$index" -ge "$count" ]; then
    index=0
    echo 0 > "$STATE_FILE"
fi

# Se il comando è "next", incrementa l'indice
if [ "$1" == "next" ]; then
    index=$(( (index + 1) % count ))
    echo "$index" > "$STATE_FILE"
    # L'output qui non serve, Waybar riceverà il segnale e rieseguirà lo script senza 'next'
    exit 0
fi

current_iface=${interfaces[$index]}
current_ip=$(get_ip "$current_iface")
current_icon=$(get_icon "$current_iface")

# Costruzione del tooltip con tutte le interfacce disponibili
tooltip="Interfaccia attiva: $current_iface\n\nInterfacce rilevate:\n"
for i in "${!interfaces[@]}"; do
    if [ "$i" -eq "$index" ]; then
        tooltip+="➜ ${interfaces[$i]}: $(get_ip "${interfaces[$i]}")\n"
    else
        tooltip+="  ${interfaces[$i]}: $(get_ip "${interfaces[$i]}")\n"
    fi
done
tooltip+="\nClicca per passare alla prossima interfaccia."

# Output JSON per Waybar
echo "{\"text\": \"$current_icon $current_ip\", \"tooltip\": \"$tooltip\", \"class\": \"$current_iface\"}"

#!/usr/bin/env bash

# File: ~/.config/hypr/scripts/wifi-menu.sh
# Dipendenze: nmcli, wofi, notify-send

# 1. Ottieni la lista delle reti WiFi disponibili tramite nmcli
# Formato: SSID:SEGNALE:SICUREZZA:BARRE
# Escludiamo righe vuote o con --
networks=$(nmcli -t -f SSID,SIGNAL,SECURITY,BARS dev wifi list | sed '/^--/d' | sed '/^$/d')

# Se non ci sono reti
if [[ -z "$networks" ]]; then
    notify-send "WiFi" "Nessuna rete trovata"
    exit 1
fi

# 2. Mostra la lista in wofi
# Puliamo la lista per wofi: mostriamo barre di segnale e SSID
# Usiamo awk per: 
# 1. Filtrare i duplicati (teniamo solo la rete con segnale più forte, la prima occorrenza)
# 2. Mappare il segnale (%) a icone Nerd Font
# 3. Gestire reti senza SSID (Hidden)
# 4. Formattare: "ICONA_SEGNALE  SSID  (SICUREZZA)"
wofi_list=$(echo "$networks" | awk -F: '!seen[$1]++ { 
    s=$2; 
    if(s >= 80) icon="󰤨"; 
    else if(s >= 60) icon="󰤥"; 
    else if(s >= 40) icon="󰤢"; 
    else if(s >= 20) icon="󰤟"; 
    else icon="󰤯";
    
    lock=($3 == "--" || $3 == "" ? "" : " ");
    ssid=($1 == "" ? "(Nascosto)" : $1); 
    
    printf "%s%s  %s  (%s)\n", icon, lock, ssid, $3 
}')

chosen_network=$(echo "$wofi_list" | wofi --dmenu --prompt "󰤨  Seleziona WiFi" --style ~/.config/hypr/wofi_style.css --width 400 --height 450 --cache-file /dev/null)

# Se l'utente preme ESC o chiude wofi
if [[ -z "$chosen_network" ]]; then
    exit 0
fi

# 3. Estrai l'SSID dalla scelta
# chosen_network è nel formato: "▂▄▆_  SSID_Name  (WPA2)"
# Usiamo awk per estrarre la parte centrale in modo più preciso
ssid=$(echo "$chosen_network" | awk -F'  ' '{print $2}')

# 4. Tenta la connessione
# Mostriamo una notifica di tentativo
notify-send "WiFi" "Tentativo di connessione a: $ssid"

# Proviamo a connetterci. Se fallisce perché manca la password, usiamo wofi per chiederla.
success=$(nmcli dev wifi connect "$ssid" 2>&1)

if [[ "$success" == *"Error: Password"* || "$success" == *"Error: Secrets"* ]]; then
    # Se serve la password, chiediamola con wofi in modalità password
    pass=$(wofi --dmenu --password --prompt "Inserisci Password per $ssid" --style ~/.config/hypr/wofi_style.css --width 400 --height 100)
    
    if [[ -n "$pass" ]]; then
        success=$(nmcli dev wifi connect "$ssid" password "$pass" 2>&1)
    else
        notify-send "WiFi" "Connessione annullata"
        exit 0
    fi
fi

if [[ $? -eq 0 ]]; then
    notify-send "WiFi" "Connesso con successo a $ssid"
else
    notify-send "WiFi" "Errore nella connessione: $success"
fi

#!/bin/bash

# Se viene passato un argomento, connettiti
if [ "$@" ]; then
    # Estrai l'SSID (rimuovendo l'icona e la sicurezza)
    ssid=$(echo "$@" | sed 's/^.*  //;s/  (.*)$//')
    
    # Tenta la connessione
    notify-send "WiFi" "Tentativo di connessione a: $ssid"
    if nmcli dev wifi connect "$ssid"; then
        notify-send "WiFi" "Connesso con successo a $ssid"
    else
        # Se serve la password, chiedila con un prompt di rofi
        pass=$(rofi -dmenu -password -p "Password for $ssid:" -config "$HOME/.config/hypr/rofi/config.rasi" -theme "$HOME/.config/hypr/rofi/theme.rasi")
        if [ ! -z "$pass" ]; then
            nmcli dev wifi connect "$ssid" password "$pass"
        fi
    fi
    exit 0
fi

# Altrimenti, elenca le reti disponibili (senza forzare il rescan per velocità)
nmcli -t -f SIGNAL,SECURITY,SSID dev wifi list --rescan no | sed '/^--/d' | awk -F: '{ 
    s=$1; 
    if(s >= 80) icon="󰤨"; 
    else if(s >= 60) icon="󰤥"; 
    else if(s >= 40) icon="󰤢"; 
    else if(s >= 20) icon="󰤟"; 
    else icon="󰤯";
    
    lock=($2 == "--" || $2 == "" ? "" : " ");
    printf "%s%s  %s  (%s)\n", icon, lock, $3, $2
}'

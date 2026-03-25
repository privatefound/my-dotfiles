#!/bin/bash

case "$1" in
    "connection")
        if ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1; then
            echo '{"text": "<span color=\"#00ff41\">󰣇</span>", "tooltip": "Online", "class": "online"}'
        else
            echo '{"text": "<span color=\"#ff3333\">󰣇</span>", "tooltip": "Offline", "class": "offline"}'
        fi
        ;;

    "weather")
        weather_info=$(curl -s "wttr.in/?format=%C+%t")
        if [[ $? -eq 0 && -n "$weather_info" ]]; then
            temp=$(echo "$weather_info" | rev | cut -d' ' -f1 | rev)
            echo "󰖐 $temp" # Icona fissa per stabilità, o puoi riaggiungere il mapping
        else
            echo "N/A"
        fi
        ;;
esac

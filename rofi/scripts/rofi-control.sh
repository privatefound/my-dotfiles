#!/bin/bash

# Se viene passato un argomento, esegui l'azione
if [ "$@" ]; then
    case "$@" in
        " Volume Up") pamixer -i 5 ;;
        " Volume Down") pamixer -d 5 ;;
        "󰝟 Mute Audio") pamixer -t ;;
        "󰃠 Brightness Up") brightnessctl set 10%+ ;;
        "󰃟 Brightness Down") brightnessctl set 10%- ;;
        "󰐥 Power Menu")
            power_options="Shutdown\nReboot\nLogout\nLock"
            p_choice=$(echo -e "$power_options" | rofi -dmenu -config ~/.config/hypr/rofi/config.rasi -p "Power" -i)
            case "$p_choice" in
                "Shutdown") shutdown now ;;
                "Reboot") reboot ;;
                "Logout") hyprctl dispatch exit ;;
                "Lock") hyprlock ;;
            esac
            ;;
    esac
    exit 0
fi

# Altrimenti, elenca le opzioni
echo -e " Volume Up"
echo -e " Volume Down"
echo -e "󰝟 Mute Audio"
echo -e "󰃠 Brightness Up"
echo -e "󰃟 Brightness Down"
echo -e "󰐥 Power Menu"

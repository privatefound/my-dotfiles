#!/bin/bash
#
# Wallpaper Selector per Hyprland con awww
# Seleziona wallpaper tramite rofi
#

WALLPAPER_DIR="$HOME/.config/hypr/wallpaper"
HYPR_DIR="$HOME/.config/hypr"

# Assicura che awww-daemon sia attivo
pgrep -x awww-daemon > /dev/null || {
    awww-daemon &
    sleep 0.5
}

# Lista wallpaper disponibili
list_wallpapers() {
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) -exec basename {} \;
}

# Menu rofi
selected=$(list_wallpapers | sort | rofi -dmenu -p "󰸉 Wallpaper" -config "$HYPR_DIR/rofi/config.rasi" -theme-str 'listview { lines: 8; }')

[[ -z "$selected" ]] && exit 0

wallpaper_path="$WALLPAPER_DIR/$selected"

if [[ -f "$wallpaper_path" ]]; then
    # Applica con transizione
    awww img "$wallpaper_path" \
        --transition-type any \
        --transition-pos top-right \
        --transition-duration 0.9 \
        --transition-fps 120
    
    # Aggiorna hyprland.lua per persistenza
    sed -i "s|awww img ~/.config/hypr/wallpaper/[^ ]*|awww img ~/.config/hypr/wallpaper/$selected|" "$HYPR_DIR/hyprland.lua"
    
    notify-send "󰸉 Wallpaper" "Impostato: $selected" -t 2000
fi

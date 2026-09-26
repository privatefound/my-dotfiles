#!/usr/bin/env bash
# Adatta Hyprland all'alimentazione:
#  - a batteria: pannello interno (eDP) a 60Hz, niente blur, ombre e animazioni,
#                profilo power-profiles-daemon "power-saver"
#  - collegato:  ricarica la config, così torna tutto come in hyprland.lua/monitors.lua,
#                e profilo "balanced"
# Resta in ascolto di udev (alimentatore collegato/scollegato) e di Hyprland
# (configreloaded: un reload fatto a batteria riporterebbe i 120Hz e gli effetti).

exec 9>"$XDG_RUNTIME_DIR/hypr-power-mode.lock"
flock -n 9 || exit 0
trap 'kill 0' EXIT

on_battery() {
    local s
    for s in /sys/class/power_supply/BAT*/status; do
        [[ $(<"$s") == Discharging ]] && return 0
    done
    return 1
}

# Riapplica i pannelli interni a 60Hz mantenendo posizione, scala e colore di monitors.lua
battery_mode() {
    local lua
    lua=$(hyprctl monitors -j | jq -r '
        .[] | select(.name | startswith("eDP"))
        | "\(.width)x\(.height)@60" as $mode
        | select(any(.availableModes[]; startswith($mode)))
        | "hl.monitor({ output = \"\(.name)\", mode = \"\($mode)\", position = \"\(.x)x\(.y)\", scale = \(.scale), transform = \(.transform), cm = \"\(.colorManagementPreset)\", sdr_min_luminance = \(.sdrMinLuminance), sdr_max_luminance = \(.sdrMaxLuminance) })"')
    hyprctl eval "$lua
        hl.config({
            decoration = { blur = { enabled = false }, shadow = { enabled = false } },
            animations = { enabled = false },
        })" >/dev/null
}

set_profile() {
    command -v powerprofilesctl >/dev/null && powerprofilesctl set "$1"
}

state=""
check() {
    local now=ac
    on_battery && now=battery
    if [[ $1 == reloaded ]]; then
        [[ $now == battery ]] && battery_mode
    elif [[ $now != "$state" ]]; then
        if [[ $now == battery ]]; then
            battery_mode
            set_profile power-saver
        elif [[ -n $state ]]; then
            hyprctl reload >/dev/null
            set_profile balanced
        fi
    fi
    state=$now
}

check
{
    udevadm monitor --udev --subsystem-match=power_supply &
    socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
} | while read -r line; do
    case $line in
        configreloaded*) check reloaded ;;
        UDEV*)           check ;;
    esac
done

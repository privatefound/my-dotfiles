#!/bin/bash

WIDTH=25
DELAY=0.2
NOTIF_FILE="/tmp/waybar_swaync_notif"

trap "rm -f '$NOTIF_FILE'; kill 0" EXIT INT TERM

# Intercetta notifiche D-Bus e salva testo + app nei file
(
    str_count=0
    in_notify=false
    summary=""
    body=""

    dbus-monitor --session "interface='org.freedesktop.Notifications',member='Notify'" 2>/dev/null | \
    while IFS= read -r line; do
        if [[ "$line" == *"member=Notify"* ]]; then
            in_notify=true
            str_count=0
            summary=""
            body=""
        elif $in_notify; then
            if [[ "$line" =~ ^[[:space:]]*string\ \"(.*)\"$ ]]; then
                val="${BASH_REMATCH[1]}"
                str_count=$((str_count + 1))
                case $str_count in
                    1) ;; # app_name - skip
                    2) ;; # app_icon - skip
                    3) summary="$val" ;;
                    4)
                        body=$(echo "$val" | sed 's/<[^>]*>//g')
                        if [ -n "$summary" ] && [ -n "$body" ]; then
                            echo "${summary}: ${body}" > "$NOTIF_FILE"
                        elif [ -n "$summary" ]; then
                            echo "${summary}" > "$NOTIF_FILE"
                        fi
                        in_notify=false
                        ;;
                esac
            fi
        fi
    done
) &

OFFSET=0
TEXT=""
LAST_NOTIF=""

while true; do
    CURRENT_NOTIF=$(cat "$NOTIF_FILE" 2>/dev/null)

    if [ -n "$CURRENT_NOTIF" ]; then
        if [ "$CURRENT_NOTIF" != "$LAST_NOTIF" ]; then
            LAST_NOTIF="$CURRENT_NOTIF"
            OFFSET=0
            TEXT="${CURRENT_NOTIF}   ---   "
        fi

        if [ ${#LAST_NOTIF} -gt $WIDTH ]; then
            LEN=${#TEXT}
            DISPLAY_TEXT=""
            for (( i=0; i<WIDTH; i++ )); do
                IDX=$(( (OFFSET + i) % LEN ))
                DISPLAY_TEXT="${DISPLAY_TEXT}${TEXT:$IDX:1}"
            done
            OFFSET=$(( (OFFSET + 1) % LEN ))
        else
            DISPLAY_TEXT="$LAST_NOTIF"
        fi

        SAFE_DISPLAY=$(printf '%s' "$DISPLAY_TEXT" | sed 's/"/\\"/g')
        SAFE_TOOLTIP=$(printf '%s' "$CURRENT_NOTIF" | sed 's/"/\\"/g')
        printf '{"text": "󰂚 %s", "tooltip": "%s", "class": "new"}\n' "$SAFE_DISPLAY" "$SAFE_TOOLTIP"
    else
        printf '{"text": "", "tooltip": "Nessuna notifica", "class": "empty"}\n'
        LAST_NOTIF=""
    fi

    sleep "$DELAY"
done

#!/bin/bash

# Lunghezza visibile del ticker
WIDTH=25
# Velocità di scorrimento (secondi)
DELAY=0.2

LAST_ID=""
TEXT=""
OFFSET=0

while true; do
    # Recupera l'ultima notifica dalla cronologia di Dunst
    HISTORY=$(dunstctl history)
    COUNT=$(echo "$HISTORY" | jq '.data[0] | length')

    if [ "$COUNT" -gt 0 ]; then
        NOTIF=$(echo "$HISTORY" | jq '.data[0][0]')
        ID=$(echo "$NOTIF" | jq -r '.id.data')
        SUMMARY=$(echo "$NOTIF" | jq -r '.summary.data')
        BODY=$(echo "$NOTIF" | jq -r '.body.data' | tr -d '\n' | sed 's/<[^>]*>//g') # Rimuove tag HTML (tipo <b>)
        
        FULL_TEXT="$SUMMARY: $BODY"
        
        # Se la notifica è cambiata, resetta lo stato
        if [ "$ID" != "$LAST_ID" ]; then
            LAST_ID="$ID"
            OFFSET=0
            # Aggiungiamo spazi alla fine per distanziare il loop
            TEXT="$FULL_TEXT   ---   "
        fi

        # Se il testo è troppo lungo, scorre
        if [ ${#FULL_TEXT} -gt $WIDTH ]; then
            LEN=${#TEXT}
            # Estrae la sottostringa per l'effetto marquee
            DISPLAY_TEXT=""
            for (( i=0; i<$WIDTH; i++ )); do
                IDX=$(( (OFFSET + i) % LEN ))
                DISPLAY_TEXT="$DISPLAY_TEXT${TEXT:$IDX:1}"
            done
            OFFSET=$(( (OFFSET + 1) % LEN ))
        else
            DISPLAY_TEXT="$FULL_TEXT"
        fi

        # Formattazione JSON per Waybar
        printf '{"text": "󰂚 %s", "tooltip": "%s", "class": "new"}\n' "$DISPLAY_TEXT" "$FULL_TEXT"
    else
        # Se non ci sono notifiche, mostra nulla (o un'icona vuota se preferisci)
        printf '{"text": "", "tooltip": "Nessuna notifica", "class": "empty"}\n'
        LAST_ID=""
    fi

    sleep "$DELAY"
done

#!/bin/bash

# Configurazione
FILE_CACHE="/tmp/waybar_news.txt"
LAST_UPDATE="/tmp/waybar_news_last"
INTERVAL=600 # 10 minuti tra un aggiornamento AI e l'altro
MODEL="gemma3:1b"

# Funzione per aggiornare la news (Gira in background)
update_news() {
    # 1. Estrazione titoli dai feed
    FEEDS=("https://www.ransomware.live/rss" "https://feeds.feedburner.com/TheHackersNews")
    TITLES=""
    for url in "${FEEDS[@]}"; do
        T=$(curl -s --max-time 10 "$url" | tr -d '\n' | grep -oP '(?<=<item>).*?(?=</item>)' | grep -oP '(?<=<title>).*?(?=</title>)' | sed 's/<!\[CDATA\[//g; s/\]\]>//g; s/<[^>]*>//g' | head -n 2 | tr '\n' ' ')
        TITLES+="$T "
    done

    # 2. Chiamata a Ollama (Gemma 3)
    RESPONSE=$(curl -s -X POST http://localhost:11434/api/generate -d "{
      \"model\": \"$MODEL\",
      \"prompt\": \"News: $TITLES. Summarize the most urgent threat in exactly 5 words. No intro.\",
      \"stream\": false
    }" | jq -r '.response // empty' | xargs | tr -d '\"' | cut -d ' ' -f 1-6)

    # 3. Fallback se l'AI fallisce
    if [ -z "$RESPONSE" ] || [ "$RESPONSE" = "null" ]; then
        RESPONSE=$(echo "$TITLES" | cut -d ' ' -f 1-5)"..."
    fi

    # 4. Salva Risultato e Timestamp
    echo "󰆧 $RESPONSE" > "$FILE_CACHE"
    date +%s > "$LAST_UPDATE"
}

# --- LOGICA PRINCIPALE ---

# Se il file non esiste, crealo subito (prima esecuzione)
if [ ! -f "$FILE_CACHE" ]; then
    echo "󰒃 Inizializzazione..." > "$FILE_CACHE"
    update_news &
fi

# Controlla se è ora di aggiornare (asincrono)
NOW=$(date +%s)
LAST=$(cat "$LAST_UPDATE" 2>/dev/null || echo 0)
if (( NOW - LAST > INTERVAL )); then
    update_news & 
fi

# Sputa fuori il contenuto attuale per Waybar (Istantaneo)
cat "$FILE_CACHE"
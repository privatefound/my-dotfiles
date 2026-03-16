#!/bin/sh
# Script per riprodurre il suono della notifica
# Questo script viene chiamato da Dunst ogni volta che arriva una notifica.

# Percorso del file audio (usa $HOME per portabilità)
SOUND_FILE="$HOME/.config/hypr/dunst/sound.mp3"

# Riproduci il suono usando mpg123
# Usiamo -o alsa perché hai confermato che funziona meglio
if [ -f "$SOUND_FILE" ]; then
    /usr/bin/mpg123 -o alsa -q "$SOUND_FILE" &
fi

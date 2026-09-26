#!/bin/sh
# Riavvia la shell Quickshell (SUPER+SHIFT+W).
# Usa SIGKILL: Quickshell 0.3 può andare in crash durante la chiusura normale e il suo
# gestore dei crash la rilancerebbe da solo, lasciando due barre. Con SIGKILL non succede.
SHELL_DIR="$HOME/.config/hypr/shell"
COMPAT="$HOME/.config/hypr/scripts/omarchy-compat"
case ":$PATH:" in *":$COMPAT:"*) ;; *) PATH="$PATH:$COMPAT"; export PATH ;; esac

for pid in $(qs list --all 2>/dev/null | awk '/Process ID/ {print $3}'); do
    kill -9 "$pid" 2>/dev/null
done
pkill -9 -f "^qs -p $SHELL_DIR\$" 2>/dev/null
pkill -9 -x quickshell 2>/dev/null
sleep 0.4

exec qs -p "$SHELL_DIR"

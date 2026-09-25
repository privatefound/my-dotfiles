#!/usr/bin/env bash
# =============================================================================
# install.sh — green-hyprtheme v2 installer (Hyprland + Quickshell)
# =============================================================================
#   ./install.sh            installa con symlink ~/.config/hypr → repo (default)
#   ./install.sh --copy     copia i file invece di creare il symlink
#   ./install.sh --no-deps  salta l'installazione dei pacchetti
#   ./install.sh --yes      risponde "sì" a tutte le domande opzionali
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; LGREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

ok()      { echo -e "${GREEN}[✔]${NC} $*"; }
info()    { echo -e "${CYAN}[→]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
err()     { echo -e "${RED}[✘]${NC} $*" >&2; }
section() { echo -e "\n${LGREEN}${BOLD}── $* ${DIM}$(printf '─%.0s' $(seq 1 $((60 - ${#1}))))${NC}"; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="$HOME/.config/hypr"
QS_LINK="$HOME/.config/quickshell"
STAMP="$(date +%Y%m%d_%H%M%S)"
USE_COPY=false
INSTALL_DEPS=true
ASSUME_YES=false

for arg in "$@"; do
    case "$arg" in
        --copy) USE_COPY=true ;;
        --no-deps) INSTALL_DEPS=false ;;
        --yes|-y) ASSUME_YES=true ;;
        -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
        *) err "Opzione sconosciuta: $arg"; exit 1 ;;
    esac
done

# ask "domanda" default(y|n)
ask() {
    local q="$1" def="${2:-n}" ans
    if $ASSUME_YES; then return 0; fi
    local hint="[y/N]"; [[ "$def" == y ]] && hint="[Y/n]"
    read -rp "$(echo -e "${YELLOW}?${NC} $q $hint ")" ans || true
    ans="${ans:-$def}"
    [[ "${ans,,}" == y* ]]
}

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${LGREEN}${BOLD}"
cat <<'BANNER'
   ▄▄ • ▄▄▄  ▄▄▄ .▄▄▄ . ▐ ▄     ▄ .▄ ▄· ▄▌ ▄▄▄·▄▄▄  
  ▐█ ▀ ▪▀▄ █·▀▄.▀·▀▄.▀·•█▌▐█   ██▪▐█▐█▪██▌▐█ ▄█▀▄ █·
  ▄█ ▀█▄▐▀▀▄ ▐▀▀▪▄▐▀▀▪▄▐█▐▐▌   ██▀▐█▐█▌▐█▪ ██▀·▐▀▀▄ 
  ▐█▄▪▐█▐█•█▌▐█▄▄▌▐█▄▄▌██▐█▌   ██▌▐▀ ▐█▀·.▐█▪·•▐█•█▌
  ·▀▀▀▀ .▀  ▀ ▀▀▀  ▀▀▀ ▀▀ █▪   ▀▀▀ ·  ▀ • .▀   .▀  ▀
BANNER
echo -e "${NC}  ${BOLD}green-hyprtheme v2${NC} — Hyprland + Quickshell"
echo -e "  ${DIM}repo: $REPO_DIR · modo: $($USE_COPY && echo copia || echo symlink)${NC}"

# ── Controlli ─────────────────────────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then err "Non eseguire come root (verrà usato sudo quando serve)."; exit 1; fi
if ! command -v pacman &>/dev/null; then warn "Installer pensato per Arch Linux: salterò i pacchetti."; INSTALL_DEPS=false; fi

# ── 1. Pacchetti ──────────────────────────────────────────────────────────────
# Tutto è nei repository ufficiali (core/extra): basta pacman.
PACKAGES=(
    # compositor, lock, idle, portali, uscita pulita
    hyprland hyprlock hypridle hyprpicker hyprshutdown
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-utils
    # shell Quickshell + moduli Qt usati (QML, SVG, Wayland, webp/gif per gli sfondi)
    quickshell qt6-base qt6-declarative qt6-svg qt6-wayland qt6-imageformats qt6-5compat
    # audio / media (pw-play per il suono delle notifiche)
    pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol playerctl
    # rete: NetworkManager + agente segreti Wi‑Fi/VPN + OpenVPN/WireGuard
    networkmanager network-manager-applet nm-connection-editor networkmanager-openvpn wireguard-tools
    # bluetooth (blueman-applet fa da agente per l'associazione) ed energia
    bluez bluez-utils blueman upower
    # appunti, screenshot, luminosità, notifiche, sfondi, portachiavi, polkit
    wl-clipboard cliphist grim slurp swappy brightnessctl libnotify awww
    curl jq gnome-keyring polkit
    # login screen
    greetd greetd-tuigreet
    # font e temi (JetBrainsMono Nerd Font per le icone, Adwaita Sans per il testo)
    ttf-jetbrains-mono-nerd adwaita-fonts noto-fonts-emoji ttf-material-symbols-variable
    # plugin DMS: git per installarli, font delle icone Material Symbols
    git
    papirus-icon-theme nwg-look qt5ct qt6ct
    # app usate dalla config (modificabili in hyprland.lua / impostazioni)
    terminology nemo conky mission-center
)
# Opzionali dai repo ufficiali
OPTIONAL_REPO=(ollama)
# Opzionali da AUR (servono paru o yay): cast dello schermo e gestione monitor
OPTIONAL_AUR=(gnome-network-displays monique)

section "Pacchetti"
if $INSTALL_DEPS; then
    info "Pacchetti richiesti: ${#PACKAGES[@]} (tutti dai repository ufficiali)"
    if ask "Installo le dipendenze con pacman?" y; then
        sudo pacman -S --needed "${PACKAGES[@]}"
        ok "Dipendenze installate."
    fi
    if ask "Installo Ollama per Morpheus (IA locale)?" n; then
        sudo pacman -S --needed "${OPTIONAL_REPO[@]}" && ok "Ollama installato."
    fi
    AUR=""
    command -v paru &>/dev/null && AUR=paru
    [[ -z "$AUR" ]] && command -v yay &>/dev/null && AUR=yay
    if [[ -n "$AUR" ]]; then
        if ask "Installo gli extra da AUR con $AUR (${OPTIONAL_AUR[*]})?" n; then
            $AUR -S --needed "${OPTIONAL_AUR[@]}" || warn "Extra AUR non installati."
        fi
    else
        info "Extra AUR (${OPTIONAL_AUR[*]}): installali con un AUR helper se ti servono."
    fi
else
    info "Installazione pacchetti saltata."
fi

# Controllo finale dei comandi essenziali
MISSING=()
for c in Hyprland qs hyprlock hypridle awww cliphist wl-paste grim slurp swappy brightnessctl nmcli pw-play; do
    command -v "$c" &>/dev/null || MISSING+=("$c")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
    warn "Comandi mancanti: ${MISSING[*]}"
else
    ok "Tutti i comandi essenziali sono presenti."
fi

# ── 2. Config Hyprland (backup + link) ────────────────────────────────────────
section "Configurazione"
if [[ "$(readlink -f "$HYPR_DIR" 2>/dev/null)" == "$REPO_DIR" ]]; then
    ok "~/.config/hypr è già questa repo."
else
    if [[ -e "$HYPR_DIR" || -L "$HYPR_DIR" ]]; then
        mv "$HYPR_DIR" "$HYPR_DIR.backup.$STAMP"
        ok "Config precedente salvata in ~/.config/hypr.backup.$STAMP"
    fi
    mkdir -p "$HOME/.config"
    if $USE_COPY; then
        cp -a "$REPO_DIR" "$HYPR_DIR"
        ok "File copiati in $HYPR_DIR"
    else
        ln -s "$REPO_DIR" "$HYPR_DIR"
        ok "Symlink: $HYPR_DIR → $REPO_DIR"
    fi
fi

# Quickshell: `qs` senza argomenti avvia la shell del tema
if [[ -e "$QS_LINK" && ! -L "$QS_LINK" ]]; then
    mv "$QS_LINK" "$QS_LINK.backup.$STAMP"
    warn "~/.config/quickshell esistente spostato in quickshell.backup.$STAMP"
fi
ln -sfn "$HYPR_DIR/shell" "$QS_LINK"
ok "~/.config/quickshell → ~/.config/hypr/shell"

# Monitor
if [[ ! -f "$HYPR_DIR/monitors.lua" ]]; then
    info "Nessun monitors.lua: verrà usata la risoluzione preferita (vedi monitors.lua.example)."
fi

# Notifiche: la shell ha il suo server, i vecchi demoni non devono partire
for svc in swaync dunst mako; do
    if systemctl --user is-enabled "$svc.service" &>/dev/null; then
        systemctl --user disable --now "$svc.service" && ok "Disabilitato $svc (sostituito dalla shell)."
    fi
done

# ── 3. Lock screen ────────────────────────────────────────────────────────────
section "Lock screen (hyprlock)"
ok "hyprlock.conf e hypridle.conf pronti (blocco dopo 5 min, SUPER+CTRL+L)."

# ── 4. Login screen (greetd + tuigreet) ───────────────────────────────────────
section "Login screen (greetd + tuigreet)"
if command -v tuigreet &>/dev/null; then
    if ask "Imposto greetd + tuigreet (tema verde) come login screen?" n; then
        if [[ -f /etc/greetd/config.toml ]]; then
            sudo cp /etc/greetd/config.toml "/etc/greetd/config.toml.backup.$STAMP"
            ok "Backup: /etc/greetd/config.toml.backup.$STAMP"
        fi
        sudo install -Dm644 "$REPO_DIR/greetd/config.toml" /etc/greetd/config.toml
        # niente messaggi di avvio sopra il login (parte a boot finito, terminale pulito)
        sudo install -Dm644 "$REPO_DIR/greetd/greetd-override.conf" /etc/systemd/system/greetd.service.d/override.conf
        sudo systemctl daemon-reload
        sudo gpasswd -a greeter video &>/dev/null || true
        sudo gpasswd -a greeter render &>/dev/null || true
        for dm in sddm gdm lightdm ly; do
            if systemctl is-enabled "$dm" &>/dev/null; then
                sudo systemctl disable "$dm" && warn "Disabilitato $dm."
            fi
        done
        sudo systemctl enable greetd
        ok "greetd abilitato (attivo dal prossimo avvio)."
    fi
else
    warn "tuigreet non installato: salto il login screen."
fi

# ── 5. Servizi ────────────────────────────────────────────────────────────────
section "Servizi di sistema"
for svc in NetworkManager bluetooth; do
    if systemctl is-enabled "$svc" &>/dev/null; then
        ok "$svc già abilitato."
    elif systemctl list-unit-files "$svc.service" &>/dev/null && ask "Abilito $svc?" y; then
        sudo systemctl enable --now "$svc" && ok "$svc abilitato."
    fi
done

if ask "Installo NetworkManager-fixed.service (NM senza conflitti con networkd/dhcpcd)?" n; then
    sudo install -Dm644 "$REPO_DIR/systemd/NetworkManager-fixed.service" /etc/systemd/system/NetworkManager-fixed.service
    sudo systemctl daemon-reload
    ok "Installato. Abilitalo con: sudo systemctl enable --now NetworkManager-fixed"
fi

# ── 6. Morpheus (IA locale) ───────────────────────────────────────────────────
section "Morpheus — IA locale (opzionale)"
if command -v ollama &>/dev/null; then
    if ask "Abilito Ollama e scarico gemma4:e4b (modello consigliato)?" n; then
        sudo systemctl enable --now ollama
        ollama pull gemma4:e4b && ok "Modello pronto."
    fi
else
    info "Ollama non installato: la chat funziona anche con un server llama.cpp su localhost:8080."
fi

# ── 7. VA-API (decodifica video hardware) ─────────────────────────────────────
section "VA-API (opzionale)"
if ask "Installo i driver VA-API per la decodifica video hardware?" n; then
    echo -e "  1) Intel gen8+   2) Intel vecchia   3) AMD   4) NVIDIA"
    read -rp "  Scelta [1-4]: " GPU || true
    case "${GPU:-}" in
        1) VA=(intel-media-driver libva-utils) ;;
        2) VA=(libva-intel-driver libva-utils) ;;
        3) VA=(libva-mesa-driver libva-utils) ;;
        4) VA=(libva-nvidia-driver libva-utils) ;;
        *) VA=() ;;
    esac
    if [[ ${#VA[@]} -gt 0 ]]; then
        sudo pacman -S --needed "${VA[@]}" && ok "VA-API installato (verifica con: vainfo)."
    fi
fi

# ── Fine ──────────────────────────────────────────────────────────────────────
echo -e "\n${LGREEN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
echo -e "${LGREEN}${BOLD}  Fatto. Esci e rientra (o riavvia) per avviare il tema.${NC}"
echo -e "${LGREEN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
echo -e "  ${CYAN}Scorciatoie:${NC} SUPER+D launcher · SUPER+A control center · SUPER+ESC sessione"
echo -e "  ${CYAN}Documentazione:${NC} $HYPR_DIR/README.md"
echo -e "  ${CYAN}Già in Hyprland?${NC} ricarica con: hyprctl reload && qs -p ~/.config/hypr/shell &"

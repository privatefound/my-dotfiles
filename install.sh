#!/usr/bin/env bash
# =============================================================================
# install.sh - green-hyprtheme installer
# =============================================================================
# Usage:
#   ./install.sh          - Install with symlink (default)
#   ./install.sh --copy   - Install by copying files instead of symlinking
# =============================================================================

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[✔]${NC} $*"; }
info() { echo -e "${CYAN}[→]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✘]${NC} $*" >&2; }

# ── Config ────────────────────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="$HOME/.config/hypr"
BACKUP_DIR="$HOME/.config/hypr.backup.$(date +%Y%m%d_%H%M%S)"
USE_COPY=false

[[ "${1:-}" == "--copy" ]] && USE_COPY=true

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${GREEN}${BOLD}"
echo "  ████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗ █████╗ ██╗     "
echo "  ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗██║     "
echo "     ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║███████║██║     "
echo "     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██╔══██║██║     "
echo "     ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██║  ██║███████╗"
echo "     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝"
echo -e "${NC}"
echo -e "  ${BOLD}green-hyprtheme${NC} — Hyprland Installer"
echo -e "  Mode: $([ "$USE_COPY" = true ] && echo 'copy' || echo 'symlink')"
echo ""

# ── Step 0: Install dependencies ─────────────────────────────────────────────
PACKAGES=(
    hyprland hyprlock hypridle hyprpicker
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    waybar swaync libnotify
    rofi rofi-calc gnome-keyring
    kitty nemo fish starship
    brave-bin sublime-text-4
    ttf-jetbrains-mono-nerd ttf-hack-nerd
    ttf-font-awesome otf-font-awesome noto-fonts-emoji
    pipewire pipewire-alsa pipewire-pulse wireplumber
    pavucontrol pasystray pamixer playerctl
    bluez bluez-utils blueman
    networkmanager network-manager-applet nm-connection-editor
    networkmanager-openvpn iwgtk
    polkit-kde-agent
    grim slurp swappy
    wl-clipboard cliphist
    brightnessctl swaybg
    jq curl ipcalc
    ollama gsimplecal
    greetd greetd-tuigreet
    nwg-look qt5ct qt6ct
    conky mission-center
)

echo -e "${CYAN}${BOLD}── Dependencies ─────────────────────────────────────────────────────${NC}"
if command -v paru &>/dev/null; then
    read -rp "$(echo -e "${YELLOW}Install all dependencies with paru? [Y/n] ${NC}")" INSTALL_DEPS
    if [[ "${INSTALL_DEPS,,}" != "n" ]]; then
        info "Installing packages ..."
        paru -S --needed --noconfirm "${PACKAGES[@]}"
        ok "Packages installed."
    else
        info "Skipping package installation."
    fi
elif command -v yay &>/dev/null; then
    read -rp "$(echo -e "${YELLOW}paru not found, install dependencies with yay instead? [Y/n] ${NC}")" INSTALL_DEPS
    if [[ "${INSTALL_DEPS,,}" != "n" ]]; then
        info "Installing packages with yay ..."
        yay -S --needed --noconfirm "${PACKAGES[@]}"
        ok "Packages installed."
    else
        info "Skipping package installation."
    fi
else
    warn "Neither paru nor yay found. Install dependencies manually (see INSTALLATION.md)."
fi
echo ""

# ── Sanity check ──────────────────────────────────────────────────────────────
if [[ "$REPO_DIR" == "$HYPR_DIR" ]]; then
    warn "Repo is already at $HYPR_DIR — skipping backup and link steps."
    warn "Running post-install setup only."
    SKIP_LINK=true
else
    SKIP_LINK=false
fi

# ── Step 1: Backup existing config ───────────────────────────────────────────
if [[ "$SKIP_LINK" == false ]]; then
    if [[ -e "$HYPR_DIR" || -L "$HYPR_DIR" ]]; then
        info "Backing up existing config to $BACKUP_DIR ..."
        mv "$HYPR_DIR" "$BACKUP_DIR"
        ok "Backup created: $BACKUP_DIR"
    else
        info "No existing config found at $HYPR_DIR"
    fi

    # Ensure parent dir exists
    mkdir -p "$HOME/.config"

    # ── Step 2: Symlink or Copy ───────────────────────────────────────────────
    if [[ "$USE_COPY" == true ]]; then
        info "Copying files to $HYPR_DIR ..."
        cp -r "$REPO_DIR" "$HYPR_DIR"
        ok "Files copied."
    else
        info "Creating symlink: $HYPR_DIR → $REPO_DIR"
        ln -sf "$REPO_DIR" "$HYPR_DIR"
        ok "Symlink created."
    fi
fi

# ── Step 2.5: Generate monitors.conf if missing ─────────────────────────────
if [[ ! -f "$HYPR_DIR/monitors.conf" ]]; then
    info "Creating default monitors.conf (auto-detect all monitors) ..."
    cp "$HYPR_DIR/monitors.conf.example" "$HYPR_DIR/monitors.conf"
    ok "monitors.conf created. Edit it to match your setup."
    warn "Tip: use 'hyprctl monitors all' or monique to configure your monitors."
else
    ok "monitors.conf already exists, skipping."
fi

# ── Step 3: Script permissions ───────────────────────────────────────────────
info "Setting executable permissions on scripts ..."
chmod +x "$HYPR_DIR"/waybar/scripts/*.sh
chmod +x "$HYPR_DIR"/rofi/scripts/*.sh
ok "Permissions set."

# ── Step 4: Disable swaync systemd service ───────────────────────────────────
info "Disabling swaync systemd user service (autostart handles it) ..."
if systemctl --user is-enabled swaync.service &>/dev/null; then
    systemctl --user disable swaync.service
    ok "swaync.service disabled."
else
    ok "swaync.service already disabled (or not installed)."
fi

# ── Step 5: Ollama ────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}── Optional: Local AI (Ollama) ──────────────────────────────────────${NC}"
if command -v ollama &>/dev/null; then
    read -rp "$(echo -e "${YELLOW}Enable Ollama service and pull gemma3:1b model? [Y/n] ${NC}")" PULL_OLLAMA
    if [[ "${PULL_OLLAMA,,}" != "n" ]]; then
        info "Enabling ollama service ..."
        systemctl enable --now ollama
        info "Pulling gemma3:1b model (this may take a while) ..."
        ollama pull gemma3:1b
        ok "Ollama ready."
    else
        info "Skipping Ollama setup. Run manually: systemctl enable --now ollama && ollama pull gemma3:1b"
    fi
else
    warn "Ollama not installed. Install it with: paru -S ollama"
fi

# ── Step 6: Greetd login screen ───────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}── Optional: Greetd Login Screen ────────────────────────────────────${NC}"
if command -v greetd &>/dev/null || command -v tuigreet &>/dev/null; then
    read -rp "$(echo -e "${YELLOW}Configure greetd + tuigreet as login manager? [y/N] ${NC}")" SETUP_GREETD
    if [[ "${SETUP_GREETD,,}" == "y" ]]; then
        GREETD_CFG="/etc/greetd/config.toml"
        GREETD_BACKUP="/etc/greetd/config.toml.backup.$(date +%Y%m%d_%H%M%S)"

        if [[ -f "$GREETD_CFG" ]]; then
            info "Backing up existing greetd config to $GREETD_BACKUP ..."
            sudo cp "$GREETD_CFG" "$GREETD_BACKUP"
        fi

        info "Writing new greetd config ..."
        sudo tee "$GREETD_CFG" > /dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --cmd start-hyprland --theme 'border=green;text=green;prompt=green;input=green;action=green;button=green;title=green'"
user = "greeter"
EOF

        info "Adding greeter user to video and render groups ..."
        sudo gpasswd -a greeter video
        sudo gpasswd -a greeter render

        info "Disabling sddm ..."
        sudo systemctl disable sddm

        info "Enabling greetd ..."
        sudo systemctl enable greetd
        ok "Greetd enabled. Will be used on next boot."
    else
        info "Skipping greetd setup. See INSTALLATION.md for manual steps."
    fi
else
    warn "greetd/tuigreet not installed. Install with: paru -S greetd greetd-tuigreet"
fi

# ── Step 7: NetworkManager ────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}── Optional: NetworkManager ─────────────────────────────────────────${NC}"
if ! systemctl is-enabled NetworkManager &>/dev/null; then
    read -rp "$(echo -e "${YELLOW}Enable NetworkManager? [y/N] ${NC}")" ENABLE_NM
    if [[ "${ENABLE_NM,,}" == "y" ]]; then
        sudo systemctl enable --now NetworkManager
        ok "NetworkManager enabled."
    fi
else
    ok "NetworkManager already enabled."
fi

# ── Step 8: Bluetooth ─────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}── Optional: Bluetooth ──────────────────────────────────────────────${NC}"
if ! systemctl is-enabled bluetooth &>/dev/null; then
    read -rp "$(echo -e "${YELLOW}Enable Bluetooth service? [y/N] ${NC}")" ENABLE_BT
    if [[ "${ENABLE_BT,,}" == "y" ]]; then
        sudo systemctl enable --now bluetooth
        ok "Bluetooth enabled."
    fi
else
    ok "Bluetooth already enabled."
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  Installation complete. Log out and log back in to apply changes.${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════════${NC}"
echo ""
[[ "$SKIP_LINK" == false && -d "$BACKUP_DIR" ]] && \
    echo -e "  ${YELLOW}Old config backed up at:${NC} $BACKUP_DIR"
echo -e "  ${CYAN}Docs:${NC} $HYPR_DIR/INSTALLATION.md"
echo ""

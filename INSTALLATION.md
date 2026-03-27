# 🛠️ Manual Installation Guide - green-hyprtheme

> **Prefer automation?** Run `./install.sh` from the repo root — it handles backup, symlink, permissions, and optional services interactively.
> This guide is for those who want full manual control over each step.

This guide explains how to manually install the theme and all its dependencies on **Arch Linux**. Following these steps gives you full control over your system.

---

## 📦 1. Dependencies List

```bash
paru -S hyprland hyprlock hypridle hyprpicker \
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
        waybar swaync libnotify \
        rofi rofi-calc gnome-keyring \
        kitty nemo fish starship \
        brave-bin sublime-text-4 \
        ttf-jetbrains-mono-nerd ttf-fira-code-nerd ttf-hack-nerd \
        ttf-font-awesome otf-font-awesome noto-fonts-emoji \
        pipewire pipewire-alsa pipewire-pulse wireplumber \
        pavucontrol pasystray pamixer playerctl \
        bluez bluez-utils blueman \
        networkmanager network-manager-applet nm-connection-editor \
        networkmanager-openvpn iwgtk \
        polkit-kde-agent \
        grim slurp swappy \
        wl-clipboard cliphist \
        brightnessctl \
        swaybg \
        jq curl ipcalc \
        ollama \
        gsimplecal \
        greetd greetd-tuigreet \
        nwg-look qt5ct qt6ct \
        conky mission-center
```

---

## 🗂️ 2. Package Descriptions

### Core & Compositor
- `hyprland` - Wayland tiling compositor
- `hyprlock` - Graphical lock screen coordinated with the theme
- `hypridle` - Daemon for power management (dim, lock, suspend)
- `hyprpicker` - Color picker for Wayland
- `xdg-desktop-portal-hyprland` - Wayland portal for screenshots and screen sharing
- `xdg-desktop-portal-gtk` - GTK portal as fallback

### Status Bar & Launcher
- `waybar` - Configurable status bar (top bar with workspaces, clock, network, etc.)
- `rofi` - Application launcher, WiFi menu, control menu, AI cmd, subnet calculator
- `swaync` - Notification daemon with side panel and custom theme
- `libnotify` - Library for `notify-send`
- `gsimplecal` - Popup calendar (click on the clock in Waybar)

### Terminal & Shell
- `kitty` - Main terminal emulator (GPU-accelerated)
- `fish` - Friendly interactive shell
- `starship` - Customizable cross-shell prompt

### Main Applications
- `nemo` - File manager (Cinnamon), lighter than Dolphin
- `brave-bin` - Browser (can be replaced with `firefox`, `chromium`, etc.)
- `sublime-text-4` - Text/code editor (`subl`)
- `mission-center` - System monitor GUI (CPU, RAM, GPU usage)

### Fonts & Icons
- `ttf-jetbrains-mono-nerd` - Theme's main font
- `ttf-fira-code-nerd` - Alternative Nerd Font
- `ttf-hack-nerd` - Alternative Nerd Font
- `ttf-font-awesome` / `otf-font-awesome` - Font Awesome icons
- `noto-fonts-emoji` - Emoji

### Audio
- `pipewire`, `pipewire-alsa`, `pipewire-pulse`, `wireplumber` - Modern audio stack
- `pavucontrol` - PulseAudio/PipeWire GUI volume control
- `pasystray` - Tray volume icon
- `pamixer` - CLI for volume (multimedia key bindings)
- `playerctl` - Media player control (Spotify, VLC, browser)

### Bluetooth
- `bluez`, `bluez-utils` - Bluetooth stack
- `blueman` - Graphical Bluetooth applet and manager

### Network & VPN
- `networkmanager` - WiFi/Ethernet network management
- `network-manager-applet` (`nm-applet`) - Network tray icon
- `nm-connection-editor` - Graphical connection editor
- `networkmanager-openvpn` - OpenVPN support
- `iwgtk` - Alternative WiFi GUI (optional)

### Screenshot
- `grim` - Screenshot tool for Wayland
- `slurp` - Screen area selection
- `swappy` - Screenshot annotation editor

### System Utilities
- `wl-clipboard` (`wl-copy`, `wl-paste`) - Wayland clipboard
- `cliphist` - Clipboard history
- `brightnessctl` - Screen brightness control
- `swaybg` - Wallpaper manager (used in autostart)
- `polkit-kde-agent` - Graphical authentication agent (sudo GUI)
- `jq` - JSON parsing (used in waybar and rofi scripts)
- `curl` - HTTP requests (weather from wttr.in, Ollama API)
- `ipcalc` - IPv4 subnet calculator (used in rofi-subnet.sh)

### Local AI
- `ollama` - Runtime for local LLM models
  - Model used: `gemma3:1b` (download with `ollama pull gemma3:1b`)
  - Used by `rofi-ai-cmd.sh` (command generation) and `rofi-subnet.sh` (subnet fallback)

### Login Manager
- `greetd` - Minimalist display manager
- `greetd-tuigreet` - TUI frontend for greetd (green/black minimal style)

### GTK/Qt Theme
- `nwg-look` - GTK theme configuration in Wayland
- `qt5ct`, `qt6ct` - Qt5/Qt6 theme configuration

### Extra (Optional)
- `conky` - System monitor overlay (enabled in autostart, can be disabled for battery saving)

---

## 🖥️ Conky — Network Interface Configuration

The conky overlay (`conky/cyberconky.conf`) monitors three network interfaces hardcoded to the original machine. **You must update them to match your system** or the network section will show no data.

The three interfaces currently configured are:

| Section | Interface | Description |
| :--- | :--- | :--- |
| DOCKING | `eno1` | USB/dock ethernet adapter |
| ETHERNET | `eth0` | Built-in ethernet |
| WIRELESS | `wlan0` | WiFi |

To find your interface names:
```bash
ip link show
```

Then replace them in `conky/cyberconky.conf`:
```bash
# Example: replace eth0 with your ethernet interface
sed -i 's/eth0/your_interface/g' ~/.config/hypr/conky/cyberconky.conf

# Example: replace wlan0 with your wifi interface
sed -i 's/wlan0/your_wifi_interface/g' ~/.config/hypr/conky/cyberconky.conf

# Example: replace the dock interface
sed -i 's/eno1/your_dock_interface/g' ~/.config/hypr/conky/cyberconky.conf
```

> If you don't use a docking station, you can leave `eno1` as-is — conky will simply show no data for that section.

---

## 🚀 3. Manual Configuration

### Clone the repository

**Option A — clone directly to the config dir** (no symlink needed):
```bash
git clone https://github.com/privatefound/my-dotfiles.git ~/.config/hypr
```

**Option B — clone anywhere, then run the installer** (creates a symlink automatically):
```bash
git clone https://github.com/privatefound/my-dotfiles.git ~/green-hyprtheme
cd ~/green-hyprtheme
./install.sh
```

> All paths in the configuration files use `$HOME` or `~`, so they work with any user without modifications.

### Scripts and Permissions
Make all scripts executable:
```bash
chmod +x ~/.config/hypr/waybar/scripts/*.sh
chmod +x ~/.config/hypr/rofi/scripts/*.sh
```

### Swaync - Disable the systemd service
Swaync is launched via `autostart.conf` with the custom config. The systemd service must be disabled to prevent it from starting without the correct parameters:
```bash
systemctl --user disable swaync.service
```

### Ollama - Download the AI model
```bash
systemctl enable --now ollama
ollama pull gemma3:1b
```

### Login Screen Configuration (Greetd + Tuigreet)
1. Edit `/etc/greetd/config.toml`:
```toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --cmd start-hyprland --theme 'border=green;text=green;prompt=green;input=green;action=green;button=green;title=green'"ok 
user = "greeter"
```

> **Note:** Using `start-hyprland` instead of `Hyprland` directly is mandatory.
> The `start-hyprland` script correctly sets environment variables before launching the compositor.

2. Add permissions to the greeter user:
```bash
sudo gpasswd -a greeter video
sudo gpasswd -a greeter render
```

3. Enable the service:
```bash
sudo systemctl disable sddm   # or gdm, lightdm...
sudo systemctl enable greetd
```

---

## 🎨 4. GTK/Qt Theme Application
- Use `nwg-look` to set the GTK theme. The recommended theme is **Adwaita-dark**.
- Use `qt5ct` / `qt6ct` for Qt applications.

---

## 📡 5. Network Fix (Optional)
If you encounter issues with NetworkManager at startup:
```bash
sudo systemctl enable --now NetworkManager
```
The `systemd/NetworkManager-fixed.service` file is available for systems with startup timeouts on some Arch configurations.

---

## 🔊 6. Enable Bluetooth
```bash
sudo systemctl enable --now bluetooth
```

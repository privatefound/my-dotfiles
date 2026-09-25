# Installation guide

`./install.sh` does all of this for you. This page explains each step so you can do it by hand.

## 1. Packages (Arch Linux)

```bash
sudo pacman -S --needed \
  hyprland hyprlock hypridle hyprpicker hyprshutdown xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-utils \
  quickshell qt6-base qt6-declarative qt6-svg qt6-wayland qt6-imageformats qt6-5compat \
  pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol playerctl \
  networkmanager network-manager-applet nm-connection-editor networkmanager-openvpn wireguard-tools \
  bluez bluez-utils blueman upower \
  wl-clipboard cliphist grim slurp swappy brightnessctl libnotify awww curl jq gnome-keyring polkit \
  greetd greetd-tuigreet \
  ttf-jetbrains-mono-nerd adwaita-fonts noto-fonts-emoji ttf-material-symbols-variable git papirus-icon-theme nwg-look qt5ct qt6ct \
  terminology nemo conky mission-center
```

Everything above is in the official repos. Optional: `ollama` (Morpheus AI, official repo), `gnome-network-displays` (screen cast, AUR), `monique` (monitor layout GUI, AUR).
The cursor theme `Breeze_Dark_Lime` is not packaged: install any cursor theme and change `XCURSOR_THEME` in `hyprland.lua`, or it falls back to the default one.

Requirements: **Hyprland ≥ 0.56 (Lua config)** and **Quickshell ≥ 0.3**.

## 2. Config

```bash
mv ~/.config/hypr ~/.config/hypr.backup        # if you have one
ln -s ~/green-hyprtheme ~/.config/hypr          # or clone directly into ~/.config/hypr
ln -sfn ~/.config/hypr/shell ~/.config/quickshell
```

Monitors: copy `monitors.lua.example` to `monitors.lua` and edit it (`hyprctl monitors` lists your outputs),
or use Monique. Without it every monitor uses its preferred mode.

Apps: terminal, file manager, browser and editor are at the top of `hyprland.lua`.
The shell's own preferences (accent color, opacity, clock, terminal, wallpaper folder, AI model…) are in the
settings panel (`SUPER + ,`) and saved to `~/.config/hypr/settings.json`.

## 3. Notifications

The shell *is* the notification server. Stop other daemons so they don't grab `org.freedesktop.Notifications`:

```bash
systemctl --user disable --now swaync.service dunst.service mako.service 2>/dev/null
```

## 4. Lock screen

`hyprlock.conf` (blurred desktop + clock + avatar) and `hypridle.conf`
(dim 2.5 min → lock 5 min → screen off 5.5 min → suspend 10 min) are used automatically.
Caffeine in the bar/control center inhibits all of it.

## 5. Login screen (greetd + tuigreet)

```bash
sudo install -Dm644 ~/.config/hypr/greetd/config.toml /etc/greetd/config.toml
# keep systemd boot messages from drawing over the greeter
sudo install -Dm644 ~/.config/hypr/greetd/greetd-override.conf /etc/systemd/system/greetd.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl disable sddm gdm lightdm 2>/dev/null
sudo systemctl enable greetd
```

## 6. Services

```bash
sudo systemctl enable --now NetworkManager bluetooth
# optional: NetworkManager without conflicts with networkd/dhcpcd
sudo install -Dm644 ~/.config/hypr/systemd/NetworkManager-fixed.service /etc/systemd/system/
```

## 7. Morpheus (local AI)

```bash
sudo systemctl enable --now ollama
ollama pull gemma4:e4b
```

A llama.cpp server on `localhost:8080` (OpenAI API) is detected too. Pick the model from the chat header.

## 8. Clipboard history

Started by Hyprland (`wl-paste --watch cliphist store`). Open it with `SUPER + Z`;
`Delete` removes the selected entry.

## Troubleshooting

- Shell logs: `qs -p ~/.config/hypr/shell log` — restart it with `SUPER + SHIFT + W`.
- Hyprland config check: `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua`.
- Stuck in the resize submap: `hyprctl dispatch 'hl.dsp.submap("reset")'`.

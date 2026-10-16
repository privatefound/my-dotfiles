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
  ttf-jetbrains-mono-nerd adwaita-fonts noto-fonts-emoji ttf-material-symbols-variable git zenity cava papirus-icon-theme nwg-look qt5ct qt6ct \
  terminology nemo mission-center
```

Everything above is in the official repos. Optional: `ollama` (Morpheus AI, official repo), `gnome-network-displays` (screen cast, AUR), `monique` (monitor layout GUI, AUR).
The cursor theme `Breeze_Dark_Lime` is not packaged: install any cursor theme and change `XCURSOR_THEME` in `hyprland.lua`, or it falls back to the default one.

Requirements: **Hyprland ≥ 0.56 (Lua config)** and **Quickshell ≥ 0.3**.

## 2. Config

```bash
mv ~/.config/hypr ~/.config/hypr.backup        # if you have one
ln -s ~/WhiteRabbitShell ~/.config/hypr          # or clone directly into ~/.config/hypr
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

## 9. Ethernet cards and profiles (Control center → Network → Ethernet)

The Ethernet tab shows three fixed slots — **Expansion card 1**, **Expansion card 2** and
**Docking station** — and, on each one, a button for every Ethernet profile that is **not bound
to a specific interface**. Clicking a button runs `nmcli connection up <profile> ifname <card>`,
so the profile goes on exactly that card (click it again, or ✕, to disconnect).
The dot next to the name is solid when the card is plugged into the laptop, hollow when it is not.

### How the cards are recognised: `state/ethernet-cards.json`

USB/Thunderbolt NICs (e.g. Framework expansion cards) get a different interface name in every
port, so the slots are matched by **MAC address**, remembered in
`~/.config/hypr/state/ethernet-cards.json` (personal, not tracked by git):

```json
{
    "map": {
        "aa:bb:cc:00:00:01": "card1",
        "aa:bb:cc:00:00:02": "card2",
        "aa:bb:cc:00:00:03": "dock"
    }
}
```

- The file is **created automatically**: the first Ethernet card seen plugged straight into the
  laptop becomes `card1`, the next new one `card2`. A card behind a USB hub (its USB port has a dot,
  e.g. `7-1.2.1`) is the `dock`. Nothing to do on a fresh install — just plug the cards in.
- Each card keeps its slot in any port.
- **A new card**: it takes `card1`/`card2` if one is free; otherwise it is listed below the slots as
  `Ethernet <name>`, with the same profile buttons. A new card behind a hub (another dock) becomes a
  `dock` too. Two cards for the same slot plugged in at once: the second one is listed below.
- **Replacing a card** (e.g. a broken expansion card): the new MAC finds both slots taken, so put it in
  the old card's place by editing the file (or delete the old card's line and plug the new one in).
- **Swap or renumber**: edit the file (values `card1`, `card2`, `dock`), or delete it and plug the
  cards in again in the order you want. The shell picks the change up on its own.
- Find a card's MAC with `cat /sys/class/net/<interface>/address` (interfaces: `nmcli device`).

### Profiles that appear on every card

A profile shows up as a button when it has **no interface name and no MAC** set. In
`nm-connection-editor` ("Edit profiles" in the panel): Ethernet tab → leave **Device** empty, no MAC.
For static profiles also untick General → **Connect automatically**, so plugging a cable in
picks DHCP and not them.

Applying a profile from the panel also enables `connection.multi-connect multiple` on it the first
time (the graphical editor has no field for it), so the same profile can be active on two cards at
once. The same from the terminal:

```bash
# DHCP, connected automatically when a cable is plugged in
nmcli connection add type ethernet con-name "Ethernet DHCP" ifname "" ipv4.method auto \
    connection.multi-connect multiple connection.autoconnect yes connection.autoconnect-priority 10
# static profile, applied only from the panel (several addresses allowed)
nmcli connection add type ethernet con-name "Config XG" ifname "" ipv4.method manual \
    ipv4.addresses "172.16.16.200/24" ipv4.gateway "172.16.16.16" \
    connection.multi-connect multiple connection.autoconnect no
# unbind an existing profile instead of recreating it
nmcli connection modify "<name>" connection.interface-name "" 802-3-ethernet.mac-address "" \
    connection.multi-connect multiple
```

Profiles bound to a card (e.g. one tied to the dock's MAC) keep working but are not shown as buttons.
An "Ethernet " prefix is dropped from the button label (`Ethernet DHCP` → `DHCP`).

## 10. Moving to a new PC

`install.sh` restores everything in the repo. These live **outside git** — copy them over
(or recreate them) if you want them on the new machine:

| What | Where | Notes |
|---|---|---|
| NetworkManager profiles (DHCP, static ones, VPN, Wi‑Fi) | `/etc/NetworkManager/system-connections/*.nmconnection` | root-only, mode 600: `sudo cp -a` them, then `sudo nmcli connection reload`. Contain Wi‑Fi/VPN passwords — don't put them in git |
| Ethernet slot ↔ card mapping | `~/.config/hypr/state/ethernet-cards.json` | only if you move the same cards; otherwise it is rebuilt by itself |
| Shell settings (accent, opacity, language…) | `~/.config/hypr/settings.json` | |
| Installed plugins and their settings | `~/.config/hypr/plugins/`, `~/.config/hypr/state/` | or reinstall them from Settings → Plugin |
| Monitor layout | `~/.config/hypr/monitors.lua` | see `monitors.lua.example` |

After copying the NetworkManager profiles, check the static ones are still unbound
(`nmcli -f connection.interface-name,802-3-ethernet.mac-address connection show "<name>"` → both empty).

## Troubleshooting

- Shell logs: `qs -p ~/.config/hypr/shell log` — restart it with `SUPER + SHIFT + W`.
- Hyprland config check: `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua`.
- Stuck in the resize submap: `hyprctl dispatch 'hl.dsp.submap("reset")'`.

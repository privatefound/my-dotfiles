# 🐇 WhiteRabbitShell

*Follow the white rabbit.* A **dark, terminal‑green** Hyprland rice with a complete desktop shell written from scratch in
[Quickshell](https://quickshell.org) (QML):
native services instead of polling scripts, animated popouts anchored to the bar, one design system.

> Black `#0a0a0a` · Terminal green `#00ff41` · Material 3 shapes and motion · CRT scanlines (optional)

## ✨ Features

**Shell (Quickshell)**
- **Bar** per monitor: Arch logo/launcher, Morpheus AI, subnet calculator, animated workspaces with app icons,
  window title, clock, media mini-player, CPU/RAM/temp, collapsible tray with **themed menus**,
  caffeine · transparency · cast toggles, network/bluetooth/volume/battery cluster, notifications, power.
- **Control center**: volume / mic / brightness sliders, quick tiles (Wi‑Fi, Bluetooth, DND, caffeine,
  window transparency, mic, cast, screenshot), media card, battery.
  - **Network**: Wi‑Fi (scan, connect, inline password, forget) · Ethernet (interfaces with default route,
    connect/disconnect, wired profiles up/down) · **VPN** (NetworkManager VPN & WireGuard toggles)
  - **Bluetooth**: power, scan, pair, connect, forget, device battery
  - **Audio**: 0–150 % boost, presets, output/input selection, per‑app volume
- **Media panel** (click the mini-player): blurred album art, live **audio spectrum** (cava, with a PipeWire
  fallback), player / output switching and volume.
- **Launcher** (spotlight): fuzzy app search ranked by usage, `=` calculator, `>` run command,
  `?` ask Morpheus, **clipboard history** with image previews (cliphist), **quick commands**.
- **Notifications**: built‑in server (replaces swaync) — popups with actions and timeout bar,
  grouped notification center, Do Not Disturb, sound.
- **Session menu** (lock, suspend, hibernate, logout, reboot, shutdown — with confirmation),
  **wallpaper picker** (awww transitions), **settings panel** (accent colors, bar opacity with panels that can
  follow it, window opacity, animations, bar, clock, language: auto / Italiano / English…),
  **OSD** for volume/brightness, **polkit agent**, **Morpheus** local AI chat (Ollama / llama.cpp),
  **system monitor** (graphs, temps, disks, network, top processes).

Everything talks to the system through Quickshell's native services — PipeWire, NetworkManager,
BlueZ, UPower, MPRIS, StatusNotifier, Hyprland IPC — so it's instant and nothing polls `pamixer`/`nmcli` in a loop.

**Plugins**: the shell natively supports **DankMaterialShell** and **Omarchy** plugins. Browse, install, update,
enable and remove them from **Settings → Plugin** (catalog with search and categories, per‑plugin settings).
Installed plugins live in `~/.config/hypr/plugins/` and are **not tracked by git**.

**Hyprland** (Lua config): 7 window/workspace animation presets (Matrix, Slide, GNOME, Elastic, Glitch, Minimal, Off) with speed control, switchable live from the shell settings, gradient borders, blur behind the shell,
fixed Alt‑Tab / resize submap / per‑window opacity for the Lua API.

**Lock screen**: hyprlock with blurred desktop, clock, avatar and green input.
**Login screen**: greetd + tuigreet in the same palette.

**Battery mode** (`scripts/power-mode.sh`, started by `hyprland.lua`): when you unplug the charger the internal
panel drops to 60Hz and blur and shadows are turned off; plugging back in reloads the config and restores
everything. It also switches the power profile to `power-saver` on battery and `balanced` on AC.

> [!TIP]
> For a proper setup install **power-profiles-daemon** (it provides `powerprofilesctl`, not installed by `install.sh`):
>
> ```bash
> sudo pacman -S power-profiles-daemon
> sudo systemctl enable --now power-profiles-daemon
> ```
>
> Without it battery mode only changes refresh rate and effects. It conflicts with TLP and auto-cpufreq: remove them
> first, and don't let other tools (e.g. Framework Control) set EPP/governor, or they'll override the profile.

## 🚀 Install

```bash
git clone https://github.com/privatefound/my-dotfiles.git ~/WhiteRabbitShell
cd ~/WhiteRabbitShell
./install.sh
```

The installer installs dependencies with pacman (all in the official repos; AUR extras optional), backs up `~/.config/hypr`, links the repo there,
points `~/.config/quickshell` to the shell, disables other notification daemons and optionally sets up
greetd + tuigreet, NetworkManager/Bluetooth, Ollama and VA‑API. Flags: `--copy`, `--no-deps`, `--yes`.

Manual steps and details: **[INSTALLATION.md](./INSTALLATION.md)**.

## ⌨️ Keybindings

| Keys | Action |
|---|---|
| `` ` `` / `SUPER + D` | Launcher |
| `SUPER + Z` | Clipboard history |
| `SUPER + X` | Quick commands |
| `SUPER + A` | Control center |
| `SUPER + N` / `SUPER + SHIFT + N` | Notifications / Do Not Disturb |
| `SUPER + ESC` | Session menu |
| `SUPER + W` | Wallpaper picker |
| `SUPER + I` | Morpheus AI chat |
| `SUPER + ,` | Shell settings |
| `SUPER + SHIFT + W` | Restart the shell |
| `SUPER + T` / `E` / `SHIFT+B` / `SHIFT+C` | Terminal / files / browser / editor |
| `SUPER + K` / `V` / `F` / `SHIFT+F` / `P` | Close / float / maximize / fullscreen / pin |
| `SUPER + O` | Toggle opacity of the active window |
| `SUPER + R` | Resize mode (arrows / HJKL, `Esc` to exit) |
| `SUPER + M` / `SHIFT+M` | Master / dwindle layout |
| `SUPER + 1‑0` / `SHIFT+1‑0` | Workspace / move window |
| `SUPER + S` / `SHIFT+S` | Scratchpad |
| `ALT + TAB` | Cycle windows |
| `SUPER + CTRL + L` | Lock |
| `F1` / `Print` / `SHIFT + Print` | Screenshot area / area / screen |
| `SUPER + SHIFT + P` | Color picker |

**Bar mouse actions** — logo: launcher (right: session) · ✦: AI chat (right: clear) · volume: wheel to change,
right click pavucontrol, middle mute · network: right click connection editor · cast: left
gnome-network-displays, right monique · bell: right click Do Not Disturb · sysmon: right click Mission Center.

## 📂 Structure

```
~/.config/hypr
├── hyprland.lua           Hyprland (Lua)
├── monitors.lua.example   copy to monitors.lua (or let Monique generate it) — not tracked
├── hypridle.conf  hyprlock.conf
├── greetd/config.toml     login screen
├── conky/  wallpapers/  systemd/
├── animations/            window/workspace animation presets
├── scripts/               restart-shell.sh (SUPER+SHIFT+W) · power-mode.sh (battery mode) · plugin helper commands
└── shell/                 Quickshell
    ├── shell.qml
    ├── config/            Theme · Settings · Icons
    ├── components/        buttons, sliders, toggles, text fields, graphs…
    ├── services/          Audio · Network · Bt · Power · Notifs · Media · SysStats · Ai · Apps · Clipboard…
    ├── modules/           bar · popouts · launcher · session · wallpaper · settings · notifications · osd · polkit
    ├── DankCommon/ Common/ Services/ Widgets/ Modules/ Ui/ Commons/   plugin support
    └── assets/            icons (Inkscape) and notification sound
```

User state lives outside git: `settings.json` (written by the settings panel) and `state/`.

## 🔧 IPC

```bash
qs -p ~/.config/hypr/shell ipc show
qs -p ~/.config/hypr/shell ipc call shell launcher
qs -p ~/.config/hypr/shell ipc call shell network vpn
qs -p ~/.config/hypr/shell ipc call wallpaper set ~/Pictures/wall.jpg
```

## 📄 License

MIT — see [LICENSE](./LICENSE).

Third‑party code bundled for plugin support keeps its own MIT license file in its folder.

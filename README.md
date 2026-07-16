# 💻 green-hyprtheme - Hyprland Config

A **Dark Minimal** theme for Hyprland. Deep black, neon green, and an essential aesthetic.

![Preview](preview.png)

![Preview2](preview_lock.png)

## ✨ Features

- 🎨 **Minimal Theme**: Black (#0a0a0a) + Terminal Green (#00ff41)
- ⚡ **Lightweight and minimal**: Only the essentials, perfect for performance
- 🔒 **Integrated lock screen**: Hyprlock with coordinated style
- 📱 **Login screen**: Greetd with Tuigreet (green/black style)
- 🎯 **QuickShell Bar**: Custom QML status bar (Waybar config included as alternative)
- 🚀 **Rofi**: Application launcher + WiFi menu, controls, subnet calculator, AI commands
- 🤖 **Local AI**: Ollama integrated for command generation and network calculations
- ⌨️ **Keybindings**: Intuitive shortcuts, Vim-style and multimedia keys
- 🔊 **Full audio**: PipeWire + Pavucontrol + hardware controls
- 📶 **Network configured**: NetworkManager with WiFi menu via Rofi

---

## 🚀 Installation

> [!CAUTION]
> I use [monique](https://github.com/ToRvaLDz/monique) for managing my monitors.


### Automatic (recommended)

Clone the repo and run the installer:

```bash
git clone https://github.com/privatefound/my-dotfiles.git ~/green-hyprtheme
cd ~/green-hyprtheme
./install.sh
```

The script will:
- Back up any existing `~/.config/hypr/` config
- Create a symlink `~/.config/hypr → <repo>` (or copy with `--copy`)
- Generate a default `monitors.conf` if missing (edit it for your setup)
- Set executable permissions on all scripts
- Interactively configure Ollama, greetd, NetworkManager, and Bluetooth

> [!NOTE]
> `monitors.conf` is machine-specific and not tracked by git. After install, edit it to match your monitor setup. See `monitors.conf.example` for reference.

### Manual

For full control over each step, follow the detailed guide:
👉 **[INSTALLATION.md](./INSTALLATION.md)**

---

## 📂 Folder Structure

```text
~/.config/hypr/
├── install.sh                  # 🚀 Automatic installer
├── INSTALLATION.md             # 🛠️ Manual installation guide
├── README.md                   # 📖 This documentation
├── README-THEME.md             # 🎨 Login/Lock screen details
├── hyprland.conf               # ⚙️ Core configuration
├── variables.conf              # 📋 Variables and apps (terminal, browser, editor...)
├── look.conf                   # 💅 Aesthetics and animations
├── keybindings.conf            # ⌨️ Keyboard shortcuts
├── monitors.conf               # 🖥️ Monitors and resolutions (not tracked, see .example)
├── monitors.conf.example       # 🖥️ Example monitor config
├── autostart.conf              # ⏯️ Programs at startup
├── windows.conf                # 🪟 Window rules
├── workspaces.conf             # 🗂️ Workspace configuration
├── permissions.conf            # 🔐 Hyprland permissions
├── hypridle.conf               # 💤 Power management (dim/lock/suspend)
├── hyprlock.conf               # 🔒 Lock screen
├── quickshell/                 # 📊 QuickShell status bar (QML)
│   ├── shell.qml               #    Main entry point
│   ├── Bar.qml                 #    Bar layout
│   ├── Clock.qml               #    Clock widget
│   ├── GemmaChat.qml           #    Gemma AI chat
│   ├── Workspaces.qml          #    Workspace indicators
│   ├── Network.qml             #    Network status
│   ├── Volume.qml              #    Volume control
│   ├── Battery.qml             #    Battery indicator
│   ├── CpuRam.qml              #    CPU/RAM monitor
│   ├── Notifications.qml       #    Notification widget
│   └── PowerMenu.qml           #    Power menu
├── waybar/                     # 📊 Waybar (alternative status bar)
│   ├── config                  #    Modules and layout
│   ├── style.css               #    CSS style
│   └── scripts/
│       ├── waybar-helper.sh    #    Weather (wttr.in) and connection status
│       ├── waybar-network-ip.sh #   Network IP display
│       └── waybar-notifications.sh # Notification count for swaync
├── rofi/                       # 🚀 Launcher and menus
│   ├── config.rasi             #    Main config
│   ├── theme.rasi              #    Graphical theme
│   └── scripts/
│       ├── rofi-wifi.sh        #    WiFi menu with nmcli
│       ├── rofi-control.sh     #    Volume, brightness, power menu, app install
│       └── rofi-subnet.sh      #    IPv4 subnet calculator (ipcalc / Ollama)
├── swaync/                     # 🔔 Notifications
│   ├── config.json             #    Panel configuration
│   └── style.css               #    CSS style
├── conky/                      # 📟 System monitor overlay
│   ├── cyberconky.conf         #    Cyber theme config
│   └── fonts/                  #    Dedicated fonts (Roboto Mono Nerd Font)
├── wallpaper/                  # 🎨 Theme wallpapers
└── systemd/                    # 🛠️ Custom systemd services
```

---

## ⌨️ Main Keybindings

| Key | Action |
| :--- | :--- |
| `` ` `` (Backtick) | Open App Launcher (Rofi) |
| `Super + T` | Open Terminal (Kitty) |
| `Super + E` | Open File Manager (Nemo) |
| `Super + Shift + B` | Open Browser (Brave) |
| `Super + Shift + C` | Open Editor (Sublime Text) |
| `Super + K` | Close Window |
| `Super + X` | Shutdown menu / Exit Hyprland |
| `Super + V` | Floating Mode |
| `Super + F` | Fullscreen |
| `Super + Ctrl + L` | Lock Screen (Hyprlock) |
| `Super + S` | Scratchpad (hidden workspace) |
| `F1` | Area screenshot (grim + slurp + swappy) |
| `XF86AudioRaiseVolume` | Volume Up |
| `XF86AudioLowerVolume` | Volume Down |
| `XF86AudioMute` | Mute Audio |
| `XF86MonBrightnessUp/Down` | Brightness Up/Down |
| `XF86AudioNext/Prev/Play` | Media controls (playerctl) |
| `Alt + Tab` | Next window |

*See `keybindings.conf` for the full list.*

---

## 🌐 Browser Hardware Acceleration & WebGL (Nvidia + Wayland)

If you are using an Nvidia GPU under Wayland/Hyprland, Chromium-based browsers (Brave, Google Chrome, VS Code/Electron) may disable WebGL and hardware acceleration by default.

To fix this, configure the browser flags files:

### Chromium / Google Chrome
Add the following flags to `~/.config/chrome-flags.conf`:
```text
--ozone-platform-hint=auto
--enable-gpu-rasterization
--enable-zero-copy
--ignore-gpu-blocklist
--use-gl=angle
--use-angle=gl
--disable-gpu-sandbox
```

### Brave Browser
Add the same flags to `~/.config/brave-flags.conf`:
```text
--ozone-platform-hint=auto
--enable-gpu-rasterization
--enable-zero-copy
--ignore-gpu-blocklist
--use-gl=angle
--use-angle=gl
--disable-gpu-sandbox
--disable-frame-rate-limit
--enable-features=AcceleratedVideoDecodeLinuxGL
```

### Firefox
For Firefox, ensure the environment variable `MOZ_ENABLE_WAYLAND=1` is set, then open `about:config` and set:
* `gfx.webrender.all` -> `true`
* `webgl.disabled` -> `false`

---

## 🤖 Local AI (Ollama)

This config integrates **Ollama** for local AI capabilities in multiple places:

### Rofi Scripts
- **`rofi-subnet.sh`**: Calculate IPv4 subnet info. Uses `ipcalc` if installed, otherwise queries Ollama as a fallback.

### QuickShell AI Chat (✦)
The status bar includes an integrated **AI Chat** accessible by clicking the ✦ icon (next to the subnet calculator book icon).

| Action | Function |
| :--- | :--- |
| **Left click** on ✦ | Open chat popup |
| **Right click** on ✦ | Clear chat history |

Features:
- 💬 **Interactive chat** with streaming responses
- 📋 **Selectable/copyable** text for easy command copying
- 🔄 **Model selector** dropdown (top-right) - automatically lists all installed Ollama models
- 📝 **Markdown rendering** - code blocks, headers, lists, bold/italic are formatted
- ⌨️ **Enter to send**, Escape to close

### Recommended Model

> [!TIP]
> The recommended model for the AI chat is [gemma4:e2b](https://ollama.com/library/gemma4:e2b-it-q4_K_M) (Q4_K_M quantization).
> It offers the best balance between speed, quality, and VRAM usage for local inference.

```bash
# Install Ollama and pull the recommended model
systemctl enable --now ollama
ollama pull gemma4:e2b-it-q4_K_M
```

You can also use other models like `gemma3:12b`, `llama3.2`, `qwen3`, or `deepseek-r1` - all installed models will appear in the dropdown selector.

---

## 🛠️ Maintenance

If you encounter network issues, the system includes a pre-configured service at `systemd/NetworkManager-fixed.service` to handle startup timeouts on some Arch configurations.

> All paths in the configuration files use `$HOME` or `~` and are portable across any user without modifications.

# Terminal Hacker Theme - Login & Lock Screen

The Terminal Hacker theme includes a coordinated configuration for system login and screen lock, maintaining the minimalist black and terminal green style.

## 📦 Components

- ✅ **Greetd** + **Tuigreet** (CLI-style login screen)
- ✅ **Hyprlock** (graphical lock screen for Hyprland)

## 🎨 Visual Features

| Component | Style | Primary Color |
| :--- | :--- | :--- |
| **Login (Tuigreet)** | Console UI | Terminal Green (#00ff41) |
| **Lock (Hyprlock)** | Minimal Modern | Neon Green / Black |

---

## 🚀 Installation

Follow the full guide: **[INSTALLATION.md](./INSTALLATION.md)**

---

### 1. Lock Screen (Hyprlock)

The configuration is located at `~/.config/hypr/hyprlock.conf`.
To activate it manually:
- Shortcut: `Super + Ctrl + L`
- Command: `hyprlock`

### 2. Login Screen (Greetd / Tuigreet)

The system configuration is located at `/etc/greetd/config.toml`.
The command used to launch the login screen is:

```bash
tuigreet --time --remember --cmd start-hyprland --theme 'border=green;text=green;prompt=green;input=green;action=green;button=green;title=green'
```

#### Restore or Modify
If you want to go back to your previous Display Manager (e.g. GDM):

```bash
sudo systemctl disable greetd
sudo systemctl enable gdm
```

---

## 🛠️ Troubleshooting

- **Black Screen at Login**: Make sure the `greeter` user is in the `video` and `render` groups:
  ```bash
  sudo gpasswd -a greeter video
  sudo gpasswd -a greeter render
  ```
- **Hyprland does not start**: Verify that the `--cmd start-hyprland` command is correct in `/etc/greetd/config.toml`.

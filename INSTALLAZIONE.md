# 🛠️ Guida all'Installazione Manuale - Terminal Hacker Theme

Questa guida spiega come installare manualmente il tema e tutte le sue dipendenze su **Arch Linux**. Seguendo questi passaggi avrai il pieno controllo del tuo sistema.

---

## 📦 1. Lista Dipendenze

`paru -S hyprland hyprlock hyprpaper ttf-jetbrains-mono-nerd ttf-font-awesome otf-font-awesome noto-fonts-emoji hyprpicker xdg-desktop-portal-hyprland waybar wofi dunst libnotify swaybg cliphist kitty fish starship dolphin ttf-jetbrains-mono-nerd ttf-fira-code-nerd ttf-hack-nerd ttf-font-awesome ttf-joypixels pipewire pipewire-alsa swaybg pipewire-pulse wireplumber pavucontrol pasystray bluez bluez-utils blueman networkmanager iwgtk polkit-kde-agent grim slurp swappy wl-clipboard brightnessctl pamixer greetd greetd-tuigreet xdg-desktop-portal-gtk nm-connection-editor network-manager-applet networkmanager-openvpn rofi`

Installa i seguenti pacchetti usando `pacman` (o il tuo AUR helper preferito come `paru`):

### Core & Compositor
- `hyprland` - Compositor Wayland
- `hyprlock` - Lock screen
- `hyprpaper` - Wallpaper utility
- `hyprpicker` - Color picker
- `xdg-desktop-portal-hyprland` - Portal per Wayland

### Barra, Notifiche & UI
- `waybar` - Status bar
- `wofi` - Application launcher
- `rofi` - Application launcher 
- `dunst` - Notification daemon
- `libnotify` - Libreria notifiche
- `swaybg` - Wallpaper fallback
- `cliphist` - Clipboard manager

### Terminale & Shell
- `kitty` - Terminal emulator principale
- `fish` - Friendly interactive shell
- `starship` - Prompt customizzabile
- `dolphin` - File manager (KDE)

### Fonts & Icone (Essenziali per il tema)
- `nerd-fonts-jetbrains-mono` (o `ttf-jetbrains-mono-nerd`)
- `nerd-fonts-fira-code`
- `ttf-hack-nerd`
- `ttf-font-awesome`
- `ttf-joypixels` (Emoji)

### Audio & Bluetooth
- `pipewire`, `pipewire-alsa`, `pipewire-pulse`, `wireplumber`
- `pavucontrol`, `pasystray`
- `bluez`, `bluez-utils`, `blueman`

### Rete & Utility
- `networkmanager`, `network-manager-applet`, `iwgtk`
- `polkit-kde-agent` - Agente autenticazione
- `grim`, `slurp`, `swappy` - Screenshots
- `wl-clipboard` - Clipboard Wayland
- `brightnessctl`, `pamixer` - Controlli hardware

### Login Manager (Hacker Style)
- `greetd`
- `greetd-tuigreet`

---

## 🚀 2. Configurazione Manuale

### Copia dei file
Copia le configurazioni nella tua cartella home:
```bash
cp -r ~/.config/hypr/* ~/.config/hypr/ # (Se già clonato qui)
# Altrimenti clona il repo e copia il contenuto in ~/.config/hypr/
```

### Configurazione Login Screen (Greetd + Tuigreet)
1. Modifica il file `/etc/greetd/config.toml`:
```toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --greeting 'SYSTEM ACCESS REQUIRED' --remember --cmd start-hyprland --theme 'border=green;text=green;prompt=green;input=green;action=green;button=green;title=green'"
user = "greeter"
```

> **Nota:** Usare `start-hyprland` invece di `Hyprland` direttamente è obbligatorio.
> Avviare Hyprland senza lo script wrapper genera l'errore:
> `hyprland has started windows without start-hyprland that is not recommended`
> Lo script `start-hyprland` imposta correttamente le variabili d'ambiente prima di avviare il compositor.

2. Aggiungi i permessi necessari all'utente greeter:
```bash
sudo gpasswd -a greeter video
sudo gpasswd -a greeter render
```

3. Abilita il servizio (disabilitando eventuali altri DM come GDM o SDDM):
```bash
sudo systemctl disable sddm # o gdm, lightdm...
sudo systemctl enable greetd
```

### Script e Permessi
Assicurati che gli script nella cartella `waybar/scripts/` siano eseguibili:
```bash
chmod +x ~/.config/hypr/waybar/scripts/*.sh
```

---

## 🎨 3. Applicazione del Tema GTK/Qt
Usa `nwg-look` per impostare il tema GTK e `qt5ct`/`qt6ct` per le applicazioni Qt. Il tema consigliato è **Adwaita-dark** con icone coerenti.

---

## 📡 4. Fix Rete (Opzionale)
Se riscontri problemi con NetworkManager, assicurati che il servizio sia attivo:
```bash
sudo systemctl enable --now NetworkManager
```

# 🛠️ Guida all'Installazione Manuale - Terminal Hacker Theme

Questa guida spiega come installare manualmente il tema e tutte le sue dipendenze su **Arch Linux**. Seguendo questi passaggi avrai il pieno controllo del tuo sistema.

---

## 📦 1. Lista Dipendenze

```bash
paru -S hyprland hyprlock hypridle hyprpicker \
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
        waybar swaync libnotify \
        rofi rofi-calc \
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

## 🗂️ 2. Descrizione Pacchetti

### Core & Compositor
- `hyprland` - Compositor Wayland tiling
- `hyprlock` - Lock screen grafico coordinato al tema
- `hypridle` - Daemon per la gestione energia (dim, lock, suspend)
- `hyprpicker` - Color picker per Wayland
- `xdg-desktop-portal-hyprland` - Portal Wayland per screenshot e screen sharing
- `xdg-desktop-portal-gtk` - Portal GTK come fallback

### Barra di Stato & Launcher
- `waybar` - Status bar configurabile (top bar con workspace, clock, rete, ecc.)
- `rofi` - Application launcher, wifi menu, menu di controllo, AI cmd, subnet calc
- `swaync` - Notification daemon con pannello laterale e tema custom
- `libnotify` - Libreria per `notify-send`
- `gsimplecal` - Calendario popup (clic sull'orologio in waybar)

### Terminale & Shell
- `kitty` - Terminal emulator principale (GPU-accelerated)
- `fish` - Friendly interactive shell
- `starship` - Prompt cross-shell customizzabile

### Applicazioni Principali
- `nemo` - File manager (Cinnamon), più leggero di Dolphin
- `brave-bin` - Browser (puoi sostituire con `firefox`, `chromium`, ecc.)
- `sublime-text-4` - Editor di testo/codice (`subl`)

### Fonts & Icone
- `ttf-jetbrains-mono-nerd` - Font principale del tema
- `ttf-fira-code-nerd` - Font alternativo Nerd Font
- `ttf-hack-nerd` - Font alternativo Nerd Font
- `ttf-font-awesome` / `otf-font-awesome` - Icone Font Awesome
- `noto-fonts-emoji` - Emoji

### Audio
- `pipewire`, `pipewire-alsa`, `pipewire-pulse`, `wireplumber` - Stack audio moderno
- `pavucontrol` - GUI controllo volume PulseAudio/PipeWire
- `pasystray` - Icona tray volume
- `pamixer` - CLI per volume (keybinding tasti multimediali)
- `playerctl` - Controllo media player (Spotify, VLC, browser)

### Bluetooth
- `bluez`, `bluez-utils` - Stack Bluetooth
- `blueman` - Applet e manager Bluetooth grafico

### Rete & VPN
- `networkmanager` - Gestione reti WiFi/Ethernet
- `network-manager-applet` (`nm-applet`) - Icona tray rete
- `nm-connection-editor` - Editor connessioni grafiche
- `networkmanager-openvpn` - Supporto VPN OpenVPN
- `iwgtk` - GUI alternativa per WiFi (opzionale)

### Screenshot
- `grim` - Screenshot per Wayland
- `slurp` - Selezione area schermo
- `swappy` - Editor annotazioni screenshot

### Utility di Sistema
- `wl-clipboard` (`wl-copy`, `wl-paste`) - Clipboard Wayland
- `cliphist` - Cronologia clipboard
- `brightnessctl` - Controllo luminosità schermo
- `swaybg` - Gestore wallpaper (usato in autostart)
- `polkit-kde-agent` - Agente autenticazione grafica (sudo GUI)
- `jq` - Parsing JSON (usato negli script waybar e rofi)
- `curl` - Richieste HTTP (meteo da wttr.in, API Ollama)
- `ipcalc` - Calcolatore subnet IPv4 (usato in rofi-subnet.sh)

### AI Locale
- `ollama` - Runtime per modelli LLM locali
  - Modello usato: `gemma3:1b` (scaricabile con `ollama pull gemma3:1b`)
  - Usato da `rofi-ai-cmd.sh` (generazione comandi) e `rofi-subnet.sh` (fallback subnet)

### Login Manager
- `greetd` - Display manager minimalista
- `greetd-tuigreet` - Frontend TUI per greetd (stile hacker verde/nero)

### Tema GTK/Qt
- `nwg-look` - Configurazione tema GTK in Wayland
- `qt5ct`, `qt6ct` - Configurazione tema Qt5/Qt6

### Extra (Opzionale)
- `conky` - System monitor overlay (configurato ma disabilitato in autostart)

---

## 🚀 3. Configurazione Manuale

### Clona il repository
```bash
git clone https://github.com/privatefound/terminal-hacker-hyprland-theme.git ~/.config/hypr
```

> Tutti i percorsi nei file di configurazione usano `$HOME` o `~`, quindi funzionano con qualsiasi utente senza modifiche.

### Script e Permessi
Rendi eseguibili tutti gli script:
```bash
chmod +x ~/.config/hypr/waybar/scripts/*.sh
chmod +x ~/.config/hypr/rofi/scripts/*.sh
```

### Swaync - Disabilita il servizio systemd
Swaync viene avviato tramite `autostart.conf` con la config custom. Il servizio systemd va disabilitato per evitare che parta senza i parametri corretti:
```bash
systemctl --user disable swaync.service
```

### Ollama - Scarica il modello AI
```bash
systemctl enable --now ollama
ollama pull gemma3:1b
```

### Configurazione Login Screen (Greetd + Tuigreet)
1. Modifica `/etc/greetd/config.toml`:
```toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --greeting 'SYSTEM ACCESS REQUIRED' --remember --cmd start-hyprland --theme 'border=green;text=green;prompt=green;input=green;action=green;button=green;title=green'"
user = "greeter"
```

> **Nota:** Usare `start-hyprland` invece di `Hyprland` direttamente è obbligatorio.
> Lo script `start-hyprland` imposta correttamente le variabili d'ambiente prima di avviare il compositor.

2. Aggiungi i permessi all'utente greeter:
```bash
sudo gpasswd -a greeter video
sudo gpasswd -a greeter render
```

3. Abilita il servizio:
```bash
sudo systemctl disable sddm   # o gdm, lightdm...
sudo systemctl enable greetd
```

---

## 🎨 4. Applicazione del Tema GTK/Qt
- Usa `nwg-look` per impostare il tema GTK. Il tema consigliato è **Adwaita-dark**.
- Usa `qt5ct` / `qt6ct` per le applicazioni Qt.

---

## 📡 5. Fix Rete (Opzionale)
Se riscontri problemi con NetworkManager all'avvio:
```bash
sudo systemctl enable --now NetworkManager
```
Il file `systemd/NetworkManager-fixed.service` è disponibile per sistemi con timeout all'avvio su alcune configurazioni Arch.

---

## 🔊 6. Abilita Bluetooth
```bash
sudo systemctl enable --now bluetooth
```

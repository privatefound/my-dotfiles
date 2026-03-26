# 💻 Terminal Hacker Theme - Hyprland Config

Un tema **Dark Minimal** per Hyprland, ispirato ai terminali retro e alla cultura hacker. Nero profondo, verde neon e un'estetica essenziale per la massima produttività.

![Preview](preview.png)

## ✨ Caratteristiche

- 🎨 **Tema Hacker**: Nero (#0a0a0a) + Verde terminale (#00ff41)
- ⚡ **Leggero e minimale**: Solo l'essenziale, perfetto per performance
- 🔒 **Lock screen integrato**: Hyprlock con stile coordinato
- 📱 **Login screen**: Greetd con Tuigreet (Hacker Style)
- 🎯 **Waybar configurata**: Status bar con meteo, media player, AI e widget
- 🚀 **Rofi**: Application launcher + menu WiFi, controlli, subnet calc, AI comandi
- 🤖 **AI locale**: Ollama integrato per generazione comandi e calcoli di rete
- ⌨️ **Keybindings**: Scorciatoie intuitive, stile Vim e tasti multimediali
- 🔊 **Audio completo**: PipeWire + Pavucontrol + controlli hardware
- 📶 **Rete configurata**: NetworkManager con WiFi menu via Rofi

---

## 🚀 Installazione Manuale

Per installare il tema e le sue dipendenze, segui la guida dettagliata:
👉 **[INSTALLAZIONE.md](./INSTALLAZIONE.md)**

Questa guida contiene l'elenco completo dei pacchetti necessari e i passaggi manuali per configurare correttamente Hyprland e il login screen.

---

## 📂 Struttura Cartelle

```text
~/.config/hypr/
├── INSTALLAZIONE.md            # 🛠️ Guida installazione manuale
├── README.md                   # 📖 Questa documentazione
├── README-THEME.md             # 🎨 Dettagli su Login/Lock screen
├── hyprland.conf               # ⚙️ Configurazione core
├── variables.conf              # 📋 Variabili e app (terminale, browser, editor...)
├── look.conf                   # 💅 Estetica e animazioni
├── keybindings.conf            # ⌨️ Scorciatoie tastiera
├── monitors.conf               # 🖥️ Monitor e risoluzioni
├── autostart.conf              # ⏯️ Programmi all'avvio
├── windows.conf                # 🪟 Regole finestre
├── workspaces.conf             # 🗂️ Configurazione workspace
├── permissions.conf            # 🔐 Permessi Hyprland
├── hypridle.conf               # 💤 Gestione energia (dim/lock/suspend)
├── hyprlock.conf               # 🔒 Lock screen
├── waybar/                     # 📊 Barra di stato
│   ├── config                  #    Moduli e layout
│   ├── style.css               #    Stile CSS
│   └── scripts/
│       ├── waybar-helper.sh    #    Meteo (wttr.in) e stato connessione
├── rofi/                       # 🚀 Launcher e menu
│   ├── config.rasi             #    Config principale
│   ├── theme.rasi              #    Tema grafico
│   └── scripts/
│       ├── rofi-wifi.sh        #    Menu WiFi con nmcli
│       ├── rofi-control.sh     #    Volume, luminosità, power menu, install app
│       ├── rofi-ai-cmd.sh      #    Genera comandi Linux via Ollama AI
│       └── rofi-subnet.sh      #    Calcolatore subnet IPv4 (ipcalc / Ollama)
├── swaync/                     # 🔔 Notifiche
│   ├── config.json             #    Configurazione pannello
│   └── style.css               #    Stile CSS
├── conky/                      # 📟 System monitor overlay (opzionale)
│   ├── cyberconky.conf         #    Config tema cyber
│   └── fonts/                  #    Font dedicati (Roboto Mono Nerd Font)
├── wallpaper/                  # 🎨 Sfondi tema
└── systemd/                    # 🛠️ Servizi systemd custom
```

---

## ⌨️ Scorciatoie Principali

| Tasto | Azione |
| :--- | :--- |
| `` ` `` (Backtick) | Apri App Launcher (Rofi) |
| `Super + T` | Apri Terminale (Kitty) |
| `Super + E` | Apri File Manager (Nemo) |
| `Super + Shift + B` | Apri Browser (Brave) |
| `Super + Shift + C` | Apri Editor (Sublime Text) |
| `Super + K` | Chiudi Finestra |
| `Super + X` | Menu spegnimento / Esci da Hyprland |
| `Super + V` | Floating Mode |
| `Super + F` | Fullscreen |
| `Super + Ctrl + L` | Blocca Schermo (Hyprlock) |
| `Super + S` | Scratchpad (workspace nascosto) |
| `F1` | Screenshot area (grim + slurp + swappy) |
| `XF86AudioRaiseVolume` | Volume Su |
| `XF86AudioLowerVolume` | Volume Giù |
| `XF86AudioMute` | Muta Audio |
| `XF86MonBrightnessUp/Down` | Luminosità Su/Giù |
| `XF86AudioNext/Prev/Play` | Controlli media (playerctl) |
| `Alt + Tab` | Finestra successiva |

*Consulta `keybindings.conf` per la lista completa.*

---

## 🤖 AI Locale (Ollama)

Due script rofi sfruttano **Ollama** con il modello `gemma3:1b`:

- **`rofi-ai-cmd.sh`**: Descrivi un task in italiano/inglese e ottieni il comando Linux corrispondente, con opzione di copiarlo o eseguirlo in terminale.
- **`rofi-subnet.sh`**: Calcola info subnet IPv4. Usa `ipcalc` se installato, altrimenti interroga Ollama come fallback.

Per abilitare l'AI: `systemctl enable --now ollama && ollama pull gemma3:1b`

---

## 🛠️ Manutenzione

Se riscontri problemi con la rete, il sistema include un servizio pre-configurato in `systemd/NetworkManager-fixed.service` per gestire i timeout all'avvio su alcune configurazioni Arch.

> Tutti i percorsi nei file di configurazione usano `$HOME` o `~` e sono portabili su qualsiasi utente senza modifiche.

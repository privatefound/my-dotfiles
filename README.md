# 💻 Terminal Hacker Theme - Hyprland Config

Un tema **Dark Minimal** per Hyprland, ispirato ai terminali retro e alla cultura hacker. Nero profondo, verde neon e un'estetica essenziale per la massima produttività.

![Preview](wallpaper/wallpaper.jpg)

## ✨ Caratteristiche

- 🎨 **Tema Hacker**: Nero (#0a0a0a) + Verde terminale (#00ff41)
- ⚡ **Leggero e minimale**: Solo l'essenziale, perfetto per performance
- 🔒 **Lock screen integrato**: Hyprlock con stile coordinato
- 📱 **Login screen**: Greetd con Tuigreet (Hacker Style)
- 🎯 **Waybar configurato**: Status bar con icone e widget
- 🚀 **Wofi**: Application launcher stile hacker
- ⌨️ **Keybindings**: Scorciatoie intuitive e produttive
- 🔊 **Audio completo**: PipeWire + Pavucontrol
- 📶 **Rete configurata**: NetworkManager con fix inclusi

---

## 🚀 Installazione Manuale

Per installare il tema e le sue dipendenze, segui la guida dettagliata:
👉 **[INSTALLAZIONE.md](./INSTALLAZIONE.md)**

Questa guida contiene l'elenco completo dei pacchetti necessari e i passaggi manuali per configurare correttamente Hyprland e il login screen.

---

## 📂 Struttura Cartelle

```text
/home/user/.config/hypr/
├── INSTALLAZIONE.md            # 🛠️ Guida installazione manuale
├── README.md                   # 📖 Questa documentazione
├── README-THEME.md             # 🎨 Dettagli su Login/Lock screen
├── hyprland.conf               # ⚙️ Configurazione core
├── variables.conf              # 📋 Variabili e app
├── look.conf                   # 💅 Estetica e animazioni
├── keybindings.conf            # ⌨️ Scorciatoie tastiera
├── monitors.conf               # 🖥️ Monitor e risoluzioni
├── autostart.conf              # ⏯️ Programmi all'avvio
├── hyprlock.conf               # 🔒 Lock screen
├── hyprpaper.conf              # 🖼️ Sfondo
├── waybar/                     # 📊 Barra di stato
├── wallpaper/                  # 🎨 Sfondi tema
└── systemd/                    # 🛠️ Servizi systemd
```

---

## ⌨️ Scorciatoie Principali

| Tasto | Azione |
| :--- | :--- |
| `Super + Q` | Apri Terminale (Kitty) |
| `Super + E` | Apri File Manager (Dolphin) |
| `Super + R` | Apri App Launcher (Wofi) |
| `Super + C` | Chiudi Finestra |
| `Super + M` | Esci da Hyprland |
| `Super + V` | Floating Mode |
| `Super + L` | Blocca Schermo (Hyprlock) |
| `Super + P` | Screenshot |

*Consulta `keybindings.conf` per la lista completa.*

---

## 🛠️ Manutenzione

Se riscontri problemi con la rete, il sistema include un servizio pre-configurato in `systemd/NetworkManager-fixed.service` per gestire i timeout all'avvio su alcune configurazioni Arch.

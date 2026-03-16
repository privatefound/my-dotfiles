# Terminal Hacker Theme - Login & Lock Screen

Il tema Terminal Hacker include una configurazione coordinata per l'accesso al sistema e il blocco dello schermo, mantenendo lo stile minimalista nero e verde terminale.

## 📦 Componenti

- ✅ **Greetd** + **Tuigreet** (login screen CLI-style)
- ✅ **Hyprlock** (lock screen grafico per Hyprland)

## 🎨 Caratteristiche Visive

| Componente | Stile | Colore Primario |
| :--- | :--- | :--- |
| **Login (Tuigreet)** | Console UI | Verde Terminale (#00ff41) |
| **Lock (Hyprlock)** | Minimal Modern | Verde Neon / Nero |

---

## 🚀 Installazione

Puoi installare e configurare entrambi i componenti usando lo script dedicato:

```bash
./install-theme.sh
```

Questo script si occuperà di:
1. Installare `greetd`, `greetd-tuigreet` e `hyprlock` se mancanti.
2. Configurare `tuigreet` con i parametri del tema hacker.
3. Configurare `hyprlock.conf` nella tua cartella home.
4. Impostare `greetd` come Display Manager predefinito (disabilitando GDM/SDDM).

---

### 1. Lock Screen (Hyprlock)

La configurazione si trova in `~/.config/hyprlock/hyprlock.conf`.
Per attivarlo manualmente:
- Scorciatoia: `Super + L` (se configurata in `keybindings.conf`)
- Comando: `hyprlock`

### 2. Login Screen (Greetd / Tuigreet)

La configurazione di sistema si trova in `/etc/greetd/config.toml`.
Il comando usato per lanciare il login screen è:

```bash
tuigreet --time --greet 'SYSTEM ACCESS REQUIRED' --remember --cmd Hyprland --theme 'border=green;text=green;prompt=green;input=green;action=green;button=green;title=green'
```

#### Ripristino o Modifiche
Se desideri tornare al tuo precedente Display Manager (es. GDM):

```bash
sudo systemctl disable greetd
sudo systemctl enable gdm
```

---

## 🛠️ Risoluzione Problemi

- **Schermo Nero al Login**: Assicurati che l'utente `greeter` faccia parte dei gruppi `video` e `render`:
  ```bash
  sudo gpasswd -a greeter video
  sudo gpasswd -a greeter render
  ```
- **Hyprland non si avvia**: Verifica che il comando `--cmd Hyprland` sia corretto in `/etc/greetd/config.toml`.

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

Segui la guida completa: **[INSTALLAZIONE.md](./INSTALLAZIONE.md)**

---

### 1. Lock Screen (Hyprlock)

La configurazione si trova in `~/.config/hypr/hyprlock.conf`.
Per attivarlo manualmente:
- Scorciatoia: `Super + Ctrl + L`
- Comando: `hyprlock`

### 2. Login Screen (Greetd / Tuigreet)

La configurazione di sistema si trova in `/etc/greetd/config.toml`.
Il comando usato per lanciare il login screen è:

```bash
tuigreet --time --greeting 'SYSTEM ACCESS REQUIRED' --remember --cmd start-hyprland --theme 'border=green;text=green;prompt=green;input=green;action=green;button=green;title=green'
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
- **Hyprland non si avvia**: Verifica che il comando `--cmd start-hyprland` sia corretto in `/etc/greetd/config.toml`.

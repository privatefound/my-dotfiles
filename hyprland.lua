-- ═══════════════════════════════════════════════════════════════════════════════
-- HYPRLAND.LUA - Configurazione Principale
-- Tema: Terminal Hacker (Dark Minimal) - Verde terminale (#00ff41)
-- ═══════════════════════════════════════════════════════════════════════════════

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "terminology"
local fileManager = "nemo"
local menu        = "rofi -show drun -config ~/.config/hypr/rofi/config.rasi 2>/dev/null"
local browser     = "brave"
local editor      = "subl"

------------------
---- MONITORS ----
------------------

-- Importa configurazione da Monique
dofile(os.getenv("HOME") .. "/.config/hypr/monitors.lua")

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Cursore
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Breeze_Dark_Lime")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Breeze_Dark_Lime")

-- NVIDIA
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")

-- GTK
hl.env("GTK_THEME", "Adwaita-dark")
hl.env("GTK_USE_PORTAL", "1")

-- Qt
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

-- Electron
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- Ambiente e portali
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("/usr/lib/xdg-desktop-portal-hyprland &")
    hl.exec_cmd("/usr/lib/xdg-desktop-portal &")
    
    -- GNOME Keyring
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    
    -- Polkit Agent
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    
    -- Wallpaper (awww daemon + set)
    hl.exec_cmd("awww-daemon &")
    hl.exec_cmd("sleep 0.5 && awww img ~/.config/hypr/wallpaper/walp3.jpg --transition-type fade --transition-duration 1")
    
    -- Barra di stato (Quickshell)
    hl.exec_cmd("env QT_ICON_THEME=Papirus-Dark quickshell --path $HOME/.config/hypr/quickshell/shell.qml")
    
    -- Applets
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("pasystray")
    hl.exec_cmd("copyq --start-server")
    
    -- Notifiche (SwayNC)
    hl.exec_cmd("swaync -c $HOME/.config/hypr/swaync/config.json -s $HOME/.config/hypr/swaync/style.css")
    hl.exec_cmd("sleep 2 && swaync-client --dnd-off")
    
    -- Hypridle
    hl.exec_cmd("hypridle -c $HOME/.config/hypr/hypridle.conf")
    
    -- Conky
    hl.exec_cmd("conky -c $HOME/.config/hypr/conky/cyberconky.conf &")
    
    -- Mouse cursor
    hl.exec_cmd("hyprctl setcursor Breeze_Dark_Lime 24")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in     = 3,
        gaps_out    = 8,
        border_size = 2,
        
        col = {
            active_border   = { colors = {"rgba(00ff41cc)", "rgba(00cc33cc)", "rgba(006611cc)"}, angle = 45 },
            inactive_border = "rgba(008f11cc)",
        },
        
        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },
    
    decoration = {
        rounding       = 15,
        rounding_power = 2,
        
        active_opacity   = 0.98,
        inactive_opacity = 0.90,
        
        shadow = {
            enabled      = true,
            range        = 20,
            render_power = 3,
            color        = 0x4400ff41,
            color_inactive = 0x22003300,
        },
        
        blur = {
            enabled          = true,
            size             = 4,
            passes           = 2,
            new_optimizations = true,
            ignore_opacity   = false,
            xray             = true,
            contrast         = 1.2,
            brightness       = 1.1,
            noise            = 0.02,
            vibrancy         = 0.3,
        },
    },
    
    animations = {
        enabled = true,
    },
    
    master = {
        allow_small_split    = true,
        special_scale_factor = 0.95,
        mfact                = 0.55,
        new_status           = "slave",
        new_on_top           = false,
        new_on_active        = "none",
        orientation          = "left",
        smart_resizing       = true,
        drop_at_cursor       = true,
    },
    
    dwindle = {
        preserve_split = true,
    },
    
    misc = {
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,
        enable_swallow          = true,
        swallow_regex           = "^(kitty)$",
        force_default_wallpaper = -1,
        disable_hyprland_logo   = true,
    },
    
    input = {
        kb_layout    = "us",
        kb_variant   = "",
        kb_model     = "",
        kb_options   = "",
        kb_rules     = "",
        follow_mouse = 1,
        sensitivity  = 0,
        
        touchpad = {
            natural_scroll = true,
        },
    },
})

-- Gesture
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

--------------------
---- ANIMATIONS ----
--------------------

-- Bezier curves Matrix style
hl.curve("crtFlicker",    { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05}  } })
hl.curve("binaryDrift",   { type = "bezier", points = { {0.22, 1},    {0.36, 1}    } })
hl.curve("mainframeBoot", { type = "bezier", points = { {0.16, 1},    {0.3, 1}     } })
hl.curve("glitchJump",    { type = "bezier", points = { {0.34, 1.56}, {0.64, 1}    } })
hl.curve("dataStream",    { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("neuralLink",    { type = "bezier", points = { {0.45, 0},    {0.55, 1}    } })
hl.curve("sectorScan",    { type = "bezier", points = { {0.0, 0.5},   {0.5, 1.0}   } })
hl.curve("decodingTrace", { type = "bezier", points = { {0.7, 0},     {0.3, 1}     } })
hl.curve("analogSnap",    { type = "bezier", points = { {0.1, 1.05},  {0.2, 1.1}   } })
hl.curve("matrixRain",    { type = "bezier", points = { {0.76, 0},    {0.24, 1}    } })
hl.curve("plasmaFlow",    { type = "bezier", points = { {0.25, 0.46}, {0.45, 0.94} } })

-- Animations
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 5,  bezier = "mainframeBoot", style = "popin 80%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 4,  bezier = "decodingTrace", style = "popin 85%" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 3,  bezier = "glitchJump" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 4,  bezier = "dataStream" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 4,  bezier = "dataStream" })
hl.animation({ leaf = "fadeSwitch",    enabled = true, speed = 6,  bezier = "neuralLink" })
hl.animation({ leaf = "fadeShadow",    enabled = true, speed = 5,  bezier = "binaryDrift" })
hl.animation({ leaf = "fadeDim",       enabled = true, speed = 4,  bezier = "sectorScan" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 6,  bezier = "matrixRain",  style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "analogSnap", style = "slidevert" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 5,  bezier = "plasmaFlow",  style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5,  bezier = "plasmaFlow",  style = "slide" })
hl.animation({ leaf = "borderangle",   enabled = true, speed = 40, bezier = "dataStream" })
hl.animation({ leaf = "border",        enabled = true, speed = 10, bezier = "crtFlicker" })
hl.animation({ leaf = "layers",        enabled = true, speed = 4,  bezier = "binaryDrift", style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 3,  bezier = "mainframeBoot" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 3,  bezier = "decodingTrace" })

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Alt-Tab (cycle windows)
hl.bind("ALT + Tab",         hl.dsp.exec_cmd("hyprctl dispatch cyclenext"))
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("hyprctl dispatch cyclenext prev"))

-- Applicazioni principali
hl.bind(mainMod .. " + T",       hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",       hl.dsp.exec_cmd(fileManager))
hl.bind("grave",                 hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd(editor))
hl.bind(mainMod .. " + Z",       hl.dsp.exec_cmd("copyq show"))
hl.bind(mainMod .. " + W",       hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/wallpaper-selector.sh"))

-- Gestione finestre
hl.bind(mainMod .. " + K", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("hyprctl dispatch toggleopaque"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = 0 }))

-- Cambio layout
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprctl eval 'hl.config({ general = { layout = \"master\" } })'"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("hyprctl eval 'hl.config({ general = { layout = \"dwindle\" } })'"))

-- Focus con frecce
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspace 1-10
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

-- Workspace speciale (Scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll workspace
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Sposta finestre con frecce
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "down" }))

-- Sposta finestre con HJKL
hl.bind(mainMod .. " + CTRL + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + l", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + j", hl.dsp.window.move({ direction = "down" }))

-- Workspace adiacenti
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.move({ workspace = "r+1" }))

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pamixer -t"),   { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("pamixer --default-source -t"), { locked = true })

-- Luminosità
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Media
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Lock screen
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("hyprlock"))

-- Screenshot
hl.bind("F1", hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))

-- Toggle Quickshell
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("killall quickshell; sleep 0.5 && quickshell --path $HOME/.config/hypr/quickshell/shell.qml"))

-- Submap resize (enter submap - bindings defined in submap-resize.conf)
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("hyprctl dispatch submap resize"))

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "conky-desktop",
    match = { class = "^Conky$" },
    float    = true,
    pin      = true,
    no_focus = true,
    opacity  = "1.0 1.0",
})

hl.window_rule({
    name  = "system-applets",
    match = { class = "pavucontrol|blueman-manager|nm-connection-editor" },
    float   = true,
    center  = true,
    size    = { 600, 400 },
    opacity = "0.9 0.8",
})

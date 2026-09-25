-- ═══════════════════════════════════════════════════════════════════════════════
-- HYPRLAND.LUA — green-hyprtheme v2 (shell Quickshell "greenshell")
-- Tema: Terminal Hacker (Dark Minimal) — verde terminale (#00ff41)
-- ═══════════════════════════════════════════════════════════════════════════════

local HOME   = os.getenv("HOME")
local CONF   = HOME .. "/.config/hypr"
local SHELL  = CONF .. "/shell"

-- Legge un valore da settings.json (scritto dal pannello Impostazioni della shell)
local function setting(key, default)
    local f = io.open(CONF .. "/settings.json", "r")
    if not f then return default end
    local content = f:read("*a")
    f:close()
    return content:match('"' .. key .. '"%s*:%s*"([^"]*)"') or content:match('"' .. key .. '"%s*:%s*([%w%.]+)') or default
end

-- Opacità finestre (Impostazioni → Aspetto → Trasparenza finestre)
local transparent   = setting("windowTransparency", "true") ~= "false"
local opacityActive   = transparent and (tonumber(setting("windowOpacityActive", "0.98")) or 0.98) or 1.0
local opacityInactive = transparent and (tonumber(setting("windowOpacityInactive", "0.90")) or 0.90) or 1.0

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "terminology"
local fileManager = "nemo"
local browser     = "brave"
local editor      = "subl"
local qs          = "qs -p " .. SHELL

-- Scorciatoie della shell (Quickshell GlobalShortcut, appid "greenshell")
local function shell(name)
    return hl.dsp.global("greenshell:" .. name)
end

------------------
---- MONITORS ----
------------------

-- monitors.lua è specifico della macchina (generato da Monique, non versionato).
-- Se manca si usa la risoluzione preferita di ogni monitor.
local monitors = CONF .. "/monitors.lua"
local f = io.open(monitors, "r")
if f then
    f:close()
    dofile(monitors)
else
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
end

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- PATH (serve per gli script in ~/.local/bin)
local localBin = HOME .. "/.local/bin"
local curPath = os.getenv("PATH") or "/usr/local/sbin:/usr/local/bin:/usr/bin"
if not string.find(curPath, localBin, 1, true) then
    hl.env("PATH", localBin .. ":" .. curPath)
end

-- Cursore
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Breeze_Dark_Lime")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Breeze_Dark_Lime")

hl.env("XDG_SESSION_TYPE", "wayland")

-- NVIDIA (solo se il driver proprietario è caricato)
local nv = io.open("/proc/driver/nvidia/version", "r")
if nv then
    nv:close()
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("GBM_BACKEND", "nvidia-drm")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("WLR_NO_HARDWARE_CURSORS", "1")
end

-- GTK (niente GTK_THEME: lascia fare a nwg-look)
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

    -- Sfondo: il daemon parte qui, l'immagine la imposta la shell (ricorda l'ultima scelta)
    hl.exec_cmd("awww-daemon")

    -- Shell: barra, popup, notifiche, OSD, launcher, agente polkit
    -- (sostituisce swaync, rofi e polkit-kde)
    hl.exec_cmd(qs)

    -- Agenti di sistema: segreti Wi‑Fi/VPN (nm-applet) e associazione Bluetooth (blueman)
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")

    -- Cronologia appunti (launcher → Appunti, SUPER+Z)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Idle / lock
    hl.exec_cmd("hypridle -c " .. CONF .. "/hypridle.conf")

    -- Conky
    hl.exec_cmd("conky -c " .. CONF .. "/conky/cyberconky.conf")

    -- Cursore
    hl.exec_cmd("hyprctl setcursor Breeze_Dark_Lime 24")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(00ff41ee)", "rgba(00cc33cc)", "rgba(006611cc)" }, angle = 45 },
            inactive_border = "rgba(0b3d16aa)",
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 15,
        rounding_power = 2,

        -- regolabili da Impostazioni → Aspetto (la shell le applica al volo)
        active_opacity   = opacityActive,
        inactive_opacity = opacityInactive,

        shadow = {
            enabled        = true,
            range          = 22,
            render_power   = 3,
            color          = 0x5500ff41,
            color_inactive = 0x22003300,
        },

        blur = {
            enabled           = true,
            size              = 5,
            passes            = 3,
            new_optimizations = true,
            ignore_opacity    = true,
            xray              = false,
            contrast          = 1.1,
            brightness        = 0.9,
            noise             = 0.02,
            vibrancy          = 0.25,
            popups            = true,
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
        swallow_regex           = "^(kitty|terminology)$",
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },

    input = {
        kb_layout     = "us",
        kb_variant    = "",
        kb_model      = "",
        kb_options    = "",
        kb_rules      = "",
        follow_mouse  = 1,
        mouse_refocus = false,
        sensitivity   = 0,

        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
            drag_lock            = false,
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

-- Curve per bordi, ombre e layer (quelle di finestre/workspace sono in animations/init.lua)
hl.curve("crtFlicker",    { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05}  } })
hl.curve("binaryDrift",   { type = "bezier", points = { {0.22, 1},    {0.36, 1}    } })
hl.curve("mainframeBoot", { type = "bezier", points = { {0.16, 1},    {0.3, 1}     } })
hl.curve("dataStream",    { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("neuralLink",    { type = "bezier", points = { {0.45, 0},    {0.55, 1}    } })
hl.curve("sectorScan",    { type = "bezier", points = { {0.0, 0.5},   {0.5, 1.0}   } })
hl.curve("decodingTrace", { type = "bezier", points = { {0.7, 0},     {0.3, 1}     } })
hl.curve("emphasized",    { type = "bezier", points = { {0.05, 0.7},  {0.1, 1}     } })


-- Finestre e workspace: preset scelto dalla shell (Impostazioni → Animazioni).
-- I preset sono in animations/*.lua; la scelta è salvata in settings.json.
dofile(CONF .. "/animations/init.lua").apply(setting("windowAnimations", "matrix"), tonumber(setting("animationSpeed", "1")))

hl.animation({ leaf = "fadeSwitch",       enabled = true, speed = 6,  bezier = "neuralLink" })
hl.animation({ leaf = "fadeShadow",       enabled = true, speed = 5,  bezier = "binaryDrift" })
hl.animation({ leaf = "fadeDim",          enabled = true, speed = 4,  bezier = "sectorScan" })
hl.animation({ leaf = "borderangle",      enabled = true, speed = 40, bezier = "dataStream" })
hl.animation({ leaf = "border",           enabled = true, speed = 10, bezier = "crtFlicker" })
hl.animation({ leaf = "layers",           enabled = true, speed = 4,  bezier = "emphasized",  style = "slide top" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 3,  bezier = "mainframeBoot" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 3,  bezier = "decodingTrace" })

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- ── Shell ──
hl.bind("grave",                        shell("launcher"))
hl.bind(mainMod .. " + D",              shell("launcher"))
hl.bind(mainMod .. " + Z",              shell("clipboard"))
hl.bind(mainMod .. " + X",              shell("commands"))
hl.bind(mainMod .. " + N",              shell("notifications"))
hl.bind(mainMod .. " + SHIFT + N",      shell("dnd"))
hl.bind(mainMod .. " + A",              shell("control"))
hl.bind(mainMod .. " + escape",         shell("session"))
hl.bind(mainMod .. " + W",              shell("wallpaper"))
hl.bind(mainMod .. " + I",              shell("ai"))
hl.bind(mainMod .. " + comma",          shell("settings"))
-- Riavvia la shell (come nella vecchia config): chiude l'istanza e la rilancia
-- (qs kill chiude le istanze avviate sia con il percorso della shell sia con ~/.config/quickshell)
hl.bind(mainMod .. " + SHIFT + W",      hl.dsp.exec_cmd("qs kill -p " .. SHELL .. "; qs kill -p " .. HOME .. "/.config/quickshell; sleep 0.6; " .. qs))

-- ── Alt-Tab (sistemato per la config Lua) ──
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)
hl.bind("ALT + SHIFT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- ── Applicazioni ──
hl.bind(mainMod .. " + T",         hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd(editor))

-- ── Finestre ──
hl.bind(mainMod .. " + K",         hl.dsp.window.close())
hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + P",         hl.dsp.window.pin())
hl.bind(mainMod .. " + J",         hl.dsp.layout("togglesplit"))

-- Opacità della singola finestra (prima era "toggleopaque")
local opaqueWindows = {}
hl.bind(mainMod .. " + O", function()
    local w = hl.get_active_window()
    if not w then return end
    local on = not opaqueWindows[w.address]
    opaqueWindows[w.address] = on
    hl.dispatch(hl.dsp.window.set_prop({ prop = "opaque", value = on and "1" or "0" }))
end)

-- Cambio layout
hl.bind(mainMod .. " + M",         function() hl.config({ general = { layout = "master" } }) end)
hl.bind(mainMod .. " + SHIFT + M", function() hl.config({ general = { layout = "dwindle" } }) end)

-- Focus con frecce
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspace 1-10
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll workspace
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Sposta finestre (frecce e HJKL)
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + CTRL + h",     hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + l",     hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + k",     hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + j",     hl.dsp.window.move({ direction = "down" }))

-- Finestra sul workspace adiacente
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.move({ workspace = "r+1" }))

-- Mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── Tasti multimediali (passano dalla shell → OSD) ──
hl.bind("XF86AudioRaiseVolume",  shell("volumeUp"),       { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  shell("volumeDown"),     { locked = true, repeating = true })
hl.bind("XF86AudioMute",         shell("volumeMute"),     { locked = true })
hl.bind("XF86AudioMicMute",      shell("micMute"),        { locked = true })
hl.bind("XF86MonBrightnessUp",   shell("brightnessUp"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", shell("brightnessDown"), { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- ── Lock / screenshot / colore ──
hl.bind(mainMod .. " + CTRL + L",   hl.dsp.exec_cmd("pidof hyprlock || hyprlock -c " .. CONF .. "/hyprlock.conf"))
local shotArea = 'g=$(slurp) && sleep 0.05 && grim -g "$g" - | swappy -f -'
hl.bind("F1",                       hl.dsp.exec_cmd(shotArea))
hl.bind("Print",                    hl.dsp.exec_cmd(shotArea))
hl.bind("SHIFT + Print",            hl.dsp.exec_cmd("grim - | swappy -f -"))
hl.bind(mainMod .. " + SHIFT + P",  hl.dsp.exec_cmd("hyprpicker -a"))

-- ── Resize (submap nativa Lua: SUPER+R, frecce/HJKL, Esc o Invio per uscire) ──
hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    local step = 20
    local moves = {
        right = {  step, 0 }, left = { -step, 0 }, up = { 0, -step }, down = { 0,  step },
        l     = {  step, 0 }, h    = { -step, 0 }, k  = { 0, -step }, j    = { 0,  step },
    }
    for key, d in pairs(moves) do
        hl.bind(key, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
    end
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)

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
    match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|nwg-look|qt5ct|qt6ct)$" },
    float   = true,
    center  = true,
    size    = { 760, 520 },
})

hl.window_rule({
    name  = "dialogs",
    match = { title = "^(Open File|Save File|Save As|Open Folder|Select a File|Choose Files|File Upload).*" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "swappy",
    match = { class = "^swappy$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "picture-in-picture",
    match = { title = "^(Picture-in-Picture|Picture in picture)$" },
    float = true,
    pin   = true,
    keep_aspect_ratio = true,
})

---------------------
---- LAYER RULES ----
---------------------

-- Blur dietro la shell (le zone trasparenti non vengono sfocate)
hl.layer_rule({ name = "shell-blur", match = { namespace = "^greenshell-(bar|popout|modal|notifications|osd|polkit)$" }, blur = true, ignore_alpha = 0.5 })

-- Popout, modali, notifiche e OSD hanno già le loro animazioni
hl.layer_rule({ name = "shell-noanim", match = { namespace = "^greenshell-(popout|modal|notifications|osd|polkit)$" }, no_anim = true })

-- slurp / hyprpicker: niente animazione, altrimenti il velo della selezione che svanisce
-- finisce dentro lo screenshot (immagini "sbiadite")
hl.layer_rule({ name = "no-anim-selection", match = { namespace = "^(selection|hyprpicker)$" }, no_anim = true })

-- Niente shell nelle condivisioni schermo
hl.layer_rule({ name = "shell-noshare", match = { namespace = "^greenshell-(notifications|polkit)$" }, no_screen_share = true })

-- ═══════════════════════════════════════════════════════════════════
-- Preset di animazione (finestre + workspace), scelti dalla shell:
-- Impostazioni → Aspetto → Animazioni finestre.
--   hyprland.lua li applica all'avvio leggendo settings.json,
--   la shell li riapplica al volo con:  hyprctl eval 'dofile(".../init.lua").apply("slide", 1.0)'
-- Ogni preset è un file <nome>.lua che restituisce function(a) … end,
-- dove a(leaf, durata, curva, stile) crea l'animazione.
-- ═══════════════════════════════════════════════════════════════════

local M = {}
local DIR = os.getenv("HOME") .. "/.config/hypr/animations"

M.presets = { "matrix", "slide", "gnome", "elastic", "glitch", "minimal", "off" }

local springs = {}

local function curves()
    local function bez(name, x1, y1, x2, y2)
        hl.curve(name, { type = "bezier", points = { { x1, y1 }, { x2, y2 } } })
    end
    local function spring(name, stiffness, dampening)
        hl.curve(name, { type = "spring", mass = 1, stiffness = stiffness, dampening = dampening })
        springs[name] = true
    end
    bez("emphasized", 0.05, 0.7, 0.1, 1)
    bez("powerDown", 0.4, 0, 1, 0.6)
    bez("fadeFast", 0.2, 0, 0, 1)
    bez("linear", 0, 0, 1, 1)
    bez("mainframeBoot", 0.16, 1, 0.3, 1)
    bez("decodingTrace", 0.7, 0, 0.3, 1)
    bez("glitchJump", 0.34, 1.56, 0.64, 1)
    bez("matrixRain", 0.76, 0, 0.24, 1)
    bez("plasmaFlow", 0.25, 0.46, 0.45, 0.94)
    bez("analogSnap", 0.1, 1.05, 0.2, 1.1)
    spring("bootSpring", 320, 23)
    spring("glideSpring", 260, 28)
    spring("bounceSpring", 360, 13)
    spring("softSpring", 180, 26)
end

-- speed: moltiplicatore di velocità (2 = due volte più veloce)
function M.apply(name, speed)
    local k = tonumber(speed) or 1
    if k <= 0 then k = 1 end

    local ok, preset = pcall(dofile, DIR .. "/" .. tostring(name) .. ".lua")
    if not ok or type(preset) ~= "function" then
        preset = dofile(DIR .. "/matrix.lua")
    end

    curves()
    local enabled = true
    local function a(leaf, duration, curve, style)
        if leaf == "off" then
            enabled = false
            return
        end
        local spec = { leaf = leaf, enabled = true, speed = duration / k }
        if springs[curve] then spec.spring = curve else spec.bezier = curve end
        if style then spec.style = style end
        hl.animation(spec)
    end
    preset(a)
    hl.config({ animations = { enabled = enabled } })
end

return M

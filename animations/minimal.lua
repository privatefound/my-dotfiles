-- Minimal: solo dissolvenze brevi, niente movimento
return function(a)
    a("windowsIn",        2,   "fadeFast",   "popin 97%")
    a("windowsOut",       1.5, "powerDown",  "popin 97%")
    a("windowsMove",      2.5, "emphasized")
    a("fadeIn",           2,   "fadeFast")
    a("fadeOut",          1.5, "powerDown")
    a("workspaces",       2.5, "fadeFast",   "fade")
    a("workspacesIn",     2.5, "fadeFast",   "fade")
    a("workspacesOut",    2.5, "fadeFast",   "fade")
    a("specialWorkspace", 2.5, "fadeFast",   "fade")
end

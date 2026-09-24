-- Matrix (predefinito): molle reattive, chiusura rapida, workspace a scorrimento
return function(a)
    a("windowsIn",        4,   "bootSpring",  "popin 86%")
    a("windowsOut",       2,   "powerDown",   "popin 90%")
    a("windowsMove",      4,   "glideSpring")
    a("fadeIn",           2.5, "fadeFast")
    a("fadeOut",          1.8, "powerDown")
    a("workspaces",       6,   "matrixRain",  "slide")
    a("workspacesIn",     5,   "plasmaFlow",  "slide")
    a("workspacesOut",    5,   "plasmaFlow",  "slide")
    a("specialWorkspace", 5,   "analogSnap",  "slidevert")
end

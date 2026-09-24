-- GNOME: le finestre si espandono e si ritraggono dal basso, workspace verticali
return function(a)
    a("windowsIn",        4,   "softSpring",  "gnomed")
    a("windowsOut",       2.5, "powerDown",   "gnomed")
    a("windowsMove",      4,   "softSpring")
    a("fadeIn",           3,   "fadeFast")
    a("fadeOut",          2,   "powerDown")
    a("workspaces",       4.5, "emphasized",  "slidevert")
    a("workspacesIn",     4.5, "emphasized",  "slidevert")
    a("workspacesOut",    4.5, "emphasized",  "slidevert")
    a("specialWorkspace", 4,   "emphasized",  "slidefadevert 30%")
end

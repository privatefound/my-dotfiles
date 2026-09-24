-- Slide: le finestre scivolano dal basso, i workspace scorrono con dissolvenza
return function(a)
    a("windowsIn",        4.5, "glideSpring", "slide bottom")
    a("windowsOut",       2.5, "powerDown",   "slide bottom")
    a("windowsMove",      4,   "glideSpring")
    a("fadeIn",           3,   "fadeFast")
    a("fadeOut",          2,   "powerDown")
    a("workspaces",       4,   "emphasized",  "slidefade 20%")
    a("workspacesIn",     4,   "emphasized",  "slidefade 20%")
    a("workspacesOut",    4,   "emphasized",  "slidefade 20%")
    a("specialWorkspace", 4,   "emphasized",  "slidevert")
end

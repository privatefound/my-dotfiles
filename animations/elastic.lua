-- Elastico: rimbalzo evidente, giocoso
return function(a)
    a("windowsIn",        5,   "bounceSpring", "popin 70%")
    a("windowsOut",       2,   "powerDown",    "popin 80%")
    a("windowsMove",      5,   "bounceSpring")
    a("fadeIn",           2.5, "fadeFast")
    a("fadeOut",          1.8, "powerDown")
    a("workspaces",       5,   "bounceSpring", "slide")
    a("workspacesIn",     5,   "bounceSpring", "slide")
    a("workspacesOut",    5,   "bounceSpring", "slide")
    a("specialWorkspace", 5,   "bounceSpring", "slidevert")
end

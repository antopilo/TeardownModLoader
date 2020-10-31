-- This is where you need to include the path to your mods

-- Exemple: #include "mods/myNewMod.lua"

-- Include mods file here
#include "mods/spam.lua"

-- This is called when you enter into a map.
function modloaderinit()
    -- call init function of your mod here
     -- should be: filenameinit()

    spaminit()

    SetString("hud.notification", "modloader initialized")
end

-- This is called every frame.
function modloadertick()
    -- should be: filenametick()

    spamtick()
end

-- This is called every frame when drawing UI.
function modloaderdraw()
    spamdraw()
end
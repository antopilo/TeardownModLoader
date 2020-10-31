-- This is an exemple mod that spams notification in the HUD

-- called at the start of the game
function spaminit()
    -- nothing to initialized here..
end

-- called every frame
function spamtick()
    -- game logic here.
end

-- called when drawing ui(every frame)
function spamdraw()
    -- spam every frame a notification
    SetString("hud.notification", "spam")
end

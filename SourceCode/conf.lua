GameReleased = false -- If the game is ready, set this var on true, it disable all Debug tools.
Debug = true

function love.conf(t)
    t.identity = "Nil" -- Save file directory.
    t.console = not GameReleased

    t.window.title = "Super Mario Bros LOVE2D"
    t.window.icon = nil
    t.window.vsync = 1
end
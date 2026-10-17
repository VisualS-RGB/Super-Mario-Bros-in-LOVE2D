require"src.globals"

function love.resize(x, y) Push:resize(x, y) end -- Resize fixed resolution. 

function love.load()
    SceneManager:Load()
end

function love.update(dt)
    dt = dt * TimeScale -- Set timescale.

    SceneManager:Update(dt)
    Debug:Update()
end

function love.draw()
    Push:start()

    SceneManager:Draw()
    Debug:Draw()

    Push:finish()
end

function love.keypressed(key)
    if key == "f11" then Push:switchFullscreen() end -- Fullscreen.

    SceneManager:KeyPressed(key)
    Debug:ReadPanelInput(key)
end
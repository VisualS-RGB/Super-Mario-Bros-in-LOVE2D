require"src.globals"

function love.resize(x, y) Push:resize(x, y) end -- Resize fixed resolution. 

function love.load()
    SceneManager:Load()
end

function love.update(dt)
    dt = dt * TimeScale -- Set timescale.

    SceneManager:Update(dt)
end

function love.draw()
    Push:start()

    SceneManager:Draw()
    Debug:DrawPanel()

    Push:finish()
end

function love.keypressed(key)
    SceneManager:KeyPressed(key)
    Debug:ReadPanelInput(key)
end
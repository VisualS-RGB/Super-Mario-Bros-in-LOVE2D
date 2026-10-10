local debug = {}

function debug:DrawPanel()
    if GameReleased or not Debug then return end

    local fps = love.timer.getFPS()
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("DEBUG PANEL!", 2, 2)
    love.graphics.print("FPS: " .. tostring(fps), 2, 16)
end

function debug:ReadPanelInput(key)
    if GameReleased then return end

    if key == "tab" then
        Debug = not Debug
    end
end

return debug
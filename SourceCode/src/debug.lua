local debug = {
    debugMenu = false,
    debugConfig = {
        showHitboxes = true,
        vsync = love.window.getVSync() ~= 0
    },

    Colliding = false,
    ColLeft = nil,
    ColRight = nil,
    ColUp = nil,
    ColDown = false,
    playerVel = {x = 0, y = 0}
}

local padding = 2
local textYsize = 12

function debug:DrawPanel()
    if GameReleased or not self.debugMenu then return end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("DEBUG PANEL!", padding, padding + (textYsize * 0))

    -- Left:
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), padding, padding + (textYsize * 1))

    love.graphics.print("PLAYER: ", padding, padding + (textYsize * 3))
    love.graphics.print("Entered: " .. tostring(self.Colliding), padding, padding + (textYsize * 4))
    love.graphics.print("ColLeft: " .. tostring(self.ColLeft), padding, padding + (textYsize * 5))
    love.graphics.print("ColRight: " .. tostring(self.ColRight), padding, padding + (textYsize * 6))
    love.graphics.print("ColUp: " .. tostring(self.ColUp), padding, padding + (textYsize * 7))
    love.graphics.print("ColDown: " .. tostring(self.ColDown), padding, padding + (textYsize * 8))
    love.graphics.print("PyrVel: " .. tostring(self.playerVel.x) .. ", " .. tostring(self.playerVel.y), padding, padding + (textYsize * 9))

    -- Right:
    local collisionText = "SHOW HITBOX: " .. tostring(self.debugConfig.showHitboxes)
    local textWidth = love.graphics.getFont():getWidth(collisionText)
    love.graphics.print(collisionText, Push:getWidth() - textWidth - padding, padding + (textYsize * 1))

    local vsyncText = "VSYNC: " .. tostring(self.debugConfig.vsync)
    local textWidth = love.graphics.getFont():getWidth(vsyncText)
    love.graphics.print(vsyncText, Push:getWidth() - textWidth - padding, padding + (textYsize * 2))
end

function debug:ReadPanelInput(key)
    if GameReleased then return end

    if key == "tab" then self.debugMenu = not self.debugMenu end

    if not self.debugMenu then return end

    if key == "h" then
        self.debugConfig.showHitboxes = not self.debugConfig.showHitboxes
    end

    if key == "v" then
        self.debugConfig.vsync = not self.debugConfig.vsync
        love.window.setVSync(self.debugConfig.vsync)
    end
end

return debug
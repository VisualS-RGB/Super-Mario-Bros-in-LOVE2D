local debug = {
    debugMenu = false,
    debugConfig = {
        showHitboxes = false,
        vsync = love.window.getVSync() ~= 0
    },

    ColLeft = nil,
    ColRight = nil,
    ColUp = nil,
    ColDown = false,
    playerVel = {x = 0, y = 0},

    leftTexts = {},
    rightTexts = {}
}

local padding = 3
local textYsize = 10

function debug:Update()
    if GameReleased or not self.debugMenu then return end

    -- Left column:
    self.leftTexts = {
        "DEBUG PANEL!",
        "FPS: " .. tostring(love.timer.getFPS()),
        "",
        "PLAYER: ",
        "ColLeft: " .. tostring(self.ColLeft),
        "ColRight: " .. tostring(self.ColRight),
        "ColUp: " .. tostring(self.ColUp),
        "ColDown: " .. tostring(self.ColDown),
        "PyrVel: " .. string.format("%.0f", self.playerVel.x) .. ", " .. string.format("%.0f", self.playerVel.y),
    }

    -- Right column:
    self.rightTexts = {
        "",
        "SHOW HITBOX: " .. tostring(self.debugConfig.showHitboxes),
        "VSYNC: " .. tostring(self.debugConfig.vsync)
    }
end

function debug:Draw()
    if GameReleased or not self.debugMenu then return end
   
    love.graphics.setColor(1, 1, 1, 1)

    -- Print data:
    -- Left:
    for i, text in ipairs(self.leftTexts) do
        love.graphics.print(text, padding, padding + textYsize * (i - 1))
    end

    -- Right:
    for i, text in ipairs(self.rightTexts) do
        local textWidth = love.graphics.getFont():getWidth(text)
        love.graphics.print(
            text,
            Push:getWidth() - textWidth - padding,
            padding + textYsize * (i - 1)
        )
    end
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
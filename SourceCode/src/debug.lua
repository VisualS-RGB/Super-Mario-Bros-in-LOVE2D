local debug = {
    debugMenu = true,
    debugConfig = {
        mute = true,
        showHitboxes = false,
        vsync = love.window.getVSync() ~= 0
    },

    leftTexts = {},
    rightTexts = {},

    pyr = {
        vel = {},
        onFloor = {},
        moving = {},
        running = {},
        skidding = {},
        RunAnimSpd = {}
    }
}

local padding = 3
local textYsize = 10

function debug:Load()
    -- Set edfault debug values:
    love.window.setVSync(self.debugConfig.vsync) -- VSync.
    if self.debugConfig.mute then AudioManager:ApplyMasterVolume(0) else AudioManager:ApplyMasterVolume(100) end -- Volume.
end

function debug:Update()
    if GameReleased or not self.debugMenu then return end

    -- Left column:
    self.leftTexts = {
        "DEBUG PANEL!",
        "FPS: " .. tostring(love.timer.getFPS()),
        "",
        "PLAYER: ",
        "XVel: " .. tostring(self.pyr.vel.x),
        "YVel: " .. tostring(self.pyr.vel.y),
        "OnFloor: " .. tostring(self.pyr.onFloor),
        "- Movement -",
        "Moving: " .. tostring(self.pyr.moving),
        "Running: " .. tostring(self.pyr.running),
        "Skidding: " .. tostring(self.pyr.skidding),
        "RunAnimSpd: " .. tostring(self.pyr.RunAnimSpd)
    }

    -- Right column:
    self.rightTexts = {
        "",
        "MUTE: " .. tostring(self.debugConfig.mute),
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

    if key == "m" then
        self.debugConfig.mute = not self.debugConfig.mute
        
        if self.debugConfig.mute then AudioManager:ApplyMasterVolume(0) else AudioManager:ApplyMasterVolume(100) end
    end
end

return debug
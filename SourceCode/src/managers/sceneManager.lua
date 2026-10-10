local scenesPath = "src.scenes."

local sceneManager = {
    scenes = {
        -- Game scenes:
        Level1 = require(scenesPath .. "level1"),
    },
}

sceneManager.sceneSelected = sceneManager.scenes.Level1 -- Starter scene.

function sceneManager:LoadScene(_scene)
    self.sceneSelected = _scene
    love.load()
end

function sceneManager:Load()
    if self.sceneSelected and self.sceneSelected.Load then self.sceneSelected:Load() end
end

function sceneManager:Update(dt)
    if self.sceneSelected and self.sceneSelected.Update then self.sceneSelected:Update(dt) end
end

function sceneManager:Draw()
    -- Draw static BG color:
    love.graphics.setColor(RgbForever.Color(146, 144, 255))
    love.graphics.rectangle("fill", 0, 0, Push:getWidth(), Push:getHeight())

    if self.sceneSelected and self.sceneSelected.Draw then self.sceneSelected:Draw() end
end

function sceneManager:KeyPressed(key)
    if self.sceneSelected and self.sceneSelected.KeyPressed then self.sceneSelected:KeyPressed(key) end
end

return sceneManager
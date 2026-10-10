local Player = require"src.objects.player"

local scene = {}

-- Scene objects
local player = {}
local world = Sti("src/tilemaps/level1-1.lua", nil, 0, -12)

function scene:Load()
    player = Player.new()
end

function scene:Update(dt)
    player:Update(dt)
end

function scene:Draw()
    love.graphics.setColor(1, 1, 1, 1)
    world:draw()
    player:Draw()
end

function scene:KeyPressed(key)
    player:KeyPressed(key)
end

return scene
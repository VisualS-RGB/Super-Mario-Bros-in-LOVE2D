local Player = require"src.objects.player"
local boxCollider = require"src.components.boxCollider"

local scene = {}

-- Scene objects
local player = {}
local world = Sti("src/tilemaps/tilemap-1-1.lua", nil, 0, -12)
local colliders = {}

-- Add collision in the world tilemap blocks:
local layer = world.layers["Undestructable"]
for y = 1, layer.height do
    for x = 1, layer.width do
        if layer.data[y] and layer.data[y][x] then
            local col = boxCollider.new(0, 0)
            col.position = {
                x = (x - 1) * world.tilewidth,
                y = (y - 1) * world.tileheight - 12
            }
            col.size = {x = world.tilewidth, y = world.tileheight}
            table.insert(colliders, col)
        end
    end
end

function scene:Load()
    player = Player.new()
end

function scene:Update(dt)
    player:Update(dt)
    self:ManageColliders()
end

function scene:Draw()
    love.graphics.setColor(1, 1, 1, 1)
    world:draw()
    player:Draw()

    for i, collider in ipairs(colliders) do
        collider:ShowCollider({r = 100, g = 20, b = 250})
    end
end

function scene:KeyPressed(key)
    player:KeyPressed(key)
end

function scene:ManageColliders()
    player.boxCollider:ResetCollisionStates()

    for i, collider in ipairs(colliders) do
        collider:ResetCollisionStates()
        collider:UpdateCollider()

        player.boxCollider:CheckCollision(collider)
    end
end

return scene
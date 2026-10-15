local Player = require"src.objects.player"
local boxCollider = require"src.components.boxCollider"
local Camera = require"lib.camera"

local scene = {}

-- Scene parameters:
local worldOffset = {x = 0, y = -16}

-- Scene objects
local camera = Camera()
local player = {}
local tilemap = Sti("src/tilemaps/tilemap-1-1.lua", nil, worldOffset.x, worldOffset.y)
local worldColliders = {}

function scene:Load()
    player = Player.new()

    -- Get the solids blocks on tileset:
    local solid = {}
    for y = 1, tilemap.height do
        solid[y] = {}
        for x = 1, tilemap.width do
            for _, name in ipairs({"Undestructable", "Destructable", "LuckyBlocks"}) do
                local layer = tilemap.layers[name]

                -- Set if is a neightbour block there:
                if layer.data[y] and layer.data[y][x] then
                    solid[y][x] = true
                end
            end
        end
    end

    -- Add collision to the solid blocks:
    for i, layer in ipairs(tilemap.layers) do
        if layer.name == "BG" then goto dontApplyCollision end

        for y = 1, layer.height do
            for x = 1, layer.width do
                if layer.data[y] and layer.data[y][x] then
                    -- Create a collider for the block:
                    local col = boxCollider.new(0, 0)
                    col.position = {
                        x = (x - 1) * tilemap.tilewidth + worldOffset.x,
                        y = (y - 1) * tilemap.tileheight + worldOffset.y
                    }
                    col.size = {x = tilemap.tilewidth, y = tilemap.tileheight}

                    -- Set if has a neighbor block:
                    col.nLeft = solid[y] and solid[y][x - 1] or false
                    col.nRight = solid[y] and solid[y][x + 1] or false
                    col.nUp = solid[y-1] and solid[y-1][x] or false
                    col.nDown = solid[y+1] and solid[y+1][x] or false

                    table.insert(worldColliders, col)
                end
            end
        end 

        ::dontApplyCollision::
    end

    AudioManager:PlayTheme("mainTheme.ogg")
end

function scene:Update(dt)
    player:Update(dt)
    self:ManageColliders()
    camera:lookAt(player.position.x, 8)
end

function scene:Draw()
    camera:attach()

    love.graphics.setColor(1, 1, 1, 1)
    
    tilemap:drawLayer(tilemap.layers["BG"])
    tilemap:drawLayer(tilemap.layers["Undestructable"])
    tilemap:drawLayer(tilemap.layers["Destructable"])
    tilemap:drawLayer(tilemap.layers["LuckyBlocks"])
    player:Draw()

    for i, collider in ipairs(worldColliders) do
        collider:ShowCollider({r = 100, g = 20, b = 250})
    end

    camera:detach()
end

function scene:KeyPressed(key)
    player:KeyPressed(key)
end

function scene:ManageColliders()
    player.collider:ResetCollisionStates()

    for i, collider in ipairs(worldColliders) do
        collider:ResetCollisionStates()
        collider:UpdateCollider()

        player.collider:CheckCollision(collider)
    end
end

return scene
local Camera = require"lib.camera"
local Button = require"src.objects.button"

local scene = {}

-- Scene parameters:
local worldOffset = {x = 0, y = -16}

-- Scene objects
local camera = Camera()
local tilemap = Sti("src/tilemaps/tilemap-1-1.lua", nil, worldOffset.x, worldOffset.y)
local buttons = {}

function scene:Load()
    buttons = {
        pyr1 = Button.new(
            {x = 25, y = 25},
            "1 player game",
            function() -- event
                SceneManager:LoadScene(SceneManager.scenes.Level1)
            end,
            true
        ),
        pyr2 = Button.new(
            {x = 25, y = 40},
            "2 player game",
            function() -- event
                love.event.quit()
            end,
            false
        ),
    }

    -- Config button input:
    buttons.pyr1.next = buttons.pyr2

    buttons.pyr2.previous = buttons.pyr1
end

function scene:Update(dt)
    camera:lookAt(0, 8)
end

function scene:Draw()
    camera:attach()

    love.graphics.setColor(1, 1, 1, 1)

    tilemap:drawLayer(tilemap.layers["BG"])
    tilemap:drawLayer(tilemap.layers["Undestructable"])
    tilemap:drawLayer(tilemap.layers["Destructable"])
    tilemap:drawLayer(tilemap.layers["LuckyBlocks"])
    tilemap:drawLayer(tilemap.layers["FlagPole"])

    for i, button in pairs(buttons) do
        button:Draw()
    end

    camera:detach()
end

function scene:KeyPressed(key)
    for i, button in pairs(buttons) do
        button:KeyPressed(key)
    end
end

return scene
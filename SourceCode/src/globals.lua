-- Global libraries:
love.graphics.setDefaultFilter("nearest", "nearest") -- Texture filter mode.
Push = require"lib.push" -- Resolution configuration.

-- Setup push:
Push:setupScreen(
    256, 240, -- Fixed resolution.
    1280, 720, -- Real resolution.
    {
        fullscreen = false,
        vsync = true,
        resizable = true
    }
)

Lem = require"lib.lem" -- Event buses.
RgbForever = require"lib.rgbForever" -- Add RBG colors.
Sti = require"lib.sti" -- Compatibility with Tiled tilemaps.

-- Global managers:
SceneManager = require"src.managers.sceneManager"
AudioManager = require"src.managers.audioManager"
Debug = require"src.debug"

-- Global parameters:
TimeScale = 1

MainEventBus = Lem:new()
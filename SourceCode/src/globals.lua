-- Global libraries:
Push = require"lib.push" -- Resolution configuration.
Lem = require"lib.lem" -- Event buses.
RgbForever = require"lib.rgbForever" -- Add RBG colors.
Anim8 = require"lib.anim8" -- Compatibility with SpriteSheets animations.
Sti = require"lib.sti" -- Compatibility with Tiled tilemaps.
Gamera = require"lib.gamera" -- Cameras.

-- Global managers:
SceneManager = require"src.managers.sceneManager"
AudioManager = require"src.managers.audioManager"

love.graphics.setDefaultFilter("nearest", "nearest") -- Texture filter mode.

-- Global parameters:
TimeScale = 1

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

MainEventBus = Lem:new()
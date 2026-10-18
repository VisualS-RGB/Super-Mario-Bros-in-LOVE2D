local player = {}
player.__index = player

local Anim8 = require"lib.anim8"
local BoxCollider = require"src.components.boxCollider"

function player.new()
    local self = setmetatable({}, player)

    -- Components:
    self.position = {x = 2.5 * 16, y = 12 * 16}
    self.velocity = {x = 0, y = 0}
    self.collider = BoxCollider.new(nil, nil, 2)

    -- Input:
    self.input = {
        left = "a", right = "d", up = "w", down = "d",
        action = "k", jump = "l"
    }

    -- States:
    self.onFloor = true
    self.falling = false
    self.rising = false

    self.moving = false
    self.running = false
    self.movAccelerating = false
    self.skidding = false
    self.movMaxSpeed = false
    self.movDirecction = 1

    self.jumped = false
    self.jumpMaxDistance = false

    -- Parameters:
    self.walkAcc = 133.59375 -- Aceleración al caminar en tierra
    self.runAcc = 200.390625 -- Aceleración al correr (con el botón de sprint presionado) en tierra
    self.minWalk = 4.453125 -- Velocidad mínima inicial al empezar a caminar
    self.maxWalk = 93.75 -- Velocidad máxima normal caminando
    self.maxRun = 153.75 -- Velocidad máxima corriendo
    self.releaseDeacc = 182.8125 -- Desaceleración/frenado natural al soltar el pad direccional
    self.skidDeacc = 365.625 -- Desaceleración al girar o derrapar (cambiar de dirección bruscamente)
    self.turnThreshold = 33.75 -- Umbral de velocidad a partir del cual se activa la animación y física de derrape

    self.airSpdThreshold = 108.75 -- Umbral de velocidad horizontal en el aire para determinar el tipo de resistencia
    self.airSlowAcc = 133.59375 -- Aceleración en el aire cuando la velocidad es baja
    self.airFastAcc = 200.390625 -- Aceleración en el aire cuando la velocidad es alta (mayor a maxWalk)
    self.airFastDrag = 3.046875 -- Resistencia/frenado en el aire al ir a alta velocidad y presionar en contra
    self.airSlowDrag = 2.2265625 -- Resistencia/frenado en el aire al ir a baja velocidad y presionar en contra

    self.jumpSpd = 240.0 -- Velocidad de impulso inicial para un salto normal/pequeño
    self.bigJumpSpd = 300.0 -- Velocidad de impulso inicial para un salto largo/rápido (fastest jump)
    self.smallUpDrag = 450.0 -- Resistencia a la subida (gravedad menor) para saltos cortos o baja velocidad
    self.mediumUpDrag = 421.875 -- Resistencia a la subida para saltos a velocidad media
    self.bigUpDrag = 562.5 -- Resistencia a la subida para saltos a máxima velocidad (mantiene el salto más tiempo arriba)
    self.smallGravity = 1575.0 -- Gravedad aplicada al caer o soltar el botón de salto a baja velocidad
    self.mediumGravity = 1350.0 -- Gravedad aplicada a velocidad media
    self.bigGravity = 2025.0 -- Gravedad aplicada al caer a máxima velocidad o soltar el botón corriendo
    self.fastJumpThreshold = 60.0 -- Umbral de velocidad horizontal para clasificar el salto como "rápido"
    self.fastestJumpThreshold = 138.75 -- Umbral de velocidad horizontal para clasificar el salto como "muy rápido" (salto máximo)
    self.maxFall = 240.0 -- Velocidad límite de caída (terminal velocity)

    -- Graphic design:
    self.smallMarioTexture = love.graphics.newImage("assets/textures/smallMario.png")
    self.smallMarioGrid = Anim8.newGrid(16, 16, self.smallMarioTexture:getWidth(), self.smallMarioTexture:getHeight())

    self.animations = {
        idle = Anim8.newAnimation(self.smallMarioGrid("1-1", 1), 1),
        running = Anim8.newAnimation(self.smallMarioGrid("1-3", 2), 0.08),
        jumping = Anim8.newAnimation(self.smallMarioGrid("2-2", 1), 1)
    }
    self.animationPlaying = self.animations.idle
    self.spriteDirecction = 1

    return self
end

function player:Update(dt)
    self:CheckGround()

    self:Movement(dt)

    self:Death()
    self:AnimationController(dt)

    -- Apply impulse:
    self.position.x = self.position.x + self.velocity.x * dt
    self.position.y = self.position.y + self.velocity.y * dt

    self.collider:UpdateCollider(
        {x = self.position.x, y = self.position.y},
        {x = 16, y = 15}
    )

    -- DEBUG PARAMETERS:
    Debug.pyr.vel = self.velocity
    Debug.pyr.moving = self.moving
    Debug.pyr.running = self.running
end

function player:Draw()
    -- Draw animations:
    love.graphics.setColor(1, 1, 1, 1)
    local ox = self.movementDirection == -1 and self.collider.size.x + self.collider.paddingX or 0
    self.animationPlaying:draw(self.smallMarioTexture, self.position.x, self.position.y, 0, self.movementDirection, 1, ox)

    self.collider:ShowCollider({r = 150, g = 20, b = 100}) -- Draw Collider:
end

function player:KeyPressed(key)
end

function player:Movement(dt)
    -- State controller:
    -- Input:
    local isLeft = love.keyboard.isDown(self.input.left)
    local isRight = love.keyboard.isDown(self.input.right)
    local isAction = love.keyboard.isDown(self.input.action)

    if isRight then
        self.movDirecction = 1
    elseif isLeft then
        self.movDirecction = -1
    else 
        if self.velocity.x >= -1 and self.velocity.x <= 1 then
            self.velocity.x = 0
            self.movDirecction = 0
            self.moving = false
        else
            self.velocity.x = self.velocity.x - self.walkAcc * self.movDirecction * dt
        end
    end

    -- Apply starter mov impulse if aren't moving before:
    if not self.moving and self.movDirecction ~= 0 then
        self.velocity.x = self.minWalk * self.movDirecction
        self.moving = true -- Set move state.
    end

    if isAction and self.moving then self.running = true else self.running = false end -- Set running state.

    -- Physics:
    if self.moving then
        if isRight then self.movDirecction = 1
        elseif isLeft then self.movDirecction = -1 end

        if isRight or isLeft then self.velocity.x = self.minWalk * self.movDirecction end
    end
end

function player:Death()
    if self.position.y >= 300 then SceneManager:LoadScene(SceneManager.sceneSelected) end
end

function player:AnimationController(dt)

    if not self.onFloor then
        self.animationPlaying = self.animations.jumping
        goto updateAnimation
    end

    if love.keyboard.isDown(self.input.left) then
        self.animationPlaying = self.animations.running
        self.movementDirection = -1
    elseif love.keyboard.isDown(self.input.right) then 
        self.animationPlaying = self.animations.running
        self.movementDirection = 1
    else self.animationPlaying = self.animations.idle end

    ::updateAnimation::
    self.animationPlaying:update(dt)
end

function player:CheckGround()
    if self.collider.colDown then self.onFloor = true
    else self.onFloor = false end
end

return player
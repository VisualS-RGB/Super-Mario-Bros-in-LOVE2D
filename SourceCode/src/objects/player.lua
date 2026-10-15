local player = {}
player.__index = player

local Anim8 = require"lib.anim8"
local BoxCollider = require"src.components.boxCollider"

function player.new()
    local self = setmetatable({}, player)

    self.position = {x = 2.5 * 16, y = 12 * 16}
    self.velocity = {x = 0, y = 0}
    self.collider = BoxCollider.new(nil, nil, 4)

    -- Parameters:
    -- Gravity:
    self.starterGravityForce = 70
    self.maxGravityForce = 850
    self.gravityAcceleration = 1.1

    -- Jump:
    self.jumpImpulse = 1000
    self.jumpDuration = 0.136
    self.jumpTimer = 0.0
    self.jumping = false

    self.movementSpeed = 117
    self.movementDirection = 1

    -- Animations:
    self.smallMarioTexture = love.graphics.newImage("assets/textures/smallMario.png")
    self.smallMarioGrid = Anim8.newGrid(16, 16, self.smallMarioTexture:getWidth(), self.smallMarioTexture:getHeight())

    self.animations = {
        idle = Anim8.newAnimation(self.smallMarioGrid("1-1", 1), 1) 
    }

    return self
end

function player:Update(dt)
    self:Movement(dt)
    self:Jumping(dt)
    self:Gravity(dt)

    -- Apply impulse:
    self.position.x = self.position.x + self.velocity.x * dt
    self.position.y = self.position.y + self.velocity.y * dt

    self.collider:UpdateCollider(
        {x = self.position.x, y = self.position.y},
        {x = 16, y = 16}
    ) 

    
    Debug.Colliding = self.collider.colliding
    Debug.ColLeft = self.collider.colLeft
    Debug.ColRight = self.collider.colRight
    Debug.ColUp = self.collider.colUp
    Debug.ColDown = self.collider.colDown
    Debug.playerVel = self.velocity
end

function player:Draw()
    -- Draw animations:
    love.graphics.setColor(1, 1, 1, 1)
    local ox = self.movementDirection == -1 and self.collider.size.x + self.collider.paddingX or 0
    self.animations.idle:draw(self.smallMarioTexture, self.position.x, self.position.y, 0, self.movementDirection, 1, ox)

    self.collider:ShowCollider({r = 150, g = 20, b = 100}) -- Draw Collider:
end

function player:KeyPressed(key)
    if key == "space" and self:OnGround() then 
        self.jumping = true
        self.velocity.y = -120
        AudioManager:PlaySfx("jump.ogg", 50)
    end -- Start jump.
end

function player:Movement(dt)
    -- Input:
    if love.keyboard.isDown("left") and not self.collider.colLeft and self.position.x >= 0 then        
        self.velocity.x = -self.movementSpeed
        self.movementDirection = -1
    elseif love.keyboard.isDown("right") and not self.collider.colRight then 
        self.velocity.x = self.movementSpeed
        self.movementDirection = 1
    else 
        self.velocity.x = 0 
    end
end

function player:Gravity(dt)
    if self:OnGround() and self.velocity.y >= 0 then
        self.velocity.y = 0
        self.position.y = self.collider.otherColPos.y - self.collider.size.y + 0.01
        return
    end

    if self.collider.colUp then  -- Colliding with an block, start to fall.
        self.velocity.y = 100 * dt
        self.position.y = self.position.y + 3
    return end

    -- Fall.
    if self.jumping then return end -- Don't apply the gravity if the player are on the air.
    self.velocity.y = self.velocity.y + self.maxGravityForce * dt
end

function player:Jumping(dt)
    if self.collider.colUp then
        self.jumping = false
        return
    end

    if not self.jumping then
        self.jumpTimer = 0 
        if self.velocity.y <= 0 and not love.keyboard.isDown("space") then 
            self.velocity.y = self.velocity.y * 0.7 
        end
        return
    end

    -- Jumping:
    self.velocity.y = self.velocity.y - self.jumpImpulse * dt -- Apply force
    self.jumpTimer = self.jumpTimer + dt -- Timer.

    if self.jumpTimer >= self.jumpDuration or not love.keyboard.isDown("space") then
        self.jumping = false
    end
end

function player:OnGround()
    if self.collider.colDown then return true end
    return false
end

return player
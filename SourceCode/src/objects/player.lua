local player = {}
player.__index = player

function player.new()
    local self = setmetatable({}, player)

    self.position = {x = 100, y = 100}
    self.colliderSize = {x = 16, y = 16}
    self.velocity = {x = 0, y = 0}

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

local groundLimit = 212 -- TEMP GROUND COL FOR THE MARIO PHISICS

function player:Update(dt)
    self:Movement(dt)
    self:Jumping(dt)
    self:Gravity(dt)

    -- Apply impulse:
    self.position.x = self.position.x + self.velocity.x * dt
    self.position.y = self.position.y + self.velocity.y * dt
end

function player:Draw()
    -- Draw animations:
    love.graphics.setColor(1, 1, 1, 1)
    local ox = self.movementDirection == -1 and self.colliderSize.x or 0
    self.animations.idle:draw(self.smallMarioTexture, self.position.x, self.position.y, 0, self.movementDirection, 1, ox)

    -- Draw Collider:
    if Debug == false then return end
    love.graphics.setColor(RgbForever.Color(150, 20, 100, 150))
    love.graphics.rectangle("fill", self.position.x, self.position.y, self.colliderSize.x, self.colliderSize.y)
end

function player:KeyPressed(key)
    if key == "space" and self:OnGround() then self.jumping = true
    self.velocity.y = -120 end -- Start jump.
end

function player:Movement(dt)
    -- Input:
    if love.keyboard.isDown("left") then 
        self.velocity.x = -self.movementSpeed
        self.movementDirection = -1
    elseif 
        love.keyboard.isDown("right") then self.velocity.x = self.movementSpeed
        self.movementDirection = 1
    else self.velocity.x = 0 end
end

function player:Gravity(dt)
    if self:OnGround() and self.velocity.y > 0 then
        self.velocity.y = 0
        self.position.y = groundLimit - self.colliderSize.y + 0.01
        return
    end

    -- Fall.
    if self.jumping then return end -- Don't apply the gravity if th eplayer are on the air.
    self.velocity.y = self.velocity.y + self.maxGravityForce * dt
end

function player:Jumping(dt)
    print(self.jumping)

    if not self.jumping then
        self.jumpTimer = 0 
        if self.velocity.y <= 0 and not love.keyboard.isDown("space") then self.velocity.y = self.velocity.y * 0.7 end
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
    if self.position.y + self.colliderSize.y > groundLimit then return true end
    return false
end

return player
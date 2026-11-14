local player = {}
player.__index = player

local Sign = require"lib.math.sign"
local Clamp = require"lib.math.clamp"
local Anim8 = require"lib.anim8"
local BoxCollider = require"src.components.boxCollider"

function player.new()
    local self = setmetatable({}, player)

    -- Components:
    self.position = {x = 2.5 * 16, y = 12 * 16}
    self.velocity = {x = 0, y = 0}
    self.collider = BoxCollider.new(nil, nil, 4)

    -- Input:
    self.input = {
        left = "z", right = "c", up = "s", down = "x",
        action = "down", jump = "right"
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

    self.jumping = false
    self.fasterAirLimit = false
    self.fasterAirSpd = false
    self.fastJump = false
    self.fastestJump = false
    self.jumped = false

    self.sprintBuffer = 0
    self.sprintBufferAmount = 10

    -- Physics parameters:
    self.walkAcc = 133.59375
    self.runAcc = 200.390625
    self.minWalk = 4.453125
    self.maxWalk = 93.75
    self.maxRun = 153.75
    self.releaseDeacc = 182.8125
    self.skidDeacc = 365.625
    self.turnThreshold = 33.75

    self.airSpdThreshold = 108.75
    self.airSlowAcc = 133.59375
    self.airFastAcc = 200.390625
    self.airFastDrag = 3.046875
    self.airSlowDrag = 2.2265625

    self.jumpSpd = 240.0
    self.bigJumpSpd = 300.0
    self.smallUpDrag = 450.0
    self.mediumUpDrag = 421.875
    self.bigUpDrag = 562.5
    self.smallGravity = 1575.0
    self.mediumGravity = 1350.0
    self.bigGravity = 2025.0
    self.fastJumpThreshold = 60.0
    self.fastestJumpThreshold = 138.75
    self.maxFall = 240.0

    -- Graphic design:
    self.smallMarioTexture = love.graphics.newImage("assets/textures/smallMario.png")
    self.smallMarioGrid = Anim8.newGrid(16, 16, self.smallMarioTexture:getWidth(), self.smallMarioTexture:getHeight())

    self.runAnimSpeed = 1
    self.animations = {
        idle = Anim8.newAnimation(self.smallMarioGrid("1-1", 1), 1),
        running = Anim8.newAnimation(self.smallMarioGrid("1-3", 2), 0.08),
        jumping = Anim8.newAnimation(self.smallMarioGrid("2-2", 1), 1),
        skidding = Anim8.newAnimation(self.smallMarioGrid("3-3", 1), 1),
    }
    self.animationPlaying = self.animations.idle
    self.spriteDirecction = 1

    return self
end

function player:Update(dt)
    self:CheckGround()

    -- Check jump type before player jumps.
    if self.onFloor then
        self.fastestJump = math.abs(self.velocity.x) > self.fastestJumpThreshold
		self.fastJump = math.abs(self.velocity.x) > self.fastJumpThreshold
		self.fasterAirLimit	= math.abs(self.velocity.x) > self.maxWalk
		self.fasterAirSpd = math.abs(self.velocity.x) > self.airSpdThreshold
    end

    self:Gravity(dt)
    self:Jump(dt)
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

    self.jumped = love.keyboard.isDown(self.input.jump) -- Save last jump input.

    -- DEBUG PARAMETERS:
    Debug.pyr.vel = self.velocity
    Debug.pyr.onFloor = self.onFloor
    Debug.pyr.moving = self.moving
    Debug.pyr.running = self.running
    Debug.pyr.skidding = self.skidding
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

function player:Gravity(dt)
    if self.onFloor then
        self.jumping = false
        self.velocity.y = 0
        self.position.y = self.collider.otherColPos.y - self.collider.size.y + 0.1
    else
        if self.velocity.y < 0.0 and love.keyboard.isDown(self.input.jump) then
			if self.fastestJump then
				self.velocity.y = self.velocity.y + self.bigUpDrag * dt
            elseif self.fastJump then
				self.velocity.y = self.velocity.y + self.mediumUpDrag * dt
			else
				self.velocity.y = self.velocity.y + self.smallUpDrag * dt
            end
		else
			if self.fastestJump then
				self.velocity.y = self.velocity.y + self.bigGravity * dt
            elseif self.fastJump then
				self.velocity.y = self.velocity.y + self.mediumGravity * dt
			else
				self.velocity.y = self.velocity.y + self.smallGravity * dt
            end
        end

		-- Limit gravity if it exceeds its limit:
		if self.velocity.y >= self.maxFall then
			self.velocity.y = self.maxFall
        end
    end
end

function player:Jump(dt)
    local isJump = love.keyboard.isDown(self.input.jump)

    -- If player collides with top, starts to fall:
    if self.collider.colUp then
        self.velocity.y = 0
        self.position.y = self.position.y + 1
        return
    end

    -- Jump:
    if self.onFloor and isJump and not self.jumped then
        self.jumping = true
        AudioManager:PlaySfx("jump.ogg", 50)
        if self.fastestJump then self.velocity.y = -self.bigJumpSpd
        else self.velocity.y = -self.jumpSpd end
        self.jumped = false
    end
end

function player:Movement(dt)
    -- State controller:
    -- Input:
    local isAction = love.keyboard.isDown(self.input.action)
    local input = (love.keyboard.isDown(self.input.right) and 1 or 0) - (love.keyboard.isDown(self.input.left) and 1 or 0) -- Get input direction.
    local acc = 0

    if self.collider.colRight then
        if input == 1 or self.velocity.x > 0 then
            self.velocity.x = 0
            return
        end
    end

    if self.collider.colLeft then
        if input == -1 or self.velocity.x < 0 then
            self.velocity.x = 0
            return
        end
    end

    -- Manage if are acctualy running:
    if isAction then
        self.sprintBuffer = self.sprintBufferAmount
        acc = self.runAcc
    else
        if self.sprintBuffer > 0 then self.sprintBuffer = self.sprintBuffer - 1 end
        acc = self.walkAcc
    end

    if self.skidding and self.velocity.x == 0 then self.skidding = false end -- Fix infinite skid state.

    if self.onFloor then
        if math.abs(input) > 0.01 then
            -- Get if mario is skidding:
			self.skidding = Sign(self.velocity.x) ~= input and math.abs(self.velocity.x) > 0.00001

            if self.skidding then
				if math.abs(self.velocity.x) > self.turnThreshold then
					self.velocity.x = self.velocity.x + self.skidDeacc * input * dt
				else
					self.velocity.x = 0.0
                end
			else
				if self.velocity.x == 0 then
					self.velocity.x = self.minWalk * input
				else
					self.velocity.x = self.velocity.x + acc * input * dt
                end
				if math.abs(self.velocity.x) > self.maxWalk and self.sprintBuffer == 0 then
					self.velocity.x = self.maxWalk * input
                elseif math.abs(self.velocity.x) > self.maxRun then
					self.velocity.x = self.maxRun * input     
                end
            end
		else
            local deAcc = self.skidding and self.skidDeacc or self.releaseDeacc

			if math.abs(self.velocity.x) < deAcc * dt then
				self.velocity.x = 0
			else
				self.velocity.x = self.velocity.x - deAcc * Sign(self.velocity.x) * dt
            end
        end
    else
		if math.abs(input) > 0.01 then
			if math.abs(self.velocity.x) >= self.maxWalk then
				self.velocity.x = self.velocity.x + self.airFastAcc * input * dt
			else
				if Sign(self.velocity.x) == input then
					self.velocity.x = self.velocity.x + self.airSlowAcc * input * dt
				else
					self.velocity.x = (self.fasterAirSpd and self.airFastDrag or self.airSlowDrag) * input
                end
            end
        end
        
		if self.fasterAirLimit then
			self.velocity.x = Clamp(self.velocity.x, -self.maxRun, self.maxRun)
		else
			self.velocity.x = Clamp(self.velocity.x, -self.maxWalk, self.maxWalk)
        end
    end
end

function player:Death()
    if self.position.y >= 300 then SceneManager:LoadScene(SceneManager.sceneSelected) end
end

function player:AnimationController(dt)
    -- Movement
    if self.onFloor then
        if love.keyboard.isDown(self.input.left) then self.movementDirection = -1
        elseif love.keyboard.isDown(self.input.right) then self.movementDirection = 1 end
    end

    -- Set Running anim:
    if math.sin(self.velocity.x) ~= 0 then self.animationPlaying = self.animations.running
    else self.animationPlaying = self.animations.idle end

    -- Run anim speed
    if math.abs(self.velocity.x) >= self.maxRun then self.runAnimSpeed = 1.96
    elseif math.abs(self.velocity.x) >= self.maxWalk + 1 then self.runAnimSpeed = 1.62
    else self.runAnimSpeed = 1 end

    if self.skidding then
        self.animationPlaying = self.animations.skidding
    end

    if self.jumping then
        self.animationPlaying = self.animations.jumping
    end

    self.animationPlaying:update(dt * self.runAnimSpeed)
end

function player:CheckGround()
    if self.collider.colDown then self.onFloor = true
    else self.onFloor = false end
end

return player
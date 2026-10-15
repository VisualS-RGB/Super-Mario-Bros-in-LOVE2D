local boxCollider = {}
boxCollider.__index = boxCollider

function boxCollider.new(_position, _size, _paddingX, _paddingY)
    local self = setmetatable({}, boxCollider)

    self.position = _position or {x = 0, y = 0}
    self.size = _size or {x = 0, y = 0}

    self.paddingX = _paddingX
    self.paddingY = _paddingY

    self.colliding = false
    self.colLeft = false
    self.colRight = false
    self.colUp = false
    self.colDown = false

    self.otherColPos = {x = 0, y = 0}
    self.otherColSize = {x = 0, y = 0}

    return self
end

function boxCollider:UpdateCollider(_position, _size)
    -- Apply padding:
    if self.paddingX ~= nil then
        _position.x = _position.x + (self.paddingX / 2)
        _size.x = _size.x - self.paddingX
    end

    if self.paddingY ~= nil then
        _position.y = _position.y + (self.paddingY / 2)
        _size.y = _size.y - self.paddingY
    end

    -- Apply the parameters:
    if _position ~= nil then self.position = _position end
    if _position ~= nil then self.size = _size end
end

function boxCollider:CheckCollision(_other)
    -- Detect if are  collider enter:
    local overlapX = self.position.x < _other.position.x + _other.size.x and self.position.x + self.size.x > _other.position.x
    local overlapY = self.position.y < _other.position.y + _other.size.y and self.position.y + self.size.y > _other.position.y

    if not (overlapX and overlapY) then return end -- Not colliding.

    self.colliding = true
    self.otherColPos = _other.position
    self.otherColSize = _other.size

    local pRight = (self.position.x + self.size.x) - _other.position.x
    local pLeft  = (_other.position.x + _other.size.x) - self.position.x
    local pDown  = (self.position.y + self.size.y) - _other.position.y
    local pUp    = (_other.position.y + _other.size.y) - self.position.y

    -- Disable edge collision if the collision has another collision next to it.
    if _other.nLeft then pRight = math.huge end
    if _other.nRight then pLeft = math.huge end
    if _other.nUp then pDown = math.huge end
    if _other.nDown then pUp = math.huge end

    local min = math.min(pRight, pLeft, pDown, pUp)
    if min == math.huge then return end

    -- Set the border who are colliding:
    if min == pRight then
        self.colRight = true
    elseif min == pLeft then
        self.colLeft = true
    elseif min == pDown then
        self.colDown = true
    else
        self.colUp = true
    end
end

function boxCollider:ResetCollisionStates()
    self.colliding = false
    self.colLeft = false
    self.colRight = false
    self.colUp = false
    self.colDown = false
end

function boxCollider:ShowCollider(_colliderColor, _line, _fill)
    if not Debug.debugMenu then return end
    if not Debug.debugConfig.showHitboxes then return end
    
    love.graphics.setColor(RgbForever.Color(_colliderColor.r, _colliderColor.g, _colliderColor.b, 150))
    if _line then love.graphics.rectangle("line", self.position.x, self.position.y, self.size.x, self.size.y) end
    if _fill or _fill == nil then love.graphics.rectangle("fill", self.position.x, self.position.y, self.size.x, self.size.y) end
end

return boxCollider
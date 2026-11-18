local button = {}
button.__index = button

function button.new(_position, _text, _event, _selected)
    local self = setmetatable({}, button)

    self.position = _position
    self.text = _text
    self.select = _selected and true or false
    self.event = _event

    self.next = nil
    self.previous = nil

    return self
end

function button:KeyPressed(k)
    if not self.select then return end

    if k == "down" and self.next ~= nil then
        self.select = false
        self.next.select = true
    end

    if k == "up" and self.previous ~= nil then
        self.select = false
        self.previous.select = true
    end

    if k == "space" and self.select and self.event ~= nil then self.event() end
end

function button:Draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(self.text, self.position.x, self.position.y)

    if not self.select then return end  
    love.graphics.setColor(1, 0.6, 0, 1)
    love.graphics.rectangle("fill", self.position.x - 13, self.position.y, 10, 10)
end

return button
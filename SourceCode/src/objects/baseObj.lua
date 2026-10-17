local ObjName = {}
ObjName.__index = ObjName

function ObjName.new()
    local self = setmetatable({}, ObjName)

    self.position = {x = 0, y = 0}

    return self
end

return ObjName

-- Soy pepe
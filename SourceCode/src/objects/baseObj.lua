local ObjName = {}
ObjName.__index = ObjName

function ObjName.new()
    local self = setmetatable({}, ObjName)

    return self
end

return ObjName
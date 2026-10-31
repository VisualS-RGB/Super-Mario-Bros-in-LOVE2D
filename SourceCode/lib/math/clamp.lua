local function clamp(x, min, max)
    return math.max(min, math.min(max, x))
end

return clamp
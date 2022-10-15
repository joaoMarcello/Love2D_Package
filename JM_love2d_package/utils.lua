local Utils = {}

---comment
---@param width number|nil
---@param height number|nil
---@param frame_size JM_Point
---@return JM_Point|nil
function Utils:desired_size(width, height, frame_size)
    local dw, dh

    dw = width and width / frame_size.x or nil
    dh = height and height / frame_size.y or nil

    return { x = dw, y = dh }
end

function Utils:desired_duration(duration, amount_steps)
    return duration / amount_steps
end

---@alias JM_Point {x: number, y:number}
--- Table representing a point with x end y coordinates.

---@alias JM_Color {r: number, g: number, b:number, a:number}
--- Represents a color in RGBA space

return Utils

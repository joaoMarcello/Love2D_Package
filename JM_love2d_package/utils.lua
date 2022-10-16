local Utils = {}

---comment
---@param width number|nil
---@param height number|nil
---@param ref_width number|nil
---@param ref_height number|nil
---@return JM.Point|nil
function Utils:desired_size(width, height, ref_width, ref_height, keep_proportions)
    local dw, dh

    dw = width and width / ref_width or nil
    dh = height and height / ref_height or nil

    if keep_proportions then
        if not dw then
            dw = dh
        elseif not dh then
            dh = dw
        end
    end

    return { x = dw, y = dh }
end

function Utils:desired_duration(duration, amount_steps)
    return duration / amount_steps
end

---@alias JM.Point {x: number, y:number}
--- Table representing a point with x end y coordinates.

---@alias JM.Color {r: number, g: number, b:number, a:number}
--- Represents a color in RGBA space

return Utils

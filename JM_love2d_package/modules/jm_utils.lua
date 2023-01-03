local string_format, mfloor, m_min, m_max, colorFromBytes, colorToBytes = string.format, math.floor, math.min, math.max,
    love.math.colorFromBytes, love.math.colorToBytes

---@alias JM.Point {x: number, y:number}
--- Table representing a point with x end y coordinates.

---@alias JM.Color {[1]: number, [2]: number, [3]:number, [4]:number}
--- Represents a color in RGBA space

---@class JM.Utils
local Utils = {}

---@param width number|nil
---@param height number|nil
---@param ref_width number|nil
---@param ref_height number|nil
---@return JM.Point
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

local results_parse = setmetatable({}, { __mode = 'kv' })

function Utils:parse_csv_line(line)
    local result = results_parse[line]
    if result then return result end

    local res = {}
    local pos = 1
    local sep = ','
    while true do
        local c = string.sub(line, pos, pos)
        if (c == "") then break end
        if (c == '"') then
            -- quoted value (ignore separator within)
            local txt = ""
            repeat
                local startp, endp = string.find(line, '^%b""', pos)
                txt = txt .. string.sub(line, startp + 1, endp - 1)
                pos = endp + 1
                c = string.sub(line, pos, pos)
                if (c == '"') then txt = txt .. '"' end
                -- check first char AFTER quoted string, if it is another
                -- quoted string without separator, then append it
                -- this is the way to "escape" the quote char in a quote. example:
                --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
            until (c ~= '"')
            table.insert(res, txt)
            assert(c == sep or c == "")
            pos = pos + 1
        else
            -- no quotes used, just look for the first separator
            local startp, endp = string.find(line, sep, pos)
            if (startp) then
                table.insert(res, string.sub(line, pos, startp - 1))
                pos = endp + 1
            else
                -- no separator found -> use rest of string and terminate
                table.insert(res, string.sub(line, pos))
                break
            end
        end
    end

    results_parse[line] = res
    return res
end

function Utils:get_lines_in_file(path)
    local lines = {}

    for line in love.filesystem.lines(path) do
        table.insert(lines, line)
    end

    return lines
end

--
function Utils:getText(path)
    local text = ""
    local lines = self:get_lines_in_file(path)

    for i, l in ipairs(lines) do
        text = text .. l .. (i == #lines and "" or "\n")
    end

    return text
end

-- look up for 'k' in parent_list
local function search(k, parent_list)
    for i = 1, #parent_list do
        local v = parent_list[i][k]
        if v then return v end
    end
end

function Utils:create_class(...)
    local class_ = {} -- the new class
    local parents = { ... } -- the parents for the new class

    -- class will search for absents fields in the parents list
    setmetatable(class_, { __index = function(t, k)
        local v = search(k, parents)
        t[k] = v -- saving for next access
        return v
    end })

    -- prepare the class to be the metatable of its instances
    class_.__index = class_

    -- defining a new constructor for this new class
    function class_:new()
        local obj = {}
        setmetatable(obj, class_)
        return obj
    end

    return class_
end

local colors = setmetatable({}, { __mode = 'v' })

---@return JM.Color
function Utils:get_rgba(r, g, b, a)
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    a = a or 1.0

    local key = string_format("%d %d %d %d", colorToBytes(r, g, b, a))
    -- local key = string_format("%.15f %.15f %.15f %.15f", r, g, b, a)

    local color = colors[key]
    if color then return color end

    color = { r, g, b, a }
    colors[key] = color
    return color
end

---@param color JM.Color
function Utils:unpack_color(color)
    return color[1], color[2], color[3], color[4]
end

function Utils:round(x)
    local f = mfloor(x + 0.5)
    if (x == f) or (x % 2.0 == 0.5) then
        return f
    else
        return mfloor(x + 0.5)
    end
end

function Utils:clamp(value, min, max)
    return m_min(m_max(value, min), max)
end

---@param rgba string
function Utils:color_hex_2_rgba(rgba)
    local rb = tonumber(string.sub(rgba, 2, 3), 16)
    local gb = tonumber(string.sub(rgba, 4, 5), 16)
    local bb = tonumber(string.sub(rgba, 6, 7), 16)
    local ab = tonumber(string.sub(rgba, 8, 9), 16) or nil
    return colorFromBytes(rb, gb, bb, ab)
end

return Utils

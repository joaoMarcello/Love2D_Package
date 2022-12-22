---@alias JM.Point {x: number, y:number}
--- Table representing a point with x end y coordinates.

---@alias JM.Color {r: number, g: number, b:number, a:number}
--- Represents a color in RGBA space

---@class JM.Utils
local Utils = {}

---comment
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

function Utils:parse_csv_line(line, sep)
    local res = {}
    local pos = 1
    sep = sep or ','
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
    setmetatable(class_, { __index = function(_, k)
        return search(k, parents)
    end })

    -- prepare the class to be the metatable of its instances
    class_.__index = class_

    -- defining a new constructor for this new class
    function class_:new()
        local obj = setmetatable({}, class_)
        return obj
    end

    return class_
end

return Utils

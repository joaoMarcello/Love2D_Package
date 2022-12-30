---@type JM.GUI.Component
local Component = require((...):gsub("container", "component"))

local INSERT_MODE = {
    normal = 1,
    left = 2,
    right = 3,
    center = 4
}

---@class JM.GUI.Container: JM.GUI.Component
---@field components table
local Container = setmetatable({}, Component)

---@return JM.GUI.Container|JM.GUI.Component
function Container:new(args)

    ---@type JM.GUI.Container|JM.GUI.Component
    local obj = Component:new(args)
    self.__index = self
    setmetatable(obj, self)

    obj:__constructor__(args)

    return obj
end

function Container:__constructor__(args)
    args = args or {}
    self.components = {}
    self.space_vertical = 15
    self.space_horizontal = 15
    self.border_x = 15
    self.border_y = 15
end

function Container:set_position(x, y)
    x = x or self.x
    y = y or self.y

    local diff_x, diff_y = x - self.x, y - self.y

    self.x, self.y = x, y

    for _, gc in ipairs(self.components) do
        ---@type JM.GUI.Component
        local c = gc
        c:set_position(c.x + diff_x, c.y + diff_y)
    end
end

function Container:update(dt)
    for i = #(self.components), 1, -1 do

        ---@type JM.GUI.Component
        local gc = self.components[i]

        if gc.remove_ then
            table.remove(self.components, i)
        else
            local r = gc.is_enable and gc:update(dt)
        end
    end
end

function Container:mouse_pressed(x, y)
    for i = 1, #(self.components) do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_enable and not gc.remove_
            and gc.mouse_pressed and gc:mouse_pressed(x, y)
    end
end

function Container:mouse_released(x, y)
    for i = 1, #(self.components) do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_enable and not gc.remove_
            and gc.mouse_released and gc:mouse_released(x, y)
    end
end

function Container:key_pressed(key, scancode, isrepeat)
    for i = 1, #(self.components) do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_enable and not gc.remove_
            and gc.key_pressed and gc:key_pressed(key, scancode, isrepeat)
    end
end

function Container:key_released(key, scancode)
    for i = 1, #(self.components) do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_enable and not gc.remove_
            and gc.key_released and gc:key_released(key, scancode)
    end
end

function Container:draw()
    for i = 1, #(self.components) do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_visible and not gc.remove_ and gc:draw()
    end

    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("line", self:rect())

    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.rectangle("line", self.x + self.border_x, self.y + self.border_y, self.w - self.border_x * 2,
        self.h - self.border_y * 2)
end

---@param obj JM.GUI.Component
---@param mode string|nil
---@return JM.GUI.Component
function Container:add(obj, mode)
    mode = mode or "center"
    local insert_mode = INSERT_MODE[mode]

    ---@type JM.GUI.Component
    local prev = self.components[#self.components]

    if insert_mode == INSERT_MODE.left then
        obj:set_position(self.x + self.border_x, (prev and prev.bottom or self.y) + self.border_y)
    elseif insert_mode == INSERT_MODE.right then
        obj:set_position(
            self.right - self.border_x - obj.w,
            (prev and prev.bottom or self.y) + self.border_y
        )
    elseif insert_mode == INSERT_MODE.center then
        obj:set_position(
            self.x + self.border_x + (self.w - self.border_x * 2) / 2 - obj.w / 2,
            (prev and prev.bottom or self.y) + self.border_y
        )
    end

    table.insert(self.components, obj)
    return obj
end

function Container:refresh_positions()

end

return Container

---@type string
local path = ...

---@class JM.GUI.Container: JM.GUI.Component
local Container = { components = nil }

---@return JM.GUI.Container|JM.GUI.Component
function Container:new()
    ---@type JM.GUI.Component
    local Component = require(path:gsub("container", "component"))

    local obj = Component:new()
    self.__index = self
    setmetatable(obj, self)

    obj.components = {}

    return obj
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

function Container:key_pressed(key)
    for i = 1, #(self.components) do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_enable and not gc.remove_
            and gc.key_pressed and gc:key_pressed(key)
    end
end

function Container:key_released(key)
    for i = 1, #(self.components) do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_enable and not gc.remove_
            and gc.key_released and gc:key_released(key)
    end
end

function Container:draw()
    for i = 1, #(self.components) do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_visible and not gc.remove_ and gc:draw()
    end
end

---@param obj JM.GUI.Component
---@return JM.GUI.Component
function Container:add(obj)
    table.insert(self.components, obj)
    return obj
end

return Container

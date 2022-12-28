---@type string
local path = ...

---@class JM.GUI.Container: JM.GUI.Component
local Container = { components = nil, n = 0 }

---@return JM.GUI.Container|JM.GUI.Component
function Container:new()
    ---@type JM.GUI.Component
    local Component = require(path:gsub("container", "component"))

    local obj = Component:new()
    self.__index = self
    setmetatable(obj, self)

    obj.components = {}
    obj.n = 0

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
    for i = self.n, 1, -1 do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_enable and gc:update(dt)
    end
end

return Container

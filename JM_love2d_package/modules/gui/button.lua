---@type string
local path = ...

---@type JM.GUI.Component
local Component = require(path:gsub("button", "component"))

---@class JM.GUI.Button: JM.GUI.Component
local Button = Component:new()

---@return JM.GUI.Button|JM.GUI.Component
function Button:new(args)
    local obj = Component:new(args)
    self.__index = self
    setmetatable(obj, self)
    return obj
end

function Button:init()
    Component.init(self)
end

return Button

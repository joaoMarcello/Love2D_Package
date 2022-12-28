---@type string
local path = ...

---@type JM.GUI.Component
local Component = require(path:gsub("button", "component"))

---@type JM.Utils
local Utils = require(path:gsub("gui.button", "jm_utils"))

---@type JM.Template.Affectable
local Affectable = require(path:gsub("gui.button", "templates.Affectable"))

---@type JM.Font.Module
local Font = require(path:gsub("gui.button", "jm_font"))

---@enum JM.GUI.ButtonStates
local STATES = {
    free = 0,
    pressed = 1,
    released = 2,
    on_focus = 3,
    locked = 4
}

---@class JM.GUI.Button: JM.GUI.Component
local Button = Component:new()

---@return JM.GUI.Button|JM.GUI.Component
function Button:new(args)
    local obj = Component:new(args)
    self.__index = self
    setmetatable(obj, self)

    self.type = self.TYPE.button
    self.text = args and args.text or "button"
    self.state = STATES.on_focus
    self.color = { 0.3, 0.8, 0.3, 1.0 }

    obj:init()

    return obj
end

function Button:init()
    Component.init(self)
end

function Button:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self:rect())
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self:rect())
    Font:print(self.text, self.x, self.y)
end

return Button

---@type string
local path = ...

---@type JM.GUI.Component
local Component = require(path:gsub("button", "component"))

---@type JM.Utils
local Utils = require(path:gsub("gui.button", "jm_utils"))

---@type JM.Template.Affectable
local Affectable = require(path:gsub("gui.button", "templates.Affectable"))

---@type JM.Font.Manager
local Font = require(path:gsub("gui.button", "jm_font"))

---@class JM.GUI.Button: JM.GUI.Component, JM.Template.Affectable
local Button = {}
setmetatable(Button, { __index = Component })
Button.__index = Button

---@return JM.GUI.Component
function Button:new(args)

    local obj = Component:new(args)
    setmetatable(obj, self)

    Button.__constructor__(obj, args)

    return obj
end

function Button:__constructor__(args)
    self.type_obj = self.TYPE.button
    self.text = args and args.text or "button"

    self:set_color2(0.3, 0.8, 0.3, 1.0)

    self:on_event("mouse_pressed", function(x, y)
        self:set_color2(math.random(), math.random(), math.random(), 1)
    end)

    self:on_event("gained_focus", function()
        self.text = "<color, 1,0,0>on <color, 1,1,0><italic>focus</italic><color, 0, 0, 0> did you hear me. " ..
            math.random(150)
    end)


    self:on_event("lose_focus", function()
        self.text = "button"
    end)

    self:on_event("mouse_released", function()
        -- self:set_color2(math.random(), math.random(), math.random(), 1)
    end)

end

function Button:init()
    Component.init(self)
end

function Button:__custom_draw__()

    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)


    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)

    Font:printf(self.text,
        self.x,
        self.y + 10,
        "center",
        self.w
    )

    -- love.graphics.setColor(0, 0, 0, 1)
    -- love.graphics.printf(self.text, self.x, self.y, self.w, "center")
end

function Button:__pos_draw__()
    -- love.graphics.setColor(0, 0, 0, 0.1)
    -- love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
end

return Button

---@enum JM.GUI.TypeComponent
local TYPES_ = {
    generic = 0,
    button = 1,
    icon = 2,
    imageIcon = 3,
    animatedIcon = 4,
    verticalList = 5,
    horizontalList = 6,
    messageBox = 7,
    window = 8,
    textBox = 9,
    dynamicLabel = 10,
    dialogueBox = 11,
    popupMenu = 12,
    checkBox = 13,
}

local function collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2
        and x1 < x2 + w2
        and y1 + h1 > y2
        and y1 < y2 + h2
end

---@class JM.GUI.Component
---@field key_pressed function
---@field key_released function
---@field mouse_pressed function
---@field mouse_released function
local Component = {
    x = 0,
    y = 0,
    w = 100,
    h = 100,
    is_visible = true,
    is_enable = true,
    type = TYPES_.generic,
    TYPE = TYPES_
}

---@return JM.GUI.Component
function Component:new(args)
    local obj = {}
    self.__index = self
    setmetatable(obj, self)

    obj.x = args.x or obj.x
    obj.y = args.y or obj.y
    obj.w = args.w or obj.w
    obj.h = args.h or obj.h

    return obj
end

function Component:init()
    self.is_enable = true
    self.is_visible = true
    self.remove_ = nil
end

function Component:rect()
    return self.x, self.y, self.w, self.h
end

function Component:check_collision(x, y, w, h)
    return collision(x, y, w, h, self:rect())
end

function Component:update(dt)
    return
end

function Component:draw()
    love.graphics.setColor(0.2, 0.9, 0.2, 1)
    love.graphics.rectangle("fill", self:rect())
end

do
    function Component:set_position(x, y)
        self.x = x or self.x
        self.y = y or self.y
    end

    function Component:set_dimensions(w, h)
        self.w = w or self.w
        self.h = h or self.h
    end

    function Component:set_visible(value)
        self.is_visible = value and true or false
    end

    function Component:set_enable(value)
        self.is_enable = value and true or false
    end

    function Component:remove()
        self.remove_ = true
    end
end

return Component

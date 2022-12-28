local function collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2
        and x1 < x2 + w2
        and y1 + h1 > y2
        and y1 < y2 + h2
end

---@class JM.GUI.Component
local Component = {
    x = 0,
    y = 0,
    w = 100,
    h = 100,
    is_visible = true,
    is_enable = true
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
end

return Component

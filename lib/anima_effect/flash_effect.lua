local Effect = require "Effect"

---
---@class Flash: Effect
---
local Flash = Effect:new(nil, nil)

---
--- Class Effect constructor.
---
---@param animation Anima
---@return Effect effect
function Flash:new(animation)
    local ef = Effect:new(animation)
    setmetatable(ef, self)
    self.__index = self

    Flash.__constructor__(ef)
    return ef
end

---
--- Constructor.
---
---@param self Effect
function Flash:__constructor__()
    self.__id = Effect.TYPE.flash
    self.__range = 0.5
    self.__alpha = 1
    self.__speed = 1
    self.__color = { 1, 1, 1, 1 }
end

--- Update flash.
---@param dt number
function Flash:update(dt)
    self.__rad = (self.__rad + math.pi * 2. / self.__speed * dt)
        % (math.pi * 2.)

    self.__alpha = 0.5 + (math.sin(self.__rad) * self.__range)
end

---
--- Tells if flash color is white.
---
---@return boolean result
function Flash:__color_is_white()
    local color = self.__color
    return color[1] == 1 and color[2] == 1 and color[3] == 1
end

--- Draw the flash effect.
---@param x number
---@param y number
function Flash:draw(x, y)
    if self.__alpha and self:__color_is_white() then
        love.graphics.setBlendMode("add", "alphamultiply")

        self.__anima:set_color({
            self.__color[1],
            self.__color[2],
            self.__color[3],
            self.__alpha * (self.__anima:get_color()[4] or 1)
        })

        self.__anima:__draw_with_no_effects(x, y)
        self.__anima:set_color(self.__config.__color)

        love.graphics.setBlendMode('alpha')
    else
        self.__anima:set_color(self.__color)
        self.__anima:set_color({ a = self.__alpha })
        self.__anima:__draw_with_no_effects(x, y)
        self.__anima:set_color(self.__config.__color)
    end
end

return Flash

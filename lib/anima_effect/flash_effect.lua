local Effect = require "/lib/anima_effect/Effect"

---
---@class Flash: Effect
--- Flash is a Effect sub-class.
local Flash = Effect:new(nil, nil)

---
--- Class Effect constructor.
---
---@overload fun(self: Effect, animation: Anima, args: nil):Effect
---@param animation Anima
---@param args {range: number, alpha: number, speed: number, color: table}
---@return Effect effect
function Flash:new(animation, args)
    local ef = Effect:new(animation, args)
    setmetatable(ef, self)
    self.__index = self

    Flash.__constructor__(ef, args)
    return ef
end

---
--- Constructor.
---@overload fun(self: Effect, args: nil)
---@param self Effect
---@param args {range: number, speed: number, color: table}
function Flash:__constructor__(args)
    self.__id = Effect.TYPE.flash
    self.__range = args and args.range or 0.6
    self.__alpha = 1
    self.__speed = args and args.speed or 0.3
    self.__color = args and args.color or { 1, 1, 1, 1 }
    self.__origin = 0.5
end

function Flash:__init__()
    self:__constructor__(self.__args)
end

--- Update flash.
---@param dt number
function Flash:update(dt)
    self.__rad = (self.__rad + math.pi * 2. / self.__speed * dt)
        % (math.pi * 2.)

    self.__alpha = self.__origin + (math.sin(self.__rad) * self.__range)
end

--- Draw the flash effect.
---@param x number
---@param y number
function Flash:draw(x, y)
    love.graphics.setBlendMode("add", "alphamultiply")

    self.__anima:set_color({
        self.__color[1],
        self.__color[2],
        self.__color[3],
        self.__alpha * (self.__anima:get_color()[4] or 1.)
    })

    self.__anima:__draw_with_no_effects(x, y)
    self.__anima:set_color(self.__config.color)
    love.graphics.setBlendMode('alpha')
end

function Flash:restaure_animation()
    self.__anima:set_color(self.__config.color)
end

return Flash

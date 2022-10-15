local Effect = require "/Anima_JM/scripts/anima_effect/Effect"

---
---@class Flash: Effect
--- Flash is a Effect sub-class.
local Flash = Effect:new(nil, nil)

---
--- Class Effect constructor.
---
---@param object table
---@param args {range: number, alpha: number, speed: number, color: table}|nil
---@return Effect effect
function Flash:new(object, args)
    local ef = Effect:new(object, args)
    setmetatable(ef, self)
    self.__index = self

    Flash.__constructor__(ef, args)
    return ef
end

---
--- Constructor.
---@overload fun(self: Effect, args: nil)
---@param self Effect
---@param args {speed: number, color: table, offset: number}
function Flash:__constructor__(args)
    self.__id = Effect.TYPE.flash
    self.__alpha = 1
    self.__speed = args and args.speed or 0.5
    self.__color = args and args.color or { 1, 1, 1, 1 }
    self.__origin = -0.3
    self.__range = 1.5 --self.__origin + 0.5
    self.__object:set_visible(true)
end

--- Update flash.
---@param dt number
function Flash:update(dt)
    self.__rad = (self.__rad + math.pi * 2. / self.__speed * dt)

    if self.__rad >= math.pi then
        self.__rad = self.__rad % math.pi
        self.__sequence = self.__sequence + 1
    end

    self.__alpha = self.__origin + (math.sin(self.__rad) * self.__range)
end

--- Draw the flash effect.
---@param x number
---@param y number
function Flash:draw(x, y)
    -- self:restaure_object()
    -- self.__object:__draw__(x+100, y)

    love.graphics.setBlendMode("add", "alphamultiply")

    self.__object:set_color({
        self.__color[1],
        self.__color[2],
        self.__color[3],
        self.__alpha
    })

    self.__object:__draw__(x, y)
    -- self.__object:set_color(self.__config.color)
    self:restaure_object()
    love.graphics.setBlendMode('alpha')
end

return Flash

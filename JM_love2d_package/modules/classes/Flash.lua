local Effect = require("/JM_love2d_package/modules/classes/Effect")

---
---@class JM.Effect.Flash: JM.Effect
--- Flash is a Effect sub-class.
local Flash = Effect:new(nil, nil)

---
--- Class Effect constructor.
---
---@param object JM.Affectable|nil
---@param args {speed: number, color: table, min: number, max: number}
---@return JM.Effect effect
function Flash:new(object, args)
    local ef = Effect:new(object, args)
    setmetatable(ef, self)
    self.__index = self

    Flash.__constructor__(ef, args)
    return ef
end

---
--- Constructor.
---@overload fun(self: JM.Effect, args: nil)
---@param self JM.Effect
---@param args {speed: number, color: table, min: number, max: number}
function Flash:__constructor__(args)
    self.__id = Effect.TYPE.flash
    self.__alpha = 1
    self.__speed = args and args.speed or 0.3
    self.__color = args and args.color or { 238 / 255, 243 / 255, 46 / 255, 1 }
    local max = args and args.max or 1.5
    local min = args and args.min or -1.5
    self.__origin = min
    self.__range = (max - min)
    self.__speed = self.__speed + self.__range * self.__speed
    -- self.__prior = 5
end

--- Update flash.
---@param dt number
function Flash:update(dt)
    self.__rad = (self.__rad + math.pi * 2. / self.__speed * dt)

    if self.__rad >= math.pi then
        self.__rad = self.__rad % math.pi
        self:__increment_cycle()
    end

    self.__alpha = self.__origin + (math.sin(self.__rad) * self.__range)
end

--- Draw the flash effect.
---@param x number
---@param y number
function Flash:draw(x, y)

    love.graphics.setBlendMode("add", "alphamultiply")

    self.__object:set_color({
        self.__color[1],
        self.__color[2],
        self.__color[3],
        self.__alpha
    })

    -- self.__object:__draw__(x, y)
    self.__object:__draw__(x, y)
    love.graphics.setBlendMode('alpha')
    self.__object:set_color(self.__obj_initial_color)
end

return Flash

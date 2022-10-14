local Effect = require("/scripts/anima_effect/Effect")

---@class Pulse: Effect
local Pulse = Effect:new(nil, nil)

function Pulse:new(animation, args)
    local ef = Effect:new(animation, args)
    setmetatable(ef, self)
    self.__index = self

    Pulse.__constructor__(ef, args)
    return ef
end

---
---@param self Effect
---@param args any
function Pulse:__constructor__(args)
    self.__acc = 0
    self.__adjust = args and args.adjust or math.pi
    self.__speed = args and args.speed or 0.5
    self.__range = args and args.range or 0.2
    self.__row = 0
    self.__max_row = args and args.max_row or nil
    self.__difX = args and args.difX or 0.1
    self.__difY = args and args.difY or 0.1

    -- self.__acc = 0.5
    -- self.__speed = 0.05
    -- self.__max_row = 6
    -- self.__difX = 0.1
    -- self.__difY = self.__config.scale.y * 0.25
end

function Pulse:__init()
    self:__constructor__(self.__args)
end

function Pulse:update(dt)
    if self.__max_row and (self.__row >= self.__max_row) then
        self.__remove = true
        return
    end

    self.__speed = self.__speed + self.__acc / 1.0 * dt

    self.__rad = (self.__rad + math.pi * 2. / self.__speed * dt)

    if self.__rad >= (math.pi * 2) then
        self.__rad = self.__rad % (math.pi * 2)
        self.__row = self.__row + 1
    end

    if self.__difX and self.__difX ~= 0 then
        self.__anima:set_scale({
            x = self.__config.scale.x
                + (math.sin(self.__rad + self.__adjust)
                    * (self.__difX or self.__range))
                * self.__config.scale.x
        })
    end

    if self.__difY and self.__difY ~= 0 then
        self.__anima:set_scale({
            y = self.__config.scale.y
                + (math.sin(self.__rad + self.__adjust)
                    * (self.__difY or self.__range))
                * self.__config.scale.y
        })
    end
end

return Pulse

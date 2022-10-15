local Effect = require("/Anima_JM/scripts/anima_effect/Effect")

---@class Pulse: Effect
local Pulse = Effect:new(nil, nil)

---comment
---@param object Affectable|nil
---@param args any
---@return Effect
function Pulse:new(object, args)
    local ef = Effect:new(object, args)
    setmetatable(ef, self)
    self.__index = self

    Pulse.__constructor__(ef, args)
    return ef
end

---
---@param self Effect
---@param args any
function Pulse:__constructor__(args)
    self.__id = Effect.TYPE.pulse
    self.__acc = 0
    self.__adjust = args and args.adjust or math.pi
    self.__speed = args and args.speed or 0.5
    self.__range = args and args.range or 0.2
    self.__sequence = 0
    self.__max_sequence = args and args.max_sequence
        or self.__max_sequence
    self.__difX = args and args.difX or 0.1
    self.__difY = args and args.difY or 0.1
    self.__rad = math.pi

    -- self.__acc = 0.5
    -- self.__speed = 0.05
    -- self.__max_row = 6
    -- self.__difX = 0.1
    -- self.__difY = self.__config.scale.y * 0.25
end

function Pulse:update(dt)
    self.__speed = self.__speed + self.__acc / 1.0 * dt

    self.__rad = (self.__rad + math.pi * 2. / self.__speed * dt)

    if self.__rad >= (math.pi * 2) then
        self.__rad = self.__rad % (math.pi * 2)
        self.__sequence = self.__sequence + 1
    end

    if self.__difX and self.__difX ~= 0 then
        self.__object:set_scale({
            x = self.__config.scale.x
                + (math.sin(self.__rad + self.__adjust)
                    * (self.__difX or self.__range))
                * self.__config.scale.x
        })
    end

    if self.__difY and self.__difY ~= 0 then
        self.__object:set_scale({
            y = self.__config.scale.y
                + (math.sin(self.__rad + self.__adjust)
                    * (self.__difY or self.__range))
                * self.__config.scale.y
        })
    end
end

return Pulse

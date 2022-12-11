---@type JM.Effect
local Effect = require((...):gsub("Pulse", "Effect"))

---@class JM.Effect.Pulse: JM.Effect
local Pulse = Effect:new(nil, nil)

---comment
---@param object JM.Affectable|nil
---@param args any
---@return JM.Effect
function Pulse:new(object, args)
    local ef = Effect:new(object, args)
    setmetatable(ef, self)
    self.__index = self

    Pulse.__constructor__(ef, args)
    return ef
end

---
---@param self JM.Effect
---@param args any
function Pulse:__constructor__(args)
    self.__id = args and args.__id__ or Effect.TYPE.pulse

    self.__acc = 0
    self.__adjust = args and args.adjust or 0 --math.pi
    self.__speed = args and args.speed or 0.5
    self.__range = args and args.range or 0.1
    self.__max_sequence = args and args.max_sequence
        or self.__max_sequence
    self.__looping = args and args.max_sequence
    self.__difX = args and args.difX or nil
    self.__difY = args and args.difY or nil
    self.__rad = args and args.__rad__ or math.pi
    self.__prior = 2

    if self.__id == Effect.TYPE.jelly then
        self.__adjust = math.pi * 0.7
        self.__rad = 0
    elseif self.__id == Effect.TYPE.stretchHorizontal then
        self.__difY = 0
    elseif self.__id == Effect.TYPE.stretchVertical then
        self.__difX = 0
    elseif self.__id == Effect.TYPE.bounce then
        self.__acc = 0.5
        self.__speed = 0.05
        self.__max_sequence = 5
        self.__range = 0.05
        self.__difX = 0.1
        self.__difY = self.__scale.y * 0.25
        self.__looping = true
        self.__ends_by_cycle = true
    end

    self.__type_transform.sx = self.__difX ~= 0
    self.__type_transform.sy = self.__difY ~= 0

end

function Pulse:update(dt)
    self.__speed = self.__speed + self.__acc / 1.0 * dt

    self.__rad = (self.__rad + math.pi * 2. / self.__speed * dt)

    if self.__rad >= (math.pi * 2) then
        self.__rad = self.__rad % (math.pi * 2)
        if self.__looping then
            self:__increment_cycle()
        end
    end

    if self.__difX ~= 0 then

        self.__object:__set_effect_transform({
            sx = 1 + (math.sin(self.__rad)
                * (self.__difX or self.__range))
        })

    end

    if self.__difY ~= 0 then

        self.__object:__set_effect_transform({
            sy = 1 + (math.sin(self.__rad + self.__adjust)
                * (self.__difY or self.__range))
        })
    end
end

return Pulse

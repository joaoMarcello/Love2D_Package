local Effect = require((...):gsub("Disc", "Effect"))

---@class JM.Effect.Disc: JM.Effect
local Disc = Effect:new(nil, nil)

---@param object JM.Affectable|nil
---@param args any|nil
---@return JM.Effect|JM.Effect.Disc
function Disc:new(object, args)
    local obj = Effect:new(object, args)
    setmetatable(obj, self)
    self.__index = self

    Disc.__constructor__(obj, args)
    return obj
end

---@param self JM.Effect
---@param args any|nil
function Disc:__constructor__(args)
    self.__id = Effect.TYPE.disc
    self.__type_transform.kx = true
    self.__type_transform.ky = true

    self.__range = 0.8
    self.__speed = 4
    self.__direction = 1
    self.__not_restaure = true
end

function Disc:update(dt)
    self.__rad = self.__rad + (math.pi * 2) / self.__speed * dt

    if self.__rad >= math.pi * 2. then
        self:__increment_cycle()
    end

    self.__rad = self.__rad % (math.pi * 2.)

    self.__object:__set_effect_transform({
        kx = math.sin(self.__rad) * self.__range,
        ky = -math.sin(self.__rad + math.pi * 1.5) * self.__range
    })
end

return Disc

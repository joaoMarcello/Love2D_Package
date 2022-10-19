local Effect = require("/JM_love2d_package/modules/classes/Effect")

---@class JM.Effect.Float: JM.Effect
local Float__ = Effect:new(nil, nil)

---@param object JM.Affectable|nil
---@param args any|nil
---@return JM.Effect|JM.Effect.Float
function Float__:new(object, args)
    local obj = Effect:new(object, args)
    setmetatable(obj, self)
    self.__index = self

    Float__.__constructor__(obj, args)
    return obj
end

---@param self JM.Effect
---@param args any|nil
function Float__:__constructor__(args)

    self.__id = args and args.__id__ or Effect.TYPE.float

    self.__speed = args and args.speed or 1

    self.__range = args and args.range or 20

    self.__floatX = self.__id == Effect.TYPE.pointing
        or self.__id == Effect.TYPE.circle or self.__id == Effect.TYPE.eight
        or self.__id == Effect.TYPE.butterfly

    self.__floatY = self.__id == Effect.TYPE.float
        or self.__id == Effect.TYPE.circle or self.__id == Effect.TYPE.eight
        or self.__id == Effect.TYPE.butterfly

    self.__adjust = args and args.adjust or math.pi / 2
    self.__rad = args and args.rad or 0

    if self.__id ~= Effect.TYPE.circle then
        self.__adjust = self.__id == Effect.TYPE.eight and 2 or 1
    end
    self.__adjustY = self.__id == Effect.TYPE.butterfly and 2 or 1

    self.__type_transform.ox = self.__floatX
    self.__type_transform.oy = self.__floatY

end

function Float__:update(dt)
    self.__rad = self.__rad + ((math.pi * 2) / self.__speed) * dt

    if self.__rad >= math.pi * 2 then
        self:__increment_cycle()
    end

    self.__rad = self.__rad % (math.pi * 2)

    if self.__id == Effect.TYPE.circle then
        self:__circle_update(dt)
    else
        self:__not_circle_update(dt)
    end
end

function Float__:__circle_update(dt)
    local tx = self.__floatX and (math.sin(self.__rad + self.__adjust) * self.__range) or 0

    local ty = self.__floatY and (math.sin(self.__rad * self.__adjustY) * self.__range) or 0

    self.__object:__set_effect_transform({
        ox = tx,
        oy = ty
    })
end

function Float__:__not_circle_update(dt)
    local tx = self.__floatX and (math.sin(self.__rad * self.__adjust) * self.__range) or 0

    local ty = self.__floatY and (math.sin(self.__rad * self.__adjustY) * self.__range) or 0

    self.__object:__set_effect_transform({
        ox = tx,
        oy = ty
    })
end

return Float__

local Effect = require("/JM_love2d_package/modules/classes/Effect")

---@class JM.Effect.Float: JM.Effect
local Float__ = Effect:new(nil, nil)

---@param object JM.Affectable|nil
---@param args any|nil
---@return JM.Effect
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
    self.__id = Effect.TYPE.float

    self.__speed = 1
    self.__range = 20
    self.__floatX = false
    self.__floatY = true
    self.__adjust = math.pi / 2
    self.__rad = 0
end

function Float__:update(dt)
    self.__rad = self.__rad + ((math.pi * 2) / self.__speed) * dt

    if self.__rad >= math.pi * 2 then
        self:__increment_cycle()
    end

    self.__rad = self.__rad % (math.pi * 2)
end

function Float__:draw(x, y)

    local tx = self.__floatX and x + (math.sin(self.__rad + self.__adjust) * self.__range)
        or x

    local ty = self.__floatY and y + (math.sin(self.__rad) * self.__range)
        or y

    self.__object:__set_transform({
        x = x,
        y = y,
        ox = tx,
        oy = ty
    })

    self.__object:__draw__(x, y)

end

return Float__

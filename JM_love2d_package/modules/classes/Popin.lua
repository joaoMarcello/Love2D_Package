local Effect = require("/JM_love2d_package/modules/classes/Effect")

---@class JM.Effect.Popin: JM.Effect
local Popin = Effect:new()

---@param object JM.Affectable|nil
---@param args any
---@return JM.Effect
function Popin:new(object, args)
    local ef = Effect:new(object, args)
    setmetatable(ef, self)
    self.__index = self

    Popin.__constructor__(ef, args)
    return ef
end

---@param self JM.Effect
---@param args any
function Popin:__constructor__(args)
    self.__id = args and args.__id__ or Effect.TYPE.popin
    self.__type_transform.sx = true
    self.__type_transform.sy = true

    self.__scale.x = 0.3
    self.__speed = 0.2
    self.__min = 1
    self.__range = 0.2
    self.__state = 1

    if self.__id == Effect.TYPE.popout then
        if self.__object then self.__object:set_visible(true) end
        self.__scale.x = 1
        self.__min = 0.3
        self.__range = 0.3
    end
end

function Popin:update(dt)
    if self.__state == 1 then
        self.__scale.x = self.__scale.x + (1 + self.__range * 2) / self.__speed * dt

        if self.__scale.x >= ((1 + self.__range)) then
            self.__scale.x = ((1 + self.__range))
            self.__state = 0
        end
    end

    if self.__state == 0 then
        self.__scale.x = self.__scale.x - (1 + self.__range * 2) / self.__speed * dt

        if self.__id == Effect.TYPE.popin then
            if self.__scale.x <= 1 then
                self.__scale.x = 1
                self.__state = -1
                self.__object:__set_effect_transform({
                    sx = 1 + self.__scale.x,
                    sy = 1 + self.__scale.x
                })
                self.__remove = true
            end
        else
            if self.__scale.x <= self.__min then
                self.__state = -1
                self.__object:set_visible(false)
                self.__object:__set_effect_transform({
                    sx = 1,
                    sy = 1
                })
                self.__remove = true
                return
            end
        end
    end

    if self.__state >= 0 then
        self.__object:__set_effect_transform({
            sx = self.__scale.x,
            sy = self.__scale.x
        })
    end
end

return Popin
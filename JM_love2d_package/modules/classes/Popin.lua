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

    self.__scale.x = self.__object and self.__object:get_scale().x * 0.3 or 0.3
    self.__speed = 0.2
    self.__min = self.__object and self.__object:get_scale().x or 1
    self.__range = 0.2
    self.__state = 1

    if self.__id == Effect.TYPE.popout then
        self.__object:set_visible(true)
        self.__scale.x = self.__object and self.__object:get_scale().x or 1
        self.__min = self.__object and self.__object:get_scale().x * 0.3 or 0.3
        self.__range = 0.3
    end
end

function Popin:update(dt)
    if self.__state == 1 then
        self.__scale.x = self.__scale.x + (1 + self.__range * 2) / self.__speed * dt

        if self.__scale.x >= (self.__config.scale.x * (1 + self.__range)) then
            self.__scale.x = (self.__config.scale.x * (1 + self.__range))
            self.__state = 0
        end
    end

    if self.__state == 0 then
        self.__scale.x = self.__scale.x - (1 + self.__range * 2) / self.__speed * dt

        if self.__id == Effect.TYPE.popin then
            if self.__scale.x <= self.__config.scale.x then
                self.__scale.x = 1
                self.__state = -1
                self.__object:set_scale({ x = self.__scale.x, y = self.__scale.x })
                self.__remove = true
            end
        else
            if self.__scale.x <= self.__min then
                self.__state = -1
                self.__object:set_visible(false)
                self.__object:set_scale({
                    x = self.__config.scale.x,
                    y = self.__config.scale.y
                })
                self.__remove = true
                return
            end
        end
    end

    if self.__state >= 0 then
        self.__object:set_scale({ x = self.__scale.x, y = self.__scale.x })
    end
end

return Popin

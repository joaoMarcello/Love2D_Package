local Effect = require("/JM_love2d_package/modules/classes/Effect")

---@class JM.Effect.Fadein: JM.Effect
local Fadein = Effect:new(nil, nil)

---@param object JM.Affectable|nil
---@param args any|nil
---@return JM.Effect|JM.Effect.Fadein
function Fadein:new(object, args)
    local obj = Effect:new(object, args)
    setmetatable(obj, self)
    self.__index = self

    Fadein.__constructor__(obj, args)
    return obj
end

---@param self JM.Effect
---@param args any|nil
function Fadein:__constructor__(args)
    self.__id = args and args.__id__ or Effect.TYPE.fadein

    self.__min = 0.0
    self.__alpha = self.__min
    self.__dif = 1
    self.__speed = args and args.speed or 0.5
    local r = self.__object and self.__object:set_color({ a = 0 })

    if self.__id == Effect.TYPE.fadeout then
        self.__alpha = 1
        self.__speed = 0.2
        local r = self.__object and self.__object:set_color({ a = 1 })
    end
end

function Fadein:update(dt)
    if self.__id == Effect.TYPE.fadein then
        self:update_fadein(dt)
    else
        self:update_fadeout(dt)
    end
end

function Fadein:update_fadein(dt)
    if self.__alpha < 1 then
        self.__alpha = self.__alpha + self.__dif / self.__speed * dt
        self.__object:set_color({ a = self.__alpha })
    else
        self.__remove = true
        self.__object:set_color(self.__config.color)
    end
end

function Fadein:update_fadeout(dt)
    if self.__alpha > self.__min then
        self.__alpha = self.__alpha - self.__dif / self.__speed * dt
    end

    self.__object:set_color({ a = self.__alpha })
end

return Fadein

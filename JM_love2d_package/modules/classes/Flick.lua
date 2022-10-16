local Effect = require("/JM_love2d_package/modules/classes/Effect")

---
---@class JM.Effect.Flick: JM_Effect
--- Flick is a Effectsub-class.
local Flick = Effect:new(nil, nil)


function Flick:new(animation, args)
    local ef = Effect:new(animation, args)
    setmetatable(ef, self)
    self.__index = self

    Flick.__constructor__(ef, args)
    return ef
end

---comment
---@param self JM_Effect
---@param args any
function Flick:__constructor__(args)
    self.__id = Effect.TYPE.flick
    self.__speed = args and args.speed or 0.1
    self.__time = 0
    self.__color = args and args.color or { 0, 0, 1, 0 }
    self.__flick_state = 1
    self.__cycle_count = -1
end

function Flick:update(dt)
    self.__time = self.__time + dt
    if self.__time >= self.__speed then
        self.__flick_state = -self.__flick_state
        self.__time = self.__time - self.__speed
        self.__cycle_count = self.__cycle_count + 1
    end

    if self.__flick_state == 1 then
        self.__object:set_color(self.__color)
    elseif self.__flick_state == -1 then
        -- self.__object:set_color(self.__config.color)
        -- self:restaure_object()
    end
end

return Flick

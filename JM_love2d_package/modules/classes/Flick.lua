local Effect = require((...):gsub("Flick", "Effect"))

---
---@class JM.Effect.Flick: JM.Effect
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
---@param self JM.Effect
---@param args any
function Flick:__constructor__(args)
    self.__id = Effect.TYPE.flickering
    self.__speed = args and args.speed or 0.1
    self.__time = 0
    self.__color = args and args.color or { r = 0, g = 0, b = 1, a = 0 }

    self.__flick_state = 1
    self.__cycle_count = -1
end

function Flick:update(dt)
    self.__time = self.__time + dt
    if self.__time >= self.__speed then
        self.__flick_state = -self.__flick_state
        self.__time = self.__time - self.__speed
        self:__increment_cycle()
    end

    if self.__flick_state == 1 then
        self.__object:set_color(self.__color)
    elseif self.__flick_state == -1 then
        self.__object:set_color(self.__obj_initial_color)
    end
end

return Flick

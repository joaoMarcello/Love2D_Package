local Effect = require((...):gsub("Ghost", "Effect"))

---@class JM.Effect.Ghost: JM.Effect
local Ghost = Effect:new(nil, nil)

---@param object JM.Affectable|nil
---@param args any|nil
---@return JM.Effect|JM.Effect.Ghost
function Ghost:new(object, args)
    local obj = Effect:new(object, args)
    setmetatable(obj, self)
    self.__index = self

    Ghost.__constructor__(obj, args)
    return obj
end

---@param self JM.Effect
---@param args any|nil
function Ghost:__constructor__(args)
    self.__id = Effect.TYPE.ghost

    self.__range = 1
    self.__speed = args and args.speed or 1.5
    self.__alpha = 1
end

function Ghost:update(dt)
    self.__rad = (self.__rad + self.PI * 2. / self.__speed * dt)
        % (self.PI * 2)

    self.__object:set_color({ a = 1 + self.sin(self.__rad) * self.__range })
end

return Ghost

local Effect = require("/JM_love2d_package/modules/classes/Effect")

---@class JM.Effect.Balance: JM.Effect
local Balance = Effect:new()


---@param object JM.Affectable|nil
---@param args any
---@return JM.Effect
function Balance:new(object, args)
    local ef = Effect:new(object, args)
    setmetatable(ef, self)
    self.__index = self

    Balance.__constructor__(ef, args)
    return ef
end

---@param self JM.Effect
---@param args any
function Balance:__constructor__(args)
    self.__id = args and args.__id__ or Effect.TYPE.balance

    self.__range = args and args.range or 0.1
    self.__speed = args and args.speed or 4
    self.__direction = 1
    self.__not_restaure = true
end

function Balance:update(dt)
    self.__rad = self.__rad + math.pi * 2 / self.__speed * dt * self.__direction

    if self.__rad >= math.pi * 2 then
        self:__increment_cycle()
        self.__rad = self.__rad % (math.pi * 2)
    end

    self.__object:set_rotation(math.sin(self.__rad) * math.pi * 2 * self.__range)
end

return Balance

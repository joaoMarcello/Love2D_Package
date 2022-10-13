---@class EffectManager
--- Manages a list of Effect.
local EffectManager = {}

---
--- Public constructor.
---@overload fun(effect_list: nil): EffectManager
---@param effect_list table <Effect>
---@return EffectManager
function EffectManager:new(effect_list)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    EffectManager.__constructor__(obj, effect_list)
    return obj
end

---
--- Constructor.
--- @overload fun(effect_list: nil)
---@param effect_list table <Effect>
function EffectManager:__constructor__(effect_list)
    self:set_effect_list(effect_list)
    self.__sort__ = false
end

--- Set the list to manager.
---@param new_list table <Effect>
function EffectManager:set_effect_list(new_list)
    self.__effects_list = new_list
end

---
--- Return a Effect element in a list of <Effect>
---@param index number
---@return Effect effect
function EffectManager:__get_effect_in_list__(index)
    return self.__effects_list[index]
end

--- Update EffectManager class.
---@param dt number
function EffectManager:update(dt)
    if self.__effects_list then
        for i = #self.__effects_list, 1, -1 do
            local eff = self:__get_effect_in_list__(i)
            local r = eff.__is_enabled and eff:update(dt)

            if eff.__remove then
                if eff.__final_action then
                    eff.__final_action(eff.__args_final_action)
                end

                if self.__effects_clear then
                    self.__effects_clear = nil;
                    break
                end

                local r2 = table.remove(self.__effects_list, i)
            end -- END if remove effect
        end -- END FOR i in effects list

        if self.__sort__ then
            table.sort(self.__effects_list,
                --- Sort function. Expecting two Effect objects. Return the one with the biggest priority.
                ---@param a Effect
                ---@param b Effect
                ---@return boolean
                function(a, b)
                    return a.__prior > b.__prior;
                end
            )

            self.__sort__ = false
        end -- END sorting list of Effects.

    end -- END effect list is not nil.
end

---
--- Stop all the current running effects.
---@return boolean
function EffectManager:stop_all()
    if self.__effects_list then
        self.__effects_list = {}
        self.__effects_clear = true
        collectgarbage("collect")
        return true
    end
    return false
end

function EffectManager:pause_all()
    if self.__effects_list then
        for i = 1, #self.__effects_list do
            local eff = self:__get_effect_in_list__(i)
            eff.__is_enabled = false
        end
    end
end

function EffectManager:resume_all()
    if self.__effects_list then
        for i = 1, #self.__effects_list do
            local eff = self:__get_effect_in_list__(i)
            eff.__is_enabled = true
        end
    end
end

return EffectManager

local Flash = require "/scripts/anima_effect/flash_effect"
local Flick = require "/scripts/anima_effect/flick_effect"
local Pulse = require("/scripts/anima_effect/pulse_effect")

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
    self.__current_id = 1
end

--- Set the list to manager.
---@param new_list table <Effect>
function EffectManager:set_effect_list(new_list)
    self.__effects_list = new_list or {}
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
            local r1 = eff.__is_enabled and eff:__update__(dt)
            local r2 = eff.__is_enabled and eff:update(dt)

            if eff.__remove then
                if eff.__final_action then
                    eff.__final_action(eff.__args_final_action)
                end

                eff:restaure_animation()

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

--- Draw the effects.
---@param x number
---@param y number
function EffectManager:draw(x, y)
    if self.__effects_list then
        for i = #self.__effects_list, 1, -1 do
            local eff = self:__get_effect_in_list__(i)
            eff:draw(x, y)
        end
    end
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

--- Stops a especific effect by his unique id.
---@param effect_unique_id number
---@return boolean result
function EffectManager:stop_effect(effect_unique_id)
    for i = 1, #self.__effects_list do

        local eff = self:__get_effect_in_list__(i)

        if eff:get_unique_id() == effect_unique_id then
            eff.__remove = true
            return true
        end
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

--- Possible values for effect names.
---@alias EffectName string
---|"flash" # animation blinks like a star.
---|"flick" # animation surges in the screen.
---|"popin"
---|"popout"
---|"fadein"
---|"fadeout"
---|"colorFlick"
---|"pulse"


---Applies effect in a animation.
---@param animation Anima # The animation object to apply the effect.
---@param effect_type EffectName # The type of the effect.
---@param effect_args any # The parameters need for that especific effect.
---@param __only_get boolean|nil
---@return Effect eff # The generate effect.
function EffectManager:apply_effect(animation, effect_type, effect_args, __only_get)
    if not self.__effects_list then self.__effects_list = {} end

    local eff

    if effect_type == "flash" then
        eff = Flash:new(animation, effect_args)
    elseif effect_type == "flick" then
        eff = Flick:new(animation, effect_args)
    elseif effect_type == "colorFlick" then
        eff = Flick:new(animation, effect_args)
        if not effect_args or (effect_args and not effect_args.color) then
            eff.__color = { 1, 0, 0, 1 }
        end
    elseif effect_type == "pulse" then
        eff = Pulse:new(animation, effect_args)
    end

    if eff then
        eff:set_unique_id(self.__current_id)
        self.__current_id = self.__current_id + 1

        if not __only_get then
            self:__insert_effect(eff)
        end
    end

    return eff
end

function EffectManager:generate_effect(animation, effect_type, effect_args)
    return self:apply_effect(animation, effect_type, effect_args, true)
end

function EffectManager:__is_in_list(effect)
    if not effect then return end

    for i = 1, #self.__effects_list do
        if effect == self.__effects_list[i] then
            return true
        end
    end

    return false
end

--- Insert effect.
---@param effect Effect
function EffectManager:__insert_effect(effect)
    if self:__is_in_list(effect) then return end

    table.insert(self.__effects_list, effect)
    self.__sort__ = true
end

return EffectManager

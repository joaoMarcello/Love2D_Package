local Effect = require("/JM_love2d_package/modules/classes/Effect")
local Flash = require("/JM_love2d_package/modules/classes/Flash")
local Flick = require("/JM_love2d_package/modules/classes/Flick")
local Pulse = require("/JM_love2d_package/modules/classes/Pulse")
local Float = require("/JM_love2d_package/modules/classes/Float")
local Idle = require("/JM_love2d_package/modules/classes/Iddle")

-- Global variable for control the unique id's from EffectManager class.
---
--- > WARNING: Don't ever manipulate this variable.
JM_current_id_for_effect_manager__ = 1

---@class JM.EffectManager
--- Manages a list of Effect.
local EffectManager = {}

---
--- Public constructor.
---@return JM.EffectManager
function EffectManager:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    EffectManager.__constructor__(obj)
    return obj
end

---
--- Constructor.
function EffectManager:__constructor__()
    self.__effects_list = {}
    self.__sort__ = false
    self.__current_id = 1
end

---
--- Return a Effect element in a list of <Effect>
---@param index number
---@return JM.Effect effect
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

                eff:restaure_object()
                eff.__object:__set_transform(nil)

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
                ---@param a JM.Effect
                ---@param b JM.Effect
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
            eff:restaure_object()
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
---@alias JM.Effect.id_string string
---|"flash" # animation blinks like a star.
---|"flick" # animation surges in the screen.
---|"pulse"
---|"colorFlick"
---|"popin"
---|"popout"
---|"fadein"
---|"fadeout"
---|"ghost"
---|"spin"
---|"clockWise"
---|"counterClockWise"
---|"balance"
---|"pop"
---|"growth"
---|"disc"
---|"idle"
---|"echo"
---|"float"
---|"pointing"
---|"darken"
---|"brighten"
---|"shadow"
---|"line"
---|"zoomInOut"
---|"stretchHorizontal"
---|"stretchVertical"
---|"circle"
---|"eight"
---|"bounce"
---|"heartBeat"


---Applies effect in a animation.
---@param object JM.Affectable|nil # The object to apply the effect.
---@param effect_type JM.Effect.id_string|JM.Effect.id_number # The type of the effect.
---@param effect_args any # The parameters need for that especific effect.
---@param __only_get__ boolean|nil
---@return JM.Effect eff # The generate effect.
function EffectManager:apply_effect(object, effect_type, effect_args, __only_get__)
    -- if not self.__effects_list then self.__effects_list = {} end

    local eff

    if effect_type == "flash" or effect_type == Effect.TYPE.flash then
        eff = Flash:new(object, effect_args)
    elseif effect_type == "flick" or effect_type == Effect.TYPE.flick then
        eff = Flick:new(object, effect_args)
    elseif effect_type == "colorFlick"
        or effect_type == Effect.TYPE.colorFlick then

        eff = Flick:new(object, effect_args)
        eff.__id = Effect.TYPE.colorFlick

        if not effect_args or (effect_args and not effect_args.color) then
            eff.__color = { 1, 0, 0, 1 }
        end
    elseif effect_type == "pulse" or effect_type == Effect.TYPE.pulse then
        eff = Pulse:new(object, effect_args)
    elseif effect_type == "float" or effect_type == Effect.TYPE.float then
        eff = Float:new(object, effect_args)
    elseif effect_type == "pointing"
        or effect_type == Effect.TYPE.pointing then

        if not effect_args then
            effect_args = {}
        end

        effect_args.__id__ = Effect.TYPE.pointing

        eff = Float:new(object, effect_args)

    elseif effect_type == "circle" or effect_type == Effect.TYPE.circle then
        if not effect_args then
            effect_args = {}
        end

        effect_args.__id__ = Effect.TYPE.circle
        eff = Float:new(object, effect_args)
    elseif effect_type == "eight" or effect_type == Effect.TYPE.eight then
        if not effect_args then
            effect_args = {}
        end
        effect_args.__id__ = Effect.TYPE.eight
        eff = Float:new(object, effect_args)
    elseif effect_type == "idle" or effect_type == Effect.TYPE.idle then
        eff = Idle:new(object, effect_args)
    elseif effect_type == "heartBeat"
        or effect_type == Effect.TYPE.heartBeat then

        eff = Pulse:new(object, { max_sequence = 2, speed = 0.3, range = 0.1 })
        local idle_eff = Idle:new(object, { duration = 1 })

        eff:set_final_action(
        ---@param args {idle: JM.Effect, pulse: JM.Effect}
            function(args)
                args.idle:apply(args.pulse.__object)
            end,
            { idle = idle_eff, pulse = eff }
        )

        idle_eff:set_final_action(
        ---@param args {idle: JM.Effect, pulse: JM.Effect}
            function(args)
                args.pulse:apply(args.idle.__object)
            end,
            { idle = idle_eff, pulse = eff }
        )
    end

    if eff then
        eff:set_unique_id(JM_current_id_for_effect_manager__)
        JM_current_id_for_effect_manager__ = JM_current_id_for_effect_manager__ + 1

        if not __only_get__ then
            self:__insert_effect(eff)
        end
    end

    return eff
end

---comment
---@param effect_type JM.Effect.id_string|JM.Effect.id_number
---@param effect_args any
---@return JM.Effect
function EffectManager:generate_effect(effect_type, effect_args)
    local eff = self:apply_effect(nil, effect_type, effect_args, true)
    eff.__object = nil
    return eff
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
---@param effect JM.Effect
function EffectManager:__insert_effect(effect)
    if self:__is_in_list(effect) then return end

    table.insert(self.__effects_list, effect)
    self.__sort__ = true
end

return EffectManager

---
---@class JM.Effect
---@field __id JM.Effect.id_number
---@field __UNIQUE_ID number
---@field __init function
local Effect = {}

local MSG_using_effect_with_no_associated_affectable = "\nError: Trying to use a 'Effect' object without associate him to a 'Affectable' object.\n\nTip: Try use the ':force' method from the 'Effect' object."

---
--- The animation effects.
---
---@enum JM.Effect.id_number
local TYPE_ = {
    generic = 0, --***
    flash = 1, --***
    flickering = 2, --***
    pulse = 3, --***
    colorFlick = 4, --***
    popin = 5,
    popout = 6,
    fadein = 7,
    fadeout = 8,
    ghost = 9,
    spin = 10,
    clockWise = 11, --***
    counterClockWise = 12,  --***
    balance = 13,
    pop = 14,
    growth = 15,
    disc = 16,
    idle = 17, --***
    echo = 18,
    float = 19, --***
    pointing = 20, --***
    darken = 21,
    brighten = 22,
    shadow = 23,
    line = 24,
    zoomInOut = 25,
    stretchHorizontal = 26, --***
    stretchVertical = 27, --***
    circle = 28, --***
    eight = 29, --***
    bounce = 30, --***
    heartBeat = 31, --***
    butterfly = 32, --***
    jelly = 33 --***
}

Effect.TYPE = TYPE_

---
--- Class effect constructor.
---@overload fun(self: table|nil, object: nil, args: nil):JM.Effect
---@param object JM.Affectable # O objeto que sera afetado pelo efeito.
---@param args any
---@return JM.Effect effect
function Effect:new(object, args)

    local effect = {}
    setmetatable(effect, self)
    self.__index = self

    Effect.__constructor__(effect, object, args)

    return effect
end

---
--- Class effect constructor.
---
---@param object JM.Affectable
function Effect:__constructor__(object, args)
    self.__id = Effect.TYPE.generic
    self.__color = { 1, 1, 1, 1 }
    self.__scale = { x = 1, y = 1 }
    self.__is_enabled = true
    self.__prior = 1
    self.__rad = 0
    self.__cycle_count = 0
    self.__object = object
    self.__args = args
    self.__remove = false
    self.__update_time = 0
    self.__duration = args and args.duration or nil
    self.__speed = 0.5
    self.__max_sequence = args and args.max_sequence or 100
    self.__ends_by_cycle = args and args.max_sequence or false

    self.__transform = nil

    if object and not self.__config then
        object:__push()
        self.__config = object:__get_configuration()
        object:__pop()
    end
end

--
--- Set the effect final action.
---@param action function
---@param args any
function Effect:set_final_action(action, args)
    self.__final_action = action
    self.__args_final_action = args
end

-- --- Set effect in loop mode.
-- ---@param value boolean
-- function Effect:loop_mode(value)
--     if value then
--         self:set_final_action(
--         ---comment
--         ---@param args JM.Affectable
--             function(args)
--                 local eff = args:apply(self.__args)
--                 eff:loop_mode(true)
--             end,

--             self.__object
--         )
--     else -- value parameter is nil or false
--         self.__final_action = nil
--         self.__args_final_action = nil
--     end
-- end

function Effect:init()
    self.__remove = false
    self.__is_enabled = true
    self.__rad = 0
    self.__cycle_count = 0
    self.__update_time = 0
    self:__constructor__(self.__args)
end

function Effect:__increment_cycle()
    self.__cycle_count = self.__cycle_count + 1
end

function Effect:update(dt)
    return false
end

function Effect:__update__(dt)
    assert(self.__object, "Error: Effect object is not associated with a Affectable object.")

    self.__update_time = self.__update_time + dt

    if self.__duration and self.__update_time >= self.__duration then
        self.__remove = true
    end

    if self.__max_sequence
        and self.__ends_by_cycle
        and (self.__cycle_count >= self.__max_sequence) then

        self.__remove = true
    end

    if self.__remove then
        if self.__final_action then
            self:restaure_object()
            self.__final_action(self.__args_final_action)
        end
    end
end

function Effect:restaure_object()
    assert(self.__object, MSG_using_effect_with_no_associated_affectable)
    self.__object:__set_configuration(self.__config)
    -- self.__object:__set_transform(nil)
    self.__object:__pop()
end

function Effect:draw(x, y)
    return false
end

--- Forca efeito em um objeto que nao era dele.
---@param object JM.Affectable
function Effect:apply(object)
    if not object then return end

    if object and object ~= self.__object then
        object:__push()
        self.__config = object:__get_configuration()
        object:__pop()
    end

    self.__object = object
    self:restart(true)
end

---comment
---@param value number
function Effect:set_unique_id(value)
    if not self.__UNIQUE_ID then
        self.__UNIQUE_ID = value
    end
end

--- The unique identifiers.
---@return number
function Effect:get_unique_id()
    return self.__UNIQUE_ID
end

--- Restaure the effect in animation.
---@param reset_config boolean|nil # if reset the effect to his initial configuration.
function Effect:restart(reset_config)
    if reset_config then
        self:init()
    end

    assert(self.__object, MSG_using_effect_with_no_associated_affectable)
    self.__object.__effect_manager:__insert_effect(self)
end

return Effect

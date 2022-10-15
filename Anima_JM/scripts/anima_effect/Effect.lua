---
---@class Effect
---@field __id Effect_ID
---@field __UNIQUE_ID number
---@field __init function
local Effect = {}

---@alias Effect.Color {[1]: number, [2]: number, [3]: number, [4]: number}|{r: number, g: number, b:number, a:number}
--- The color format for effects.

---@alias Effect.Point {x:number, y: number}
--- Table with x and y fileds.

---
--- The animation effects.
---
---@enum Effect_ID
local TYPE_ = {
    generic = 0,
    flash = 1,
    flick = 2,
    pulse = 3,
    colorFlick = 4
}

Effect.TYPE = TYPE_

---
--- Class effect constructor.
---@overload fun(self: table, object: nil, args: nil):Effect
---@param object Affectable # O objeto que sera afetado pelo efeito.
---@param args any
---@return Effect effect
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
---@param object Affectable
function Effect:__constructor__(object, args)
    self.__id = Effect.TYPE.generic
    self.__color = { 1, 1, 1, 1 }
    self.__scale = { x = 1, y = 1 }
    self.__is_enabled = true
    self.__prior = 1
    self.__rad = 0
    self.__sequence = 0
    self.__object = object
    self.__args = args
    self.__remove = false
    self.__update_time = 0
    self.__duration = args and args.duration or nil
    self.__speed = 0.5
    self.__max_sequence = args and args.max_sequence or 100
    self.__ends_by_sequence = args and args.max_sequence or false

    self.__transform = {
        x = 0, y = 0,
        rot = 0,
        sx = 1, sy = 1,
        ox = 0, oy = 0,
        kx = 0, ky = 0
    }

    if object then
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

--- Set effect in loop mode.
---@param value boolean
function Effect:loop_mode(value)
    if value then
        self:set_final_action(
            function(args)
                local eff = args:applyEffect(self.__args)
                eff:loop_mode(true)
            end,

            self.__object
        )
    else -- value parameter is nil or false
        self.__final_action = nil
        self.__args_final_action = nil
    end
end

function Effect:init()
    self.__remove = false
    self.__is_enabled = true
    self.__rad = 0
    self.__sequence = 0
    self.__update_time = 0
    self:__constructor__(self.__args)
end

function Effect:update(dt)
    return false
end

function Effect:__update__(dt)
    self.__update_time = self.__update_time + dt

    if self.__duration and self.__update_time >= self.__duration then
        self.__remove = true
        return
    end

    if self.__max_sequence
        and self.__ends_by_sequence
        and (self.__sequence >= self.__max_sequence) then

        self.__remove = true
        return
    end
end

function Effect:restaure_object()
    self.__object:__set_configuration(self.__config)
    self.__object:__pop()
end

function Effect:draw(x, y)
    return false
end

--- Forca efeito em um objeto que nao era dele.
---@param object Affectable
function Effect:force(object)
    if not object then return end

    if object then
        object:__push()
        self.__config = object:__get_configuration()
        object:__pop()
    end

    self.__object = object
    self:restart(true)
    -- object.__effect_manager:apply_effect(object, self.__id, self.__args)
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
        -- local r = self.__init and self:__init()
    end
    self.__object.__effect_manager:__insert_effect(self)
end

--- Tells if this is a flash effect.
---@return boolean result
function Effect:is_flash()
    return self.__id == TYPE_.flash
end

return Effect

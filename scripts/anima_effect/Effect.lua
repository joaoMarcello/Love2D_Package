---
---@class Effect
---@field __id Effect_ID
---@field __UNIQUE_ID number
---@field __init function
local Effect = {}

---
--- The animation effects.
---
---@enum Effect_ID
local TYPE_ = {
    generic = 0,
    flash = 1,
    flick = 2,
    pop = 3
}

Effect.TYPE = TYPE_

---
--- Class effect constructor.
---@overload fun(self: table, animation: nil, args: nil):Effect
---@param animation Anima
---@param args any
---@return Effect effect
function Effect:new(animation, args)

    local effect = {}
    setmetatable(effect, self)
    self.__index = self

    Effect.__constructor__(effect, animation, args)
    return effect
end

---
--- Class effect constructor.
---
---@param animation Anima
function Effect:__constructor__(animation, args)
    self.__id = Effect.TYPE.generic
    self.__color = { 1, 1, 1, 1 }
    self.__scale = { x = 1, y = 1 }
    self.__is_enabled = true
    self.__prior = 1
    self.__rad = 0
    self.__row = 0
    self.__anima = animation
    self.__args = args
    self.__remove = false
    self.__update_time = 0
    self.__duration = args and args.duration or nil
    self.__speed = 0.5
    self.__max_row = args and args.max_row or nil

    if animation then
        animation:__push()
        self.__config = animation.__configuration
        animation:__pop()
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

            self.__anima
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
    self.__row = 0
    self.__update_time = 0
end

function Effect:update(dt)
    return false
end

function Effect:__update__(dt)
    if not self.__duration then return end

    self.__update_time = self.__update_time + dt

    if self.__update_time >= self.__duration then
        self.__remove = true
    end
end

function Effect:restaure_animation()
    self.__anima.__configuration = self.__config
    self.__anima:__pop()
end

function Effect:draw(x, y)
    return false
end

---comment
---@param value number
function Effect:set_unique_id(value)
    self.__UNIQUE_ID = value
end

--- The unique identifiers.
---@return number
function Effect:get_unique_id()
    return self.__UNIQUE_ID
end

--- Restaure the effect in animation.
---@param restart boolean|nil
function Effect:restaure(restart)
    if restart then
        self:init()
        local r = self.__init and self:__init()
    end
    self.__anima.__effect_manager:__insert_effect(self)
end

--- Tells if this is a flash effect.
---@return boolean result
function Effect:is_flash()
    return self.__id == TYPE_.flash
end

return Effect

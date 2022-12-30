---@type JM.Utils
local Utils = require((...):gsub("templates.Affectable", "jm_utils"))

---@type JM.EffectManager
local EffectManager = require((...):gsub("templates.Affectable", "jm_effect_manager"))

local love_math_new_transform = love.math.newTransform
local love_graphics_apply_transform = love.graphics.applyTransform

---@alias JM.Effect.TransformObject {x: number, y: number, rot: number, sx: number, sy: number, ox: number, oy: number, kx: number, ky: number}

---@class JM.Template.Affectable
-- ---@field __effect_manager JM.EffectManager
-- -@field __effect_transform JM.Effect.TransformObject|nil
-- -@field set_color function
-- -@field get_color function
---@field set_visible function
local Affectable = {}

function Affectable:new()
    ---@type JM.Template.Affectable
    local obj = setmetatable({}, self)
    obj.__index = self

    obj:__constructor__()

    return obj
end

function Affectable:__constructor__()
    self.__color = Utils:get_rgba(1, 1, 1, 1)
    self.__effect_manager = EffectManager:new()
end

--- Check if object implements all the needed Affectable methods and fields.
---@param object table
function Affectable.__checks_implementation__(object)
    if not object then return end

    assert(object.__effect_manager, "\nError: The class do not have the required '__effect_manager' field.")

    assert(object.set_color, "\nError: The class do not implements the required 'set_color' method.")

    assert(object.set_visible,
        "\nError: The class do not implements the required 'set_visible' method.")

    assert(object.__draw__,
        "\nError: The class do not implements the required '__draw__' method.")

    assert(object.__get_effect_transform,
        "\nError: The class do not implements the required '__get_effect_transform' method.")

    assert(object.__set_effect_transform,
        "\nError: The class do not implements the required '__set_effect_transform' method.")
end

---@param object JM.Template.Affectable
---@param value JM.Color
function Affectable.set_color(object, value)
    -- if not value then return end
    -- if not object.__color then object.__color = {} end

    -- if value.r or value.g or value.b or value.a then
    --     object.__color = {
    --         value.r or object.__color[1],
    --         value.g or object.__color[2],
    --         value.b or object.__color[3],
    --         value.a or object.__color[4]
    --     }

    -- else -- color is in index format
    --     object.__color = {
    --         value[1] or object.__color[1],
    --         value[2] or object.__color[2],
    --         value[3] or object.__color[3],
    --         value[4] or object.__color[4]
    --     }
    -- end

    object.__color = Utils:get_rgba(1, 1, 1, 1)

    return object.__color
end

---@param self JM.Template.Affectable
function Affectable:set_color2(r, g, b, a)
    r = r or self.__color[1] or 1.0
    g = g or self.__color[2] or 1.0
    b = b or self.__color[3] or 1.0
    a = a or self.__color[4] or 1.0

    self.__color = Utils:get_rgba(r, g, b, a)
end

---@return JM.Color
function Affectable.get_color(object)
    return object.__color
end

---@param object JM.Template.Affectable
---@param arg JM.Effect.TransformObject
function Affectable.__set_effect_transform(object, arg)
    if not arg then
        object.__effect_transform = nil
        return
    end

    if not object.__effect_transform then
        object.__effect_transform = {}
    end

    object.__effect_transform = {
        x = arg.x or object.__effect_transform.x or 0,
        y = arg.y or object.__effect_transform.y or 0,
        rot = arg.rot or object.__effect_transform.rot or 0,
        sx = arg.sx or object.__effect_transform.sx or 1,
        sy = arg.sy or object.__effect_transform.sy or 1,
        ox = arg.ox or object.__effect_transform.ox or 0,
        oy = arg.oy or object.__effect_transform.oy or 0,
        kx = arg.kx or object.__effect_transform.kx or 0,
        ky = arg.ky or object.__effect_transform.ky or 0
    }
end

function Affectable:set_visible(value)
    self.is_visible = value and true or false
end

---@param object JM.Template.Affectable
---@return JM.Effect.TransformObject
function Affectable.__get_effect_transform(object)
    return object.__effect_transform
end

---@param x number
---@param y number
function Affectable.__draw__(object, x, y)
    return nil
end

---@param obj JM.Template.Affectable
---@param x number
---@param y number
function Affectable.apply_transform(obj, x, y)
    local eff_transf = obj:__get_effect_transform()

    if eff_transf then
        local transform = love_math_new_transform()

        transform:setTransformation(
            x + eff_transf.ox,
            y + eff_transf.oy,
            eff_transf.rot,
            eff_transf.sx,
            eff_transf.sy,
            x,
            y,
            eff_transf.kx,
            eff_transf.ky
        )

        love_graphics_apply_transform(transform)
    end
end

return Affectable

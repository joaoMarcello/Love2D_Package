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
Affectable.__index = Affectable

function Affectable:new()

    local obj = {}
    self.__index = self
    setmetatable(obj, self)

    Affectable.__constructor__(obj)

    return obj
end

function Affectable:__constructor__()
    self.color = Utils:get_rgba(1, 1, 1, 1)
    self.__effect_manager = EffectManager:new()
    self.__effect_transform = { ox = 0, oy = 0, rot = 0, sx = 1, sy = 1, kx = 0, ky = 0 }

    self.__transform = love.math.newTransform()
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
    object.color = value or Utils:get_rgba(1, 1, 1, 1)

    return object.color
end

---@param self JM.Template.Affectable
function Affectable:set_color2(r, g, b, a)
    r = r or self.color[1] or 1.0
    g = g or self.color[2] or 1.0
    b = b or self.color[3] or 1.0
    a = a or self.color[4] or 1.0

    self.color = Utils:get_rgba(r, g, b, a)
end

---@param object JM.Template.Affectable
---@return JM.Color
function Affectable.get_color(object)
    return object.color
end

---@param self JM.Template.Affectable
---@param arg JM.Effect.TransformObject
function Affectable:__set_effect_transform(arg)
    self.__effect_transform.x = arg.x or self.__effect_transform.x or 0
    self.__effect_transform.y = arg.y or self.__effect_transform.y or 0
    self.__effect_transform.rot = arg.rot or self.__effect_transform.rot or 0
    self.__effect_transform.sx = arg.sx or self.__effect_transform.sx or 1
    self.__effect_transform.sy = arg.sy or self.__effect_transform.sy or 1
    self.__effect_transform.ox = arg.ox or self.__effect_transform.ox or 0
    self.__effect_transform.oy = arg.oy or self.__effect_transform.oy or 0
    self.__effect_transform.kx = arg.kx or self.__effect_transform.kx or 0
    self.__effect_transform.ky = arg.ky or self.__effect_transform.ky or 0

    -- self.__transform:translate(self.__effect_transform.ox, self.__effect_transform.oy)
    -- self.__transform:rotate(self.__effect_transform.rot)
    -- self.__transform:scale(self.__effect_transform.sx, self.__effect_transform.sy)
end

function Affectable:set_effect_transform(index, value)
    if self.__effect_transform[index] then
        self.__effect_transform[index] = value
    end
end

function Affectable:set_visible(value)
    self.is_visible = value and true or false
end

---@param object JM.Template.Affectable
---@return JM.Effect.TransformObject
function Affectable.__get_effect_transform(object)
    return object.__effect_transform
end

function Affectable:__draw__(...)
    return
end

---@param self JM.Template.Affectable
function Affectable:apply_transform()
    local eff_transf = self:__get_effect_transform()

    if eff_transf then
        local transform = love_math_new_transform()

        transform:setTransformation(
            eff_transf.ox,
            eff_transf.oy,
            eff_transf.rot,
            eff_transf.sx,
            eff_transf.sy,
            0,
            0,
            eff_transf.kx,
            eff_transf.ky
        )

        love_graphics_apply_transform(transform)
    end
end

return Affectable

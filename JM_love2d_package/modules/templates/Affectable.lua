local EffectManager = require("/JM_love2d_package/modules/classes/EffectManager")

---@alias JM.Effect.TransformObject {x: number, y: number, rot: number, sx: number, sy: number, ox: number, oy: number, kx: number, ky: number}

---@class JM.Affectable
---@field __effect_manager JM.EffectManager
-- -@field __effect_transform JM.Effect.TransformObject|nil
-- -@field set_color function
-- -@field get_color function
---@field set_visible function
local Affectable = {}

--- Check if object implements all the needed Affectable methods and fields.
---@param object table
function Affectable.__checks_implementation__(object)
    if not object then return end

    assert(object.__effect_manager, "\nError: The class do not have the required '__effect_manager' field.")

    assert(object.set_color, "\nError: The class do not implements the required 'set_color' method.")

    -- assert(object.__push,
    --     "\nError: The class passed to Effect class constructor  do not implements the required '__push' method.")

    -- assert(object.__pop,
    --     "\nError: The class passed to Effect class constructor  do not implements the required '__pop' method.")

    -- assert(object.__set_configuration,
    --     "\nError: The class passed to Effect class constructor  do not implements the required '__set_configuration' method.")

    -- assert(object.__get_configuration,
    --     "\nError: The class passed to Effect class constructor  do not implements the required '__get_configuration' method.")

    assert(object.set_visible,
        "\nError: The class do not implements the required 'set_visible' method.")

    assert(object.__draw__,
        "\nError: The class do not implements the required '__draw__' method.")

    -- assert(object.set_scale,
    --     "\nError: The class passed to Effect class constructor  do not implements the required 'set_scale' method.")

    -- assert(object.get_scale,
    --     "\nError: The class passed to Effect class constructor  do not implements the required 'get_scale' method.")

    -- assert(object.set_rotation,
    --     "\nError: The class passed to Effect class constructor  do not implements the required 'set_rotation' method.")

    -- assert(object.get_rotation,
    --     "\nError: The class passed to Effect class constructor  do not implements the required 'get_rotation' method.")

    -- assert(object.get_origin,
    --     "\nError: The class passed to Effect class constructor  do not implements the required 'get_origin' method.")

    -- assert(object.set_kx,
    --     "\nError: The class passed to Effect class constructor  do not implements the required 'set_kx' method.")

    assert(object.__get_effect_transform,
        "\nError: The class do not implements the required '__get_effect_transform' method.")

    assert(object.__set_effect_transform,
        "\nError: The class do not implements the required '__set_effect_transform' method.")
end

---@param object JM.Affectable
---@param value JM.Color
function Affectable.set_color(object, value)
    if not value then return end
    if not object.__color then object.__color = {} end

    if value.r or value.g or value.b or value.a then
        object.__color = {
            value.r or object.__color[1],
            value.g or object.__color[2],
            value.b or object.__color[3],
            value.a or object.__color[4]
        }

    else -- color is in index format
        object.__color = {
            value[1] or object.__color[1],
            value[2] or object.__color[2],
            value[3] or object.__color[3],
            value[4] or object.__color[4]
        }
    end

    return object.__color
end

---@return JM.Color
function Affectable.get_color(object)
    return object.__color
end

---@param object JM.Affectable
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

---@param object JM.Affectable
---@return JM.Effect.TransformObject
function Affectable.__get_effect_transform(object)
    return object.__effect_transform
end

---@param x number
---@param y number
function Affectable.__draw__(object, x, y)
    return nil
end

---@param obj JM.Affectable
---@param x number
---@param y number
function Affectable.apply_transform(obj, x, y)
    local eff_transf = obj:__get_effect_transform()

    if eff_transf then
        local transform = love.math.newTransform()

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

        love.graphics.applyTransform(transform)
    end
end

return Affectable

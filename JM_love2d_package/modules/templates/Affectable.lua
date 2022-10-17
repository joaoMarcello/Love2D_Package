local EffectManager = require("/JM_love2d_package/modules/classes/EffectManager")

---@class JM.Affectable
---@field __effect_manager JM.EffectManager
---@field set_color function
---@field __push function
---@field __pop function
---@field set_visible function
---@field __draw__ function
---@field __set_configuration function
---@field __get_configuration function
---@field set_scale function
---@field get_scale function
---@field set_rotation function
---@field get_rotation function
---@field get_origin function
---@field set_kx function
---@field set_ky function
---@field __set_transform function
local Affectable = {}

--- Check if object implements all the needed Affectable methods and fields.
---@param object table
function Affectable.__checks_implementation__(object)
    if not object then return end

    assert(object.__effect_manager, "\nError: The class do not have the required '__effect_manager' field.")

    assert(object.set_color, "\nError: The class do not implements the required 'set_color' method.")

    assert(object.__push,
        "\nError: The class passed to Effect class constructor  do not implements the required '__push' method.")

    assert(object.__pop,
        "\nError: The class passed to Effect class constructor  do not implements the required '__pop' method.")

    assert(object.__set_configuration,
        "\nError: The class passed to Effect class constructor  do not implements the required '__set_configuration' method.")

    assert(object.__get_configuration,
        "\nError: The class passed to Effect class constructor  do not implements the required '__get_configuration' method.")

    assert(object.set_visible,
        "\nError: The class passed to Effect class constructor  do not implements the required 'set_visible' method.")

    assert(object.__draw__,
        "\nError: The class passed to Effect class constructor  do not implements the required '__draw__' method.")

    assert(object.set_scale,
        "\nError: The class passed to Effect class constructor  do not implements the required 'set_scale' method.")

    assert(object.get_scale,
        "\nError: The class passed to Effect class constructor  do not implements the required 'get_scale' method.")

    assert(object.set_rotation,
        "\nError: The class passed to Effect class constructor  do not implements the required 'set_rotation' method.")

    assert(object.get_rotation,
        "\nError: The class passed to Effect class constructor  do not implements the required 'get_rotation' method.")

    assert(object.get_origin,
        "\nError: The class passed to Effect class constructor  do not implements the required 'get_origin' method.")

    assert(object.set_kx,
        "\nError: The class passed to Effect class constructor  do not implements the required 'set_kx' method.")

    assert(object.set_ky,
        "\nError: The class passed to Effect class constructor  do not implements the required 'set_ky' method.")

    assert(object.__set_transform,
        "\nError: The class passed to Effect class constructor  do not implements the required '__set_transform' method.")
end

---@param color JM.Color
function Affectable:set_color(color)
end

function Affectable:__push()
end

function Affectable:__pop()
end

---@param value boolean
function Affectable:set_visible(value)
end

---@param x number
---@param y number
function Affectable:__draw__(x, y)
end

---@param config any
function Affectable:__set_configuration(config)
end

---@param scale JM.Point
function Affectable:set_scale(scale)
end

---@return table
function Affectable:get_scale()
    return {}
end

return Affectable

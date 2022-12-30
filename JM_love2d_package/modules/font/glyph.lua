---@type JM.Template.Affectable
local Affectable

---@type JM.EffectManager
local EffectManager

---@type JM.Utils
local Utils

---@class JM.Font.Glyph: JM.Template.Affectable
---@field __anima JM.Anima
local Glyph = {}

---@param affectable JM.Template.Affectable
---@param effect_manager JM.EffectManager
---@param utils JM.Utils
Glyph.load_dependencies = function(affectable, effect_manager, utils)
    Affectable = affectable
    EffectManager = effect_manager
    Utils = utils
end

---@return JM.Font.Glyph
function Glyph:new(img, quad, args)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Glyph.__constructor__(obj, img, quad, args)

    return obj
end

function Glyph:__constructor__(img, quad, args)
    assert(Affectable, "\n> Class Affectable not initialized!")
    assert(EffectManager, "\n> Class EffectManager not initialized!")

    self.__img = img
    self.__quad = quad
    self.__id = args.id or ""

    self.x = args.x
    self.y = args.y
    self.w = args.w
    self.h = args.h

    self.sy = args.sy or 1
    self.sx = self.sy

    self.qx = args.x
    self.qy = args.y
    self.qw = args.w
    self.qh = args.h

    self.__args = args

    if self.qy and self.qh then
        self.bottom = args.bottom or self.qy + self.qh
        self.offset_y = args.bottom and self.qy + self.qh - self.bottom or 0
        self.h = self.h - self.offset_y
    else
        self.bottom = nil
        self.offset_y = nil
    end

    self.__anima = args.anima

    self:set_color({ 1, 1, 1, 1 })

    self.ox = self.qx and self.qw / 2 or 0
    self.oy = self.qy and self.qh / 2 or 0

    self.__effect_manager = EffectManager:new()

    self.__visible = true

    self.bounds = { left = 0, top = 0, right = love.graphics.getWidth(), bottom = love.graphics.getHeight() }

    Affectable.__checks_implementation__(self)
end

function Glyph:update(dt)
    if self.__anima then
        self.__anima:update(dt)
    end

    self.__effect_manager:update(dt)
end

function Glyph:get_width()
    return self.w * self.sx
end

function Glyph:get_height()
    return self.h * self.sy
end

function Glyph:copy()
    local obj = Glyph:new(self.__img, self.__quad, self.__args)

    if obj.__anima then
        obj.__anima = obj.__anima:copy()
    end
    return obj
end

function Glyph:set_color(value)
    self.__color = Affectable.set_color(self, value)

    if self:is_animated() then
        self.__anima:set_color(self.__color)
    end
end

function Glyph:set_color2(r, g, b, a)
    r = r or self.__color[1]
    g = g or self.__color[2]
    b = b or self.__color[3]
    a = a or self.__color[4]

    self.__color = Utils:get_rgba(r, g, b, a)
    if self:is_animated() then
        self.__anima:set_color(self.__color)
    end
end

function Glyph:set_color3(color)
    self.__color = color
end

function Glyph:get_color()
    return Affectable.get_color(self)
end

---@param value number
function Glyph:set_scale(value)
    self.sy = value
    self.sx = self.sy
    -- if self:is_animated() then
    --     self.__anima:set_scale({ x = self.sx, y = self.sy })
    -- end
end

---@param value boolean|nil
function Glyph:set_visible(value)
    self.__visible = value
end

function Glyph:__set_effect_transform(arg)
    return Affectable.__set_effect_transform(self, arg)
end

function Glyph:__get_effect_transform()
    return Affectable.__get_effect_transform(self)
end

---@return {x: number, y: number}
function Glyph:get_origin()
    return { x = self.ox, y = self.oy }
end

function Glyph:is_animated()
    return self.__anima and true or false
end

function Glyph:setViewport(img, quad, x, y)
    local qx = self.qx
    local qy = self.qy
    local qw = self.qw
    local qh = self.qh

    local bottom = self.bounds.top + self.bounds.bottom
    local top = self.bounds.top

    -- if y and bottom then
    --     if y + self.h * self.sy > bottom then
    --         qh = self.h - ((y + self.h * self.sy) - bottom) / self.sy
    --     end
    -- end

    quad:setViewport(
        qx, qy,
        qw, qh,
        img:getWidth(), img:getHeight()
    )
end

function Glyph:draw(x, y)
    self:__draw__(x, y)
    self.__effect_manager:draw(x, y)
end

function Glyph:draw_rec(x, y, w, h)
    x = x + w / 2
    y = y + h - self.h * self.sy + self.oy * self.sy

    self:__draw__(x, y)
end

local love_graphics = love.graphics
local love_graphics_draw = love_graphics.draw
local love_graphics_rectangle = love_graphics.rectangle
local love_graphics_set_color = love_graphics.setColor
local love_graphics_push = love_graphics.push
local love_graphics_pop = love_graphics.pop
local love_graphics_apply_transform = love_graphics.applyTransform
local love_math_new_transform = love.math.newTransform

function Glyph:__draw__(x, y)
    -- if self.__id == "__nule__" then return end

    love_graphics_push()

    local eff_transf = self:__get_effect_transform()

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

    if self.__anima then
        self.__anima:draw(x, y)

    elseif not self.__img then

        love_graphics_set_color(0, 0, 0, 0.2)
        love_graphics_rectangle("fill", x, y,
            self.w * self.sx,
            self.h * self.sy
        )

    elseif self.__id ~= "\t" and self.__id ~= " " then
        love_graphics_set_color(self:get_color())

        self:setViewport(self.__img, self.__quad, x, y)

        love_graphics_draw(self.__img, self.__quad,
            x,
            y,
            0,
            self.sx, self.sy,
            self.ox, self.oy
        )

    end

    love_graphics_pop()


    -- if self.w and self.h then
    --     love.graphics.setColor(0, 0, 0, 0.4)
    --     love.graphics.rectangle("line", x - self.ox * self.sx, y - self.oy * self.sy, self.w * self.sx, self.h * self.sy)
    -- end
end

return Glyph

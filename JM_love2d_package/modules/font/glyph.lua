local love_graphics = love.graphics
local love_graphics_draw = love_graphics.draw
local love_graphics_rectangle = love_graphics.rectangle
local love_graphics_set_color = love_graphics.setColor

---@type JM.Template.Affectable
local Affectable = require((...):gsub("font.glyph", "templates.Affectable"))

---@class JM.Font.Glyph: JM.Template.Affectable
local Glyph = setmetatable({}, Affectable)
Glyph.__index = Glyph

---@return JM.Font.Glyph
function Glyph:new(img, quad, args)
    local obj = Affectable:new(self.__glyph_draw__)
    setmetatable(obj, self)

    Glyph.__constructor__(obj, img, quad, args)

    return obj
end

function Glyph:__constructor__(img, quad, args)
    --assert(Affectable, "\n> Class Affectable not initialized!")
    --assert(EffectManager, "\n> Class EffectManager not initialized!")

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

    ---@type JM.Anima
    self.__anima = args.anima

    self:set_color2(1, 1, 1, 1)

    self.ox = self.qx and self.qw / 2 or 0
    self.oy = self.qy and self.qh / 2 or 0

    self.bounds = { left = 0, top = 0, right = love.graphics.getWidth(), bottom = love.graphics.getHeight() }

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

---@param value JM.Color
function Glyph:set_color(value)
    self.color = Affectable.set_color(self, value)

    if self:is_animated() then
        self.__anima:set_color(self.color)
    end
end

function Glyph:set_color2(r, g, b, a)
    Affectable.set_color2(self, r, g, b, a)

    if self:is_animated() then
        self.__anima:set_color(self.color)
    end
end

---@param value number
function Glyph:set_scale(value)
    self.sy = value
    self.sx = self.sy
    -- if self:is_animated() then
    --     self.__anima:set_scale({ x = self.sx, y = self.sy })
    -- end
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

    self.x, self.y = x, y

    Affectable.draw(self)
end

function Glyph:draw_rec(x, y, w, h)
    x = x + w / 2
    y = y + h - self.h * self.sy + self.oy * self.sy

    self:draw(x, y)
end

function Glyph:__glyph_draw__()
    -- if self.__id == "__nule__" then return end

    if not self.is_visible then return end
    local x, y = self.x, self.y

    if self.__anima then
        self.__anima:draw(x, y)

    elseif not self.__img then

        love_graphics_set_color(0, 0, 0, 0.2)
        love_graphics_rectangle("fill", x, y,
            self.w * self.sx,
            self.h * self.sy
        )

    elseif self.__id ~= "\t" and self.__id ~= " " then
        love_graphics_set_color(self.color)

        self:setViewport(self.__img, self.__quad, x, y)

        love_graphics_draw(self.__img, self.__quad,
            x,
            y,
            0,
            self.sx, self.sy,
            self.ox, self.oy
        )

    end

    -- if self.w and self.h then
    --     love.graphics.setColor(0, 0, 0, 0.4)
    --     love.graphics.rectangle("line", x - self.ox * self.sx, y - self.oy * self.sy, self.w * self.sx, self.h * self.sy)
    -- end
end

return Glyph

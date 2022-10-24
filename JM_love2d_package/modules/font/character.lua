local Affectable = require("/JM_love2d_package/modules/templates/Affectable")
local EffectManager = require("/JM_love2d_package/modules/classes/EffectManager")

---@class JM.Font.Character: JM.Affectable
---@field __anima JM.Anima
local Character = {}

---@return JM.Font.Character
function Character:new(img, quad, args)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Character.__constructor__(obj, img, quad, args)

    return obj
end

function Character:__constructor__(img, quad, args)
    self.__img = img
    self.__quad = quad
    self.__id = args.id

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

function Character:update(dt)
    if self.__anima then
        self.__anima:update(dt)
    end

    self.__effect_manager:update(dt)
end

function Character:get_width()
    return self.w * self.sx
end

function Character:get_height()
    return self.h * self.sy
end

function Character:copy()
    local obj = Character:new(self.__img, self.__quad, self.__args)

    if obj.__anima then
        obj.__anima = obj.__anima:copy()
    end
    return obj
end

function Character:set_color(value)
    self.__color = Affectable.set_color(self, value)
end

function Character:get_color()
    return Affectable.get_color(self)
end

---@param value number
function Character:set_scale(value)
    self.sy = value
    self.sx = self.sy
    -- if self:is_animated() then
    --     self.__anima:set_scale({ x = self.sx, y = self.sy })
    -- end
end

---@param value boolean|nil
function Character:set_visible(value)
    self.__visible = value
end

function Character:__set_effect_transform(arg)
    return Affectable.__set_effect_transform(self, arg)
end

function Character:__get_effect_transform()
    return Affectable.__get_effect_transform(self)
end

---@return {x: number, y: number}
function Character:get_origin()
    return { x = self.ox, y = self.oy }
end

function Character:is_animated()
    return self.__anima and true or false
end

function Character:setViewport(img, quad, x, y)
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

function Character:draw(x, y)
    self:__draw__(x, y)
    self.__effect_manager:draw(x, y)
end

function Character:draw_rec(x, y, w, h)
    x = x + w / 2
    y = y + h - self.h * self.sy + self.oy * self.sy

    self:__draw__(x, y)
end

function Character:__draw__(x, y)
    -- if self.__id == "__nule__" then return end

    love.graphics.push()

    local eff_transf = self:__get_effect_transform()

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

    if self.__anima then
        self.__anima:draw(x, y)

    elseif not self.__img then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", x - self.w / 2 * self.sx, y,
            self.w * self.sx,
            self.h * self.sy
        )

    elseif self.__id ~= "\t" and self.__id ~= " " then
        love.graphics.setColor(self:get_color())

        self:setViewport(self.__img, self.__quad, x, y)

        -- love.graphics.draw(self.__img, self.__quad,
        --     x + self.w / 2 * self.sx,
        --     y + (self.h + self.offset_y) / 2 * self.sy,
        --     0,
        --     self.sx, self.sy,
        --     self.ox, self.oy
        -- )

        love.graphics.draw(self.__img, self.__quad,
            x,
            y,
            0,
            self.sx, self.sy,
            self.ox, self.oy
        )

    end

    love.graphics.pop()

    love.graphics.setColor(0, 0, 0, 0.5)

    if self.w and self.h then
        -- love.graphics.rectangle("fill", x - self.ox * self.sx, y - self.oy * self.sy, self.w * self.sx, self.h * self.sy)
    end
end

return Character

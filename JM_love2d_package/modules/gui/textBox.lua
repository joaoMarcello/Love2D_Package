---@type JM.Font.Phrase
local Phrase = require((...):gsub("gui.textBox", "font.Phrase"))

---@class JM.GUI.TextBox
local TextBox = {}
TextBox.__index = TextBox

function TextBox:new(text, font, x, y, w, h)
    local obj = setmetatable({}, self)
    TextBox.__constructor__(obj, { text = text, x = x, y = y, font = font }, w, h)
    return obj
end

function TextBox:__constructor__(args, w, h)
    self.sentence = Phrase:new(args)
    self.sentence:set_bounds(nil, nil, args.x + w)
    self.lines = self.sentence:get_lines(self.sentence.x, true)

    self.align = "left"
    self.x = self.sentence.x
    self.y = self.sentence.y
    self.w = w
    self.h = h
    self.is_visible = true

    self.cur_glyph = 0
    self.time_glyph = 0.0
    self.max_time_glyph = 0.05
    self.extra_time = 0.0
end

function TextBox:rect()
    return self.x, self.y, self.w, self.h
end

function TextBox:update(dt)
    self.sentence:update(dt)

    if love.keyboard.isDown("a") then self.cur_glyph = nil end

    self.time_glyph = self.time_glyph + dt

    if self.time_glyph >= (self.max_time_glyph + self.extra_time) then

        self.time_glyph = self.time_glyph - self.max_time_glyph
            - self.extra_time

        if self.cur_glyph then
            self.cur_glyph = self.cur_glyph + 1
        end
    end

end

local Font = _G.JM_Font
function TextBox:draw()
    local x, y = self.sentence.x, self.sentence.y

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", self:rect())

    local tx, ty, glyph = self.sentence:draw_lines(self.lines, x, y, self.align, nil,
        self.cur_glyph)

    if glyph then
        local id = glyph.__id

        if id:match("[%.;]") or id == "--dots--" then
            self.extra_time = 0.8
        elseif id:match("[,?!]") or id == "--dots--" then
            self.extra_time = 0.2
        else
            self.extra_time = 0.0
        end
    end

    self.__finish = not tx

    Font:print(self.__finish and "<color>true" or "<color, 1, 1, 1>false", self.x, self.y - 20)
end

function TextBox:finished()
    return self.__finish
end

return TextBox

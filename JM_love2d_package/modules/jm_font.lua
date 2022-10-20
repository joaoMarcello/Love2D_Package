local EffectManager = require("/JM_love2d_package/modules/classes/EffectManager")
local Affectable = require("/JM_love2d_package/modules/templates/Affectable")
local Character = require("/JM_love2d_package/modules/font/character")
local Utils = require("/JM_love2d_package/utils")
local Anima = require "/JM_love2d_package/animation_module"

---@class JM.Font.Font: JM.Affectable
local Font = {}

---@return JM.Font.Font new_Font
function Font:new(args)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Font.__constructor__(obj, args)

    return obj
end

local Animation = Anima:new({
    img = "/data/goomba.png",
    duration = 1,
    height = 100,
    flip_x = true,
    flip_y = false,
    is_reversed = false,
    state = "looping",
    -- color = { 0, 0, 1, 1 },
    frames_list = {
        { 27, 18, 58, 70 },
        { 151, 21, 58, 68 },
        { 272, 21, 59, 68 },
        { 392, 25, 68, 63 },
        { 517, 26, 61, 63 },
        { 638, 25, 57, 63 },
        { 765, 24, 56, 65 },
        { 889, 27, 55, 61 },
        { 1007, 26, 63, 62 }
    }
})

function Font:__constructor__(args)
    self.__img = love.graphics.newImage("/JM_love2d_package/data/Font/calibri/calibri.png")
    self.__img:setFilter("linear", "nearest")

    self.__quad = love.graphics.newQuad(
        0, 0,
        20, 20,
        self.__img:getDimensions()
    )

    self.__font_size = 30

    self.character_space = 2
    self.line_space = 20
    self.__characters = {}

    local lines = Utils:getLines("/JM_love2d_package/data/Font/Calibri/calibri.txt")

    for i = 2, #lines do
        local parse = Utils:parse_csv_line(lines[i], ",")
        local id = (parse[1])
        local x = tonumber(parse[2])
        local y = tonumber(parse[3])
        local w = tonumber(parse[4])
        local h = tonumber(parse[5])
        local bottom = tonumber(parse[6])

        table.insert(self.__characters,
            Character:new(self.__img, self.__quad,
                { id = id, x = x, y = y, w = w, h = h, bottom = bottom })
        )
    end

    self.ref_height = self:get_equals("A").h or self:get_equals("0").h
    self.word_space = self.ref_height * 0.6
    self.tab_size = 4


    local sy = Utils:desired_size(nil, self.__font_size, nil, self.ref_height, true).y

    self.scale = sy

    -- self.__characters[2].__anima = Animation
    -- Animation:set_size(nil, self.__font_size, nil, 69)
    -- Animation:apply_effect("float", { range = 5 })
end

function Font:update(dt)
    local character = self:get_equals("A")
    local r = character and character:update(dt)
end

---@return JM.Font.Character|nil
function Font:get_char(index)
    return self.__characters[index]
end

---@return JM.Font.Character|nil|JM.Affectable
function Font:get_equals(c)
    for i = 1, #self.__characters do
        if c == self:get_char(i).__id then
            return self:get_char(i)
        end
    end
    return nil
end

---@param text string
---@param x any
---@param y any
function Font:print(text, x, y, w, h)
    local tx = x
    local ty = y

    local jump = -1
    local jumped = 0

    for i = 1, #text do
        if jump > 0 then
            jump = jump - 1
            goto continue
        end

        local current_char = text:sub(i, i)
        local prev_char = text:sub(i - 1 - jumped, i - 1 - jumped)
        local next_char = text:sub(i + 1, i + 1)

        local character = self:get_equals(current_char)
        local last = self:get_equals(prev_char)
        local next = self:get_equals(next_char)

        local last_w = last and last.w
            or (prev_char == " " and self.word_space)
            or (prev_char) == "\t"
            and self.word_space * self.tab_size

        if jump == 0 then
            jump = -1
            jumped = 0
        end

        local next_w = (next and next.w) or (next_char) == " " and self.word_space

        local wc = character and last_w
            and character.w * self.scale + last_w * self.scale
            or nil

        -- TAB
        if current_char == "\t" then
            tx = tx + (self.word_space * self.scale * 4)

            if w and tx + (next_w and next_w * self.scale or 0) + self.character_space * 2 > w then
                tx = x
                ty = ty + self.line_space + self.ref_height * self.scale
            end
        end

        local condition_1 = current_char == "\n"
        local condition_2 = w and wc
            and tx + wc + (self.character_space * 2) > w

        -- Broken line or current x position is bigger than desired width.
        if condition_1 or condition_2 then

            ty = ty + self.line_space + self.ref_height * self.scale
            tx = x

            -- Current char is "\n"
            if condition_1 then
                goto continue
            else -- Current x position is bigger than desired width
                last_w = false
            end
        end

        -- Space
        if current_char == " " then
            tx = tx + self.word_space * self.scale + (last_w and last_w * self.scale or 0)
            goto continue
        end

        -- Updating the x position to draw
        if last_w and character then
            tx = tx + self.character_space + last_w * self.scale
        end

        if character then
            character:set_scale(self.scale)
            character:__draw__(tx, ty + self.__font_size - character.h * self.scale)
        end

        ::continue::
    end
end

return Font

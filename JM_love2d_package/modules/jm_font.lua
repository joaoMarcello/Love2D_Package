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

local goomba = "<goomba>"

function Font:__constructor__(args)
    self.__img = love.graphics.newImage("/JM_love2d_package/data/Font/calibri/calibri.png")
    self.__img:setFilter("linear", "nearest")

    self.__quad = love.graphics.newQuad(
        0, 0,
        20, 20,
        self.__img:getDimensions()
    )

    self.__font_size = 20

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
    self.word_space = self.ref_height * 0.3
    self.tab_size = 4


    local sy = Utils:desired_size(nil, self.__font_size, nil, self.ref_height, true).y

    self.scale = sy

    local anim_char = Character:new(self.__img, self.__quad, { id = goomba, x = 78, y = 33, w = 64, h = 75 })
    anim_char.__anima = Animation
    Animation:apply_effect("flash")
    Animation:apply_effect("float", { range = 5 })
    Animation:set_size(nil, self.__font_size, nil, 69)

    table.insert(self.__characters, anim_char)
end

---@param s string
local function is_identifier(s, index)
    local identifier = goomba

    if s:sub(index, index + #identifier - 1) == identifier then
        return identifier
    end
end

---@param s string
---@param index number
local function is_command(s, index)
    local command = "color"

    if s:sub(index, index) == "<" then
        local startp, endp = s:find(">", index)

        if startp then
            local start2, endp2 = s:find("</color>", endp)
            if start2 then
                local command_line = s:sub(index + 1, endp - 1)
                local parse = Utils:parse_csv_line(command_line)

                if parse[1] == command then
                    local color = {
                        tonumber(parse[2]),
                        tonumber(parse[3]),
                        tonumber(parse[4]),
                        1
                    }
                    return {
                        color = color,
                        start1 = index,
                        start2 = start2,
                        final1 = endp,
                        final2 = endp2
                    }
                end
            end

        end
    end
end

function Font:update(dt)
    local character = self:get_equals(goomba)
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
    local last_was_identifier = nil
    local color = { 0, 0, 0, 1 }
    local result_color = nil

    for i = 1, #text do
        if jump > 0 then
            jump = jump - 1
            goto continue
        end

        local current_char = text:sub(i, i)
        local prev_char = text:sub(i - 1 - jumped, i - 1 - jumped)
        local next_char = text:sub(i + 1, i + 1)

        local result = is_identifier(text, i)

        if result then
            current_char = result
        end

        if last_was_identifier then
            prev_char = last_was_identifier
            last_was_identifier = nil
        end

        local color_change = is_command(text, i)
        if color_change then
            result_color = color_change
            if result_color then
                color = result_color.color
                jump = result_color.final1 - result_color.start1
                -- jump = 15
                jumped = jump
                goto continue
            end
        end

        if result_color then
            color = result_color.color

            if i > result_color.final2 then
                color = { 0, 0, 0, 1 }
                result_color = nil
            elseif i >= result_color.start2 then
                jump = result_color.final2 - result_color.start2
                jumped = jump
                goto continue
            end

        end

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
            tx = tx + (self.word_space * self.scale * self.tab_size)

            if w and next_w and tx + (next_w * self.scale) + self.character_space * 2 > w then
                tx = x
                ty = ty + self.line_space + self.ref_height * self.scale
            end
        end

        local condition_1 = current_char == "\n"
        local condition_2 = w and character and last_w
            and tx + character.w * self.scale + last_w * self.scale + (self.character_space * 2) > w

        -- w and wc
        --     and tx + wc + (self.character_space * 2) > w

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
            character:set_color(color)

            character:set_scale(self.scale)
            character:__draw__(tx, ty + self.__font_size - character.h * self.scale)
        end

        if result then
            jump = #result - 1
            jumped = jump
            last_was_identifier = result
        end

        ::continue::
    end
end

return Font

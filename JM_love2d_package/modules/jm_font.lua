local EffectManager = require("/JM_love2d_package/modules/classes/EffectManager")
local Affectable = require("/JM_love2d_package/modules/templates/Affectable")
local Character = require("/JM_love2d_package/modules/font/character")
local Utils = require("/JM_love2d_package/utils")

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

function Font:__constructor__(args)
    self.__img = love.graphics.newImage("/JM_love2d_package/data/Font/Calibri/calibri.png")

    self.__quad = love.graphics.newQuad(
        0, 0,
        20, 20,
        self.__img:getDimensions()
    )

    self.__font_size = 30
    self.__sy = 0.3

    self.word_space = 40
    self.space_between_char = 2
    self.space_between_lines = 20
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
                { id = id, x = x, y = y, w = w, h = h, sy = self.__sy })
        )
    end

    self.ref_height = self:get_equals("A").h

    local sy = Utils:desired_size(nil, self.__font_size, nil, self.ref_height, true).y

    self.__sy = sy
end

function Font:update(dt)
    local character = self:get_char(1)
    character:update(dt)
end

---@return JM.Font.Character
function Font:get_char(index)
    return self.__characters[index]
end

---@return JM.Font.Character|nil
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
    for i = 1, #text do

        local character = self:get_equals(text:sub(i, i))
        local last = self:get_equals(text:sub(i - 1, i - 1))
        local wc = character and character.w * self.__sy or nil

        if text:sub(i, i) == "\n" or (w and wc and tx + wc + (self.space_between_char * 2) >= w) then
            ty = ty + self.space_between_lines + self.ref_height * self.__sy
            tx = x
            if text:sub(i, i) == "\n" then
                goto continue
            else
                last = nil
            end
        end

        if text:sub(i, i) == " " then
            tx = tx + self.word_space * self.__sy + self.ref_height * self.__sy * 0.7
            goto continue
        end


        if last and character then
            tx = tx + self.space_between_char + last.w * self.__sy
        end

        if character then
            character:set_scale(self.__sy)
            character:__draw__(tx, ty + self.__font_size - character.h * self.__sy)
        end

        ::continue::
    end
end

return Font

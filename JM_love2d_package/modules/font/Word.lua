---@class JM.Font.Word
local Word = {}

---@param args {text: string, font: JM.Font.Font}
---@return JM.Font.Word phrase
function Word:new(args)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Word.__constructor__(obj, args)

    return obj
end

---@param args {text: string, font: JM.Font.Font}
function Word:__constructor__(args)
    self.__text = args.text
    self.__font = args.font
    self.__font_config = self.__font:__get_configuration()

    self.__characters = {}
    for i = 1, #self.__text do
        local cur_char = self.__text:sub(i, i)
        local char_obj = self.__font:__get_char_equals(cur_char)
        if char_obj then
            char_obj = char_obj:copy()
            table.insert(self.__characters, char_obj)
        end
    end
end

---@param index number
---@return JM.Font.Character
function Word:__get_char_by_index(index)
    return self.__characters[index]
end

function Word:get_width()
    local w = 0

    for i = 1, #self.__characters do
        local cur_char = self:__get_char_by_index(i)
        w = w + (cur_char.w * self.__font.__scale)
            + self.__font.__character_space
    end

    return w
end

function Word:get_height()
    local h = self.__font.__font_size + self.__font.__line_space
    return h
end

function Word:draw(x, y)
    local tx = x
    for i = 1, #self.__characters do
        local cur_char = self:__get_char_by_index(i)
        cur_char:set_color(self.__font.__default_color)
        cur_char:set_scale(self.__font.__scale)
        cur_char:__draw__(tx, y + self.__font.__font_size - cur_char.h * cur_char.sy)

        tx = tx + cur_char.w * self.__font.__scale + self.__font.__character_space
    end

    love.graphics.setColor(1, 0, 0, 0.3)
    love.graphics.rectangle("fill", x, y, self:get_width(), self.__font.__font_size)

    -- self.__font:print(tostring(#self.__characters), x, y)
end

return Word

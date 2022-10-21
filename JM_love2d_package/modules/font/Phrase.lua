local Word = require("/JM_love2d_package/modules/font/Word")

---@class JM.Font.Phrase
local Phrase = {}

---@param args {text: string, font: JM.Font.Font}
---@return JM.Font.Phrase phrase
function Phrase:new(args)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Phrase.__constructor__(obj, args)

    return obj
end

---@param args {text: string, font: JM.Font.Font}
function Phrase:__constructor__(args)
    self.__text = args.text
    self.__font = args.font
    self.__font_config = self.__font:__get_configuration()

    self.__separated_string = self:separate_string(self.__text)
    self.__words = {}

    self.__bounds = { top = 0, left = 0, height = love.graphics.getHeight(), right = love.graphics.getWidth() }

    for i = 1, #self.__separated_string do
        local w = Word:new({ text = self.__text, font = self.__font })
        table.insert(self.__words, w)
    end

end

---@return JM.Font.Word
function Phrase:get_word_by_index(index)
    return self.__words[index]
end

function Phrase:get_lines(x, y)
    local lines = {}
    local total_w = 0
    local index = 1

    for i = 1, #self.__words do
        local word = self:get_word_by_index(i)
        if total_w + word:get_width() > self.__bounds.right then
            local new_line = {}

            for j = i, index, -1 do
                table.insert(new_line, self:get_word_by_index(j))
            end
            index = i + 1
        end
    end
end

---@param text string
---@param index number
---@return {start:number, final:number, tag:string}|nil
local function is_a_tag(text, index)
    if text:sub(index, index) == "<" then
        local startp, endp = text:find(">", index + 1)
        if startp then
            return { start = startp, final = endp, tag = text:sub(index, endp) }
        end
    end
end

function Phrase:separate_string(s)
    local words = {}
    local sep = " "
    local i = 1
    local current_index = 1

    while (i <= #s) do
        local current_char = s:sub(i, i)

        if current_char == sep then
            local w = s:sub(current_index, i - 1)
            if w ~= "" and w ~= " " then
                table.insert(words, w)
            end

            current_index = i + 1
            i = current_index
        end

        if current_char == "\n" then
            local w = s:sub(current_index, i - 1)
            if w ~= "" and w ~= " " then
                table.insert(words, w)
            end

            table.insert(words, "\n")
            current_index = i + 1
        end

        local r = is_a_tag(s, i)
        if r then
            table.insert(words, r.tag)
            current_index = r.final + 1
            i = current_index
        end

        local r2 = self.__font:__is_a_nickname(s, current_index)
        if r2 then
            table.insert(words, s:sub(current_index, current_index + #r2 - 1))
            current_index = current_index + #r2
            i = current_index
        end

        i = i + 1
    end

    table.insert(words, s:sub(current_index, #s))
    return words
end

function Phrase:draw(x, y)
    for i = 1, #self.__words do
        local w = self:get_word_by_index(i)

        w:draw(x, y + (i - 1) * self.__font.__font_size + 3)
    end
end

return Phrase

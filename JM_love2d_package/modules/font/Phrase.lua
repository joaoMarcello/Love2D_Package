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

    self.__bounds = { top = 0, left = 0, height = love.graphics.getHeight(), right = 600 }

    for i = 1, #self.__separated_string do
        local w = Word:new({ text = self.__separated_string[i], font = self.__font })
        table.insert(self.__words, w)
    end

end

---@return JM.Font.Word
function Phrase:get_word_by_index(index)
    return self.__words[index]
end

function Phrase:get_lines(x, y)
    local lines = {}
    for j = 1, 10 do
        table.insert(lines, {})
    end
    local tx = x
    local index = 1
    local cur_line = 1

    for i = 1, #self.__words do
        local w = self:get_word_by_index(i)

        local r = w:get_width() + (self.__font.__word_space * self.__font.__scale)

        if tx + r > self.__bounds.right then
            tx = x
            cur_line = cur_line + 1
            -- ty = ty + (self.__font.__font_size + self.__font.__line_space)
        end
        table.insert(lines[cur_line], w)
        tx = tx + r
    end

    -- for i = 1, #self.__words do
    --     if not lines[cur_line] then lines[cur_line] = {} end

    --     local word = self:get_word_by_index(i)

    --     local r = total_w + (self.__font.__word_space * self.__font.__scale)
    --         + word:get_width()

    --     if r > self.__bounds.right then
    --         cur_line = cur_line + 1
    --         total_w = x
    --         if not lines[cur_line] then lines[cur_line] = {} end
    --         table.insert(lines[cur_line], word)
    --     else
    --         table.insert(lines[cur_line], word)
    --         total_w = r
    --     end

    -- end -- END FOR each word in table or words

    return lines
end -- END function get_lines()

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
            i = current_index - 1
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
    local lines = self:get_lines(x, y)

    local tx, ty = x, y

    for i = 1, #lines do
        for j = 1, #lines[i] do
            local w = lines[i][j]
            local r = w:get_width() + (self.__font.__word_space * self.__font.__scale)

            w:draw(tx, ty)
            tx = tx + r
        end
        tx = x
        ty = ty + (self.__font.__font_size + self.__font.__line_space)
    end


    ------------------------------------------------------------------------
    -- local tx = x - 200
    -- local ty = y

    -- for i = 1, #self.__words do
    --     local w = self:get_word_by_index(i)

    --     local r = w:get_width() + (self.__font.__word_space * self.__font.__scale)

    --     if tx + r > self.__bounds.right then
    --         tx = x - 200
    --         ty = ty + (self.__font.__font_size + self.__font.__line_space)
    --     end
    --     w:draw(tx, ty)
    --     tx = tx + r
    -- end
end

return Phrase

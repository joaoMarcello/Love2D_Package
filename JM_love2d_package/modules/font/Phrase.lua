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

    self.__bounds = { top = 0, left = 0, height = love.graphics.getHeight(), right = love.graphics.getWidth() - 100 }

    for i = 1, #self.__separated_string do
        local w = Word:new({ text = self.__separated_string[i], font = self.__font })
        if w.__text ~= "" then
            table.insert(self.__words, w)
        end
    end

end

---@return JM.Font.Word
function Phrase:get_word_by_index(index)
    return self.__words[index]
end

function Phrase:get_lines(x, y)
    local lines = {}
    local tx = x
    local cur_line = 1
    local word_char = Word:new({ text = " ", font = self.__font })

    for i = 1, #self.__words do
        local current_word = self:get_word_by_index(i)
        local next_word = self:get_word_by_index(i + 1)

        local r = current_word:get_width()
            + word_char:get_width()

        if tx + r > self.__bounds.right
            or current_word.__text == "\n" then

            tx = x

            -- Try remove the last added space word
            if pcall(function()
                local last_added = self:__get_word_in_list(lines[cur_line], #lines[cur_line])

                if last_added.__text ~= "\n"
                    and last_added.__text ~= "\t"
                    and not self.__font:__is_a_nickname(last_added.__text, 1) then

                    table.remove(lines[cur_line], #lines[cur_line])
                end
            end
            ) then
                cur_line = cur_line + 1
            end
        end

        if not lines[cur_line] then lines[cur_line] = {} end

        if current_word.__text ~= "\n" then
            table.insert(lines[cur_line], current_word)
        elseif next_word.__text ~= "\n" then
            table.insert(lines[cur_line - 1], current_word)
        else
            table.insert(lines[cur_line], current_word)
            table.insert(lines[cur_line - 1], current_word)
        end

        if i ~= #self.__words
            and current_word.__text ~= "\t"
            and current_word.__text ~= "\n"
            and next_word and next_word.__text ~= "\t" then

            table.insert(lines[cur_line], word_char)
        end
        tx = tx + r
    end

    table.insert(lines[cur_line], Word:new({ text = "\n", font = self.__font }))

    return lines
end -- END function get_lines()

---@return JM.Font.Word
function Phrase:__get_word_in_list(list, index)
    return list[index]
end

function Phrase:__line_length(line)
    local total_len = 0

    for i = 1, #line do
        local word = self:__get_word_in_list(line, i)
        total_len = total_len + word:get_width()
    end

    return total_len
end

-- ---@param text string
-- ---@param index number
-- ---@return {start:number, final:number, tag:string}|nil
-- local function is_a_tag(text, index)
--     local command = "color"

--     if text:sub(index, index) == "<" then
--         local startp, endp = text:find(">", index + 1)
--         if startp then
--             -- local start2, endp2 = text:find("</" .. command .. ">", endp)
--             -- if start2 then
--             return { start = startp, final = endp, tag = text:sub(index, endp) }
--             -- end
--         end
--     end
-- end

-- ---@param lines table
-- ---@param cur_line number
-- ---@param cur_column number
-- ---@return {init: number, final: number, tag: string}|nil
-- function Phrase:__is_a_command(lines, cur_line, cur_column)
--     local t = 0
--     for i = 1, cur_line - 1, 1 do
--         t = t + #lines[i]
--     end

--     local cur_index = t + cur_column
--     local r = is_a_tag(self:get_word_by_index(cur_index).__text, 0)
--     if r then
--         for i = cur_index + 1, #self.__words, 1 do
--             local r2 = is_a_tag(self:get_word_by_index(i).__text, 0)
--             if r2 and r2.tag == ("/" .. r.tag) then
--                 return { init = cur_index, final = i, tag = r2.tag }
--             end
--         end
--     end
-- end

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
            -- table.insert(words, current_char)
            current_index = i + 1
        end

        local r2 = self.__font:__is_a_nickname(s, i)
        if r2 then
            local w = s:sub(current_index, i - 1)
            if w ~= "" and w ~= " " then
                table.insert(words, w)
            end
            table.insert(words, s:sub(i, i + #r2 - 1))
            current_index = i + #r2
            i = current_index - 1
        end

        if current_char == "\n" or current_char == "\t" then
            local w = s:sub(current_index, i - 1)
            if w ~= "" and w ~= " " then
                table.insert(words, w)
            end

            table.insert(words, current_char)
            current_index = i + 1
        end

        -- local r = is_a_tag(s, i)
        -- if r then
        --     local w = s:sub(current_index, i - 1)
        --     if w ~= "" and w ~= " " then
        --         table.insert(words, w)
        --     end

        --     table.insert(words, r.tag)
        --     current_index = r.final + 1
        --     i = current_index - 1
        -- end



        i = i + 1
    end

    table.insert(words, s:sub(current_index, #s))
    return words
end

function Phrase:update(dt)
    for i = 1, #self.__words, 1 do
        local w = self:__get_word_in_list(self.__words, i)
        w:update(dt)
    end
end

---@param x number
---@param y number
---@param mode "left"|"right"|"center"|"justified"|nil
function Phrase:draw(x, y, mode)
    if x >= self.__bounds.right then return end

    local lines = self:get_lines(x, y)

    if not mode then mode = "left" end

    local tx, ty = x, y
    local space = 0

    self.__font:push()

    for i = 1, #lines do
        if mode == "right" then

            tx = self.__bounds.right - self:__line_length(lines[i])

        elseif mode == "center" then

            tx = x + (self.__bounds.right - x) / 2 - self:__line_length(lines[i]) / 2

        elseif mode == "justified" then

            local total = self:__line_length(lines[i])

            local q = #lines[i] - 1
            if lines[i][#lines[i]] and lines[i][#lines[i]].__text == "\n" then
                -- q = q - 1
                q = q * 2 + 5

            end

            -- if lines[i][1] and lines[i][1].__text == "\t" then
            --     -- space = 0
            --     q = q - 1
            -- end

            if q == 0 then q = 1 end
            space = (self.__bounds.right - x - total) / (q)

            tx = tx
        end

        for j = 1, #lines[i] do
            local w = self:__get_word_in_list(lines[i], j)
            local r = w:get_width() + space

            w:draw(tx, ty)

            tx = tx + r
        end
        tx = x
        ty = ty + (self.__font.__font_size + self.__font.__line_space)
    end

    self.__font:pop()

    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.line(self.__bounds.right, 0, self.__bounds.right, 600)
    ------------------------------------------------------------------------
    -- do
    --     local tx = x - 200
    --     local ty = y + 330

    --     for i = 1, #self.__words do
    --         local w = self:get_word_by_index(i)

    --         local r = w:get_width() + (self.__font.__word_space * self.__font.__scale)

    --         if tx + r > self.__bounds.right then
    --             tx = x - 200
    --             ty = ty + (self.__font.__font_size + self.__font.__line_space)
    --         end
    --         w:draw(tx, ty)
    --         tx = tx + r
    --     end
    -- end
end

return Phrase

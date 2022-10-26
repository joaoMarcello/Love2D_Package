local Word = require("/JM_love2d_package/modules/font/Word")
local EffectGenerator = require("/JM_love2d_package/effect_generator_module")


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

    self.__font:push()

    self.__separated_string = self:separate_string(self.__text)
    self.__words = {}

    self.__bounds = { top = 0, left = 0, height = love.graphics.getHeight(), right = love.graphics.getWidth() - 100 }

    for i = 1, #self.__separated_string do
        local w = Word:new({ text = self.__separated_string[i],
            font = self.__font,
            format = self.__font:get_format_mode()
        })

        -- self:__verify_commands(w.__text)

        if w.__text ~= "" then
            if not self.__font:__is_a_nickname(w.__text, 1) then
                w:set_color(self.__font.__default_color)
            end
            table.insert(self.__words, w)
        end
    end

    self.__font:pop()
end

function Phrase:__verify_commands(text)
    local r = self:__is_a_tag(text, 1)
    if r then
        if r.tag == "<bold>" then
            self.__font:set_format_mode(self.__font.format_options.bold)
        elseif r.tag == "</bold>" then
            self.__font:set_format_mode(self.__font_config.format)
        elseif r.tag == "<color>" then
            self.__font:set_color({ 0, 0, 1, 1 })
        elseif r.tag == "</color>" then
            self.__font:set_color(self.__font_config.color)
        end
    end
end

---@param word string
---@param mode number|"all"
function Phrase:color_pattern(word, color, mode)
    local count = 0

    for i = 1, #self.__words, 1 do
        local w = self:get_word_by_index(i)
        local text = w.__text
        local startp, endp = 1, 1

        while true do
            startp, endp = text:find(word, startp)

            if startp then
                if self.__font:__is_a_nickname(text, 1) then
                    if word == text then
                        w:set_color(color)
                    end
                else
                    w:turn_into_bold(startp, endp)
                    w:set_color(color, startp, endp)
                end

                if mode ~= "all" then
                    count = count + 1
                    if count >= mode then return end
                end

                startp = startp + 1
                -- text = text:sub(endp + 1, #text)
            else
                break
            end

        end


    end -- END FOR each word in list
end

---@return {stack: table, phrase: JM.Font.Phrase}
function Phrase:__find_occurrences__(sentence, mode)
    local Sentence = Phrase:new({ text = sentence, font = self.__font })
    local found_stack = {}
    local count = 0

    local i = 1
    while (i <= #self.__words) do

        local j = 1
        while (j <= #Sentence.__words) do
            local word = self:get_word_by_index(i + j - 1)
            if not word then break end

            local cur_sentence_word = Sentence:get_word_by_index(j).__text
            local startp, endp = word.__text:find(cur_sentence_word)

            local startp = word.__text == cur_sentence_word
                or word.__text:sub(1, #(word.__text) - 1) == cur_sentence_word

            if not startp then break end

            if j == #Sentence.__words then
                if not (self.__font:string_is_nickname(word.__text)
                    and word.__text ~= cur_sentence_word)
                    and not (self.__font:string_is_nickname(cur_sentence_word)
                        and cur_sentence_word ~= word.__text)
                then

                    table.insert(found_stack, i)
                    count = count + 1
                end
            end

            j = j + 1
        end

        if mode ~= "all" and count >= mode then
            break
        end

        i = i + 1
    end

    return { stack = found_stack, phrase = Sentence }
end

--- Color a sentence.
---@param sentence string
---@param color JM.Color
---@param mode number|"all"
function Phrase:color_sentence(sentence, color, mode)
    local result = self:__find_occurrences__(sentence, mode)
    local found_stack = result.stack
    local phrase = result.phrase

    if #found_stack > 0 then
        for k = 1, #found_stack do
            local where_found = found_stack[k]

            for i = where_found, where_found + #(phrase.__words) - 1, 1 do
                local word = self:get_word_by_index(i)
                local word_sentence = phrase:get_word_by_index(i - where_found + 1)

                local startp, endp = word.__text:find(word_sentence.__text)
                local r = startp and word:set_color(color, startp, endp)
                r = startp and word:turn_into_bold(startp, endp)
            end
        end
    end
end

---@param sentence string
---@param mode number|"all"
function Phrase:apply_freaky(sentence, mode)
    local result = self:__find_occurrences__(sentence, mode)
    local found_stack = result.stack
    local Sentence = result.phrase

    local offset = 0
    if #found_stack > 0 then
        for k = 1, #found_stack do

            local where_found = found_stack[k]

            for i = where_found, where_found + #(Sentence.__words) - 1, 1 do
                offset = offset + math.pi / 2

                local word = self:get_word_by_index(i)
                local word_sentence = Sentence:get_word_by_index(i - where_found + 1)

                local startp, endp = word.__text:find(word_sentence.__text)
                local r = startp and word:apply_effect(startp, endp, "freaky", offset)
            end
        end
    end
end

---@return JM.Font.Word
function Phrase:get_word_by_index(index)
    return self.__words[index]
end

---@return table
function Phrase:get_lines(x, y)
    local lines = {}
    local tx = x
    local cur_line = 1
    local word_char = Word:new({ text = " ", font = self.__font })


    for i = 1, #self.__words do
        local current_word = self:get_word_by_index(i)
        local next_word = self:get_word_by_index(i + 1)

        if self:__is_a_tag(current_word.__text, 1) then
            -- goto skip_word
        end

        local r = current_word:get_width()
            + word_char:get_width()

        if tx + r > self.__bounds.right
            or current_word.__text == "\n" then

            tx = x

            -- Try remove the last added space word
            if pcall(
                function()
                    local last_added = self:__get_word_in_list(lines[cur_line], #lines[cur_line])

                    if last_added.__text == " " then
                        table.remove(lines[cur_line], #lines[cur_line])
                    end
                end)
            then
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
        ::skip_word::
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

---@param text string
---@param index number
---@return {start:number, final:number, tag:string}|nil
function Phrase:__is_a_tag(text, index)
    local command = "color"

    if text:sub(index, index) == "<" then
        local startp, endp = text:find(">", index + 1)
        local start2
        if startp then
            -- start2 = text:find("<", index + 1)
            -- if start2 and start2 < startp then start2 = true end
        end

        if startp and not start2 then
            -- local start2, endp2 = text:find("</" .. command .. ">", endp)
            -- if start2 then
            return { start = startp, final = endp, tag = text:sub(index, endp) }
            -- end
        end
    end
end

---@param s string
function Phrase:separate_string(s)
    s = s .. " "
    local sep = "\n\t "
    local current_init = 1
    local words = {}

    while (current_init <= #(s)) do
        local regex = "[^[ ]]*.-[" .. sep .. "]"
        local find = s:match(regex, current_init)
        local nick = find and string.match(find, "%-%-%w-%-%-")

        if nick and nick ~= "----" then
            local startp, endp = string.find(s, "%-%-%w-%-%-", current_init)
            local sub_s = s:sub(startp, endp)
            local prev_word = s:sub(current_init, startp - 1)

            if prev_word and prev_word ~= "" and prev_word ~= " " then
                table.insert(words, prev_word)
            end

            if sub_s ~= "" then
                table.insert(words, sub_s)
            end

            current_init = endp

        elseif find then
            local startp, endp = string.find(s, regex, current_init)
            local sub_s = s:sub(startp, endp - 1)

            if sub_s ~= "" then
                local sub2 = sub_s:sub(1, 1)
                if sub2 == "\n" or sub2 == "\t" then
                    sub_s = sub_s:sub(2, #sub_s)
                    -- table.insert(words, sub2)
                end
                table.insert(words, sub_s)
            end

            if s:sub(endp, endp) == "\n" then table.insert(words, "\n") end
            if s:sub(endp, endp) == "\t" then table.insert(words, "\t") end

            current_init = endp
        else
            break
        end

        current_init = current_init + 1
    end

    if s:sub(current_init, #s) ~= "" then
        table.insert(words, s:sub(current_init, #s))
    end

    return words
end

function Phrase:update(dt)
    for i = 1, #self.__words, 1 do
        local w = self:__get_word_in_list(self.__words, i)
        w:update(dt)
    end
end

---
---@param lines table
---@param x number
---@param y number
---@param alignment "left"|"right"|"center"|"justified"|nil
---@param threshold number|nil
---@return JM.Font.CharacterPosition|nil
function Phrase:draw_lines(lines, x, y, alignment, threshold, __max_char__)
    if not alignment then alignment = "left" end
    if not threshold then threshold = #lines end

    local tx, ty = x, y
    local space = 0
    local character_count = { [1] = 0 }
    local result

    for i = 1, #lines do
        if alignment == "right" then

            tx = self.__bounds.right - self:__line_length(lines[i])

        elseif alignment == "center" then

            tx = x + (self.__bounds.right - x) / 2 - self:__line_length(lines[i]) / 2

        elseif alignment == "justified" then

            local total = self:__line_length(lines[i])

            local q = #lines[i] - 1
            if lines[i][#lines[i]] and lines[i][#lines[i]].__text == "\n" then
                q = q * 2 + 5
                q = 100000000
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
            local current_word = self:__get_word_in_list(lines[i], j)
            local r = current_word:get_width() + space

            result = current_word:draw(tx, ty, __max_char__, character_count)

            tx = tx + r

            if result then return result end
        end

        tx = x
        ty = ty + (self.__font.__font_size + self.__font.__line_space)

        if i >= threshold then
            break
        end
    end
end

function Phrase:refresh()
    self.__last_lines__ = nil
end

function Phrase:__debbug()
    local s = self.__text
    local w = self:separate_string(s)

    for i = 1, #w do
        self.__font:print(tostring(w[i]), 0, 50 * i)
    end
end

---@param x number
---@param y number
---@param alignment "left"|"right"|"center"|"justified"|nil
---@param __max_char__ number|nil
---@return JM.Font.CharacterPosition|nil
function Phrase:draw(x, y, alignment, __max_char__)
    self:__debbug()

    if x >= self.__bounds.right then return end

    if not self.__last_lines__
        or self.__last_lines__.x ~= x
        or self.__last_lines__.y ~= y
    then
        self.__last_lines__ = { lines = self:get_lines(x, y), x = x, y = y }
    end

    local lines = self.__last_lines__.lines

    local result = self:draw_lines(lines, x, y, alignment, nil, __max_char__)


    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.line(self.__bounds.right, 0, self.__bounds.right, 600)

    return result
    ------------------------------------------------------------------------
end

return Phrase

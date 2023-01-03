---@type string
local path = ...

---@type JM.Font.Word
local Word = require(path:gsub("Phrase", "Word"))

---@type JM.Utils
local Utils --= require("/JM_love2d_package/utils")

---@class JM.Font.Phrase
local Phrase = {}

Phrase.load_dependencies = function(effect_manager, utils)
    Word.load_dependencies(effect_manager)
    Utils = utils
end

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
    assert(Utils, "\n> Module Utils not initialized!")

    self.text = args.text
    self.__font = args.font
    self.__font_config = self.__font:__get_configuration()

    self.__font:push()

    self.__separated_string = self.__font:separate_string(self.text)
    self.__words = {}

    self.__bounds = { top = 0, left = 0, bottom = love.graphics.getHeight(), right = love.graphics.getWidth() - 100 }

    for i = 1, #self.__separated_string do
        local w = Word:new({ text = self.__separated_string[i],
            font = self.__font,
            format = self.__font:get_format_mode()
        })

        self:__verify_commands(w.text)

        if w.text ~= "" then
            if not self.__font:__is_a_nickname(w.text, 1) then
                w:set_color(self.__font.__default_color)
            end
            table.insert(self.__words, w)
        end
    end

    self.__font:pop()
end

function Phrase:__verify_commands(text)
    local result = self.__font:__is_a_command_tag(text)

    if result then
        if result:match("< *bold *>") then
            self.__font:set_format_mode(self.__font.format_options.bold)

        elseif result:match("< */ *bold *>") then
            self.__font:set_format_mode(self.__font_config.format)

        elseif result == "<color>" then
            local tag = text:match("< *color[ ,%d.]*>")
            local parse = Utils:parse_csv_line(tag:sub(2, #tag - 1))
            local r = tonumber(parse[2]) or 1
            local g = tonumber(parse[3]) or 0
            local b = tonumber(parse[4]) or 0
            local a = tonumber(parse[5]) or 1
            self.__font:set_color({ r, g, b, a })

        elseif result:match("< */ *color *>") then
            self.__font:set_color(self.__font_config.color)

        elseif result:match("< *italic *>") then
            self.__font:set_format_mode(self.__font.format_options.italic)

        elseif result:match("< */ *italic *>") then
            self.__font:set_format_mode(self.__font_config.format)

        end
    end
end

function Phrase:set_bounds(top, left, right, bottom)
    self.__bounds.top = top or self.__bounds.top
    self.__bounds.left = left or self.__bounds.left
    self.__bounds.right = right or self.__bounds.right
    self.__bounds.bottom = bottom or self.__bounds.bottom
end

---@param word string
---@param mode number|"all"
function Phrase:color_pattern(word, color, mode)
    local count = 0

    for i = 1, #self.__words, 1 do
        local w = self:get_word_by_index(i)
        local text = w.text
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

            local cur_sentence_word = Sentence:get_word_by_index(j).text
            local startp, endp = word.text:find(cur_sentence_word)

            local startp = word.text == cur_sentence_word
                or word.text:sub(1, #(word.text) - 1) == cur_sentence_word

            if not startp then break end

            if j == #Sentence.__words then
                if not (self.__font:string_is_nickname(word.text)
                    and word.text ~= cur_sentence_word)
                    and not (self.__font:string_is_nickname(cur_sentence_word)
                        and cur_sentence_word ~= word.text)
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

                local startp, endp = word.text:find(word_sentence.text)
                local r = startp and word:set_color(color, startp, endp)
                -- r = startp and word:turn_into_bold(startp, endp)
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

                local startp, endp = word.text:find(word_sentence.text)
                local r = startp and word:apply_effect(startp, endp, "freaky", offset)
            end
        end
    end
end

---@return JM.Font.Word
function Phrase:get_word_by_index(index)
    return self.__words[index]
end

local results_get_lines = setmetatable({}, { __mode = 'kv' })

---@return table
function Phrase:get_lines(x, y)
    local result = results_get_lines[self] and results_get_lines[self][x]
    if result then return result end

    local lines = {}
    local tx = x
    local cur_line = 1
    local word_char = Word:new({ text = " ", font = self.__font })


    for i = 1, #self.__words do
        local current_word = self:get_word_by_index(i)
        local next_word = self:get_word_by_index(i + 1)

        local cur_is_tag = self.__font:__is_a_command_tag(current_word.text)

        if cur_is_tag then
            goto skip_word
        end

        local r = current_word:get_width()
            + word_char:get_width()

        if tx + r > self.__bounds.right
            or current_word.text:match("\n ?") then

            tx = x

            -- Try remove the last added space word
            if pcall(
                function()
                    local last_added = self:__get_word_in_list(lines[cur_line], #lines[cur_line])

                    if last_added.text == " " then
                        table.remove(lines[cur_line], #lines[cur_line])
                    end
                end)
            then
                cur_line = cur_line + 1
            end
        end

        if not lines[cur_line] then lines[cur_line] = {} end

        if current_word.text ~= "\n" then
            table.insert(lines[cur_line], current_word)
        elseif next_word.text ~= "\n" then
            table.insert(lines[cur_line - 1], current_word)
        else
            table.insert(lines[cur_line], current_word)
            table.insert(lines[cur_line - 1], current_word)
        end

        if i ~= #(self.__words)
            and current_word.text ~= "\t"
            and current_word.text ~= "\n"
            and next_word and next_word.text ~= "\t"
        then

            table.insert(lines[cur_line], word_char)
        end
        tx = tx + r
        ::skip_word::
    end

    table.insert(lines[cur_line], Word:new({ text = "\n", font = self.__font }))

    results_get_lines[self] = results_get_lines[self]
        or setmetatable({}, { __mode = 'k' })
    results_get_lines[self][x] = lines

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

-- ---@param s string
-- function Phrase:separate_string(s, list)
--     s = s .. " "
--     local sep = "\n "
--     local current_init = 1
--     local words = list or {}

--     while (current_init <= #(s)) do
--         local regex = "[^[ ]]*.-[" .. sep .. "]"
--         local tag_regex = "< *[%d, .%w/]*>"

--         local tag = s:match(tag_regex, current_init)
--         tag = tag and self.__font:__is_a_command_tag(tag) or nil
--         local find = not tag and s:match(regex, current_init)
--         local nick = false and find and string.match(find, "%-%-%w-%-%-")

--         if tag then
--             local startp, endp = string.find(s, tag_regex, current_init)
--             local sub_s = s:sub(startp, endp)
--             local prev_s = s:sub(current_init, startp - 1)

--             if prev_s ~= "" and prev_s ~= " " then
--                 self:separate_string(prev_s, words)
--             end

--             table.insert(words, sub_s)
--             current_init = endp

--         elseif nick and nick ~= "----" then
--             local startp, endp = string.find(s, "%-%-%w-%-%-", current_init)
--             local sub_s = s:sub(startp, endp)
--             local prev_word = s:sub(current_init, startp - 1)

--             if prev_word and prev_word ~= "" and prev_word ~= " " then
--                 self:separate_string(prev_word, words)
--             end

--             if sub_s ~= "" and sub_s ~= " " then
--                 table.insert(words, sub_s)
--             end

--             current_init = endp

--         elseif find then

--             local startp, endp = string.find(s, regex, current_init)
--             local sub_s = s:sub(startp, endp - 1)

--             if sub_s ~= "" and sub_s ~= " " then
--                 table.insert(words, sub_s)
--             end

--             if s:sub(endp, endp) == "\n" then
--                 table.insert(words, "\n")
--             end

--             current_init = endp
--         else
--             break
--         end

--         current_init = current_init + 1
--     end

--     local rest = s:sub(current_init, #s)

--     if rest ~= "" and not rest:match(" *") then
--         table.insert(words, s:sub(current_init, #s))
--     end

--     return words
-- end

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
---@param align "left"|"right"|"center"|"justified"|nil
---@param threshold number|nil
---@return JM.Font.CharacterPosition|nil
function Phrase:draw_lines(lines, x, y, align, threshold, __max_char__)
    if not align then align = "left" end
    if not threshold then threshold = #lines end

    local tx, ty = x, y
    local space = 0
    local character_count = { [1] = 0 }
    local result

    for i = 1, #lines do
        if align == "right" then

            tx = self.__bounds.right - self:__line_length(lines[i])

        elseif align == "center" then

            tx = x + (self.__bounds.right - x) / 2 - self:__line_length(lines[i]) / 2

        elseif align == "justified" then

            local total = self:__line_length(lines[i])

            local q = #lines[i] - 1
            if lines[i][#lines[i]] and lines[i][#lines[i]].__text == "\n" then
                q = q * 2 + 7
                q = 100
            end

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
    local s = self.text
    local w = self.__font:separate_string(s)

    for i = 1, #w do
        self.__font:print(tostring(w[i]), 10, 50 * i)
    end
end

---@param x number
---@param y number
---@param align "left"|"right"|"center"|"justified"|nil
---@param __max_char__ number|nil
---@return JM.Font.CharacterPosition|nil
function Phrase:draw(x, y, align, __max_char__)
    self:__debbug()

    --if x >= self.__bounds.right then return end

    -- if not self.__last_lines__
    --     or self.__last_lines__.x ~= x
    --     or self.__last_lines__.y ~= y
    -- then
    --     self.__last_lines__ = { lines = self:get_lines(x, y), x = x, y = y }
    -- end

    -- local lines = self.__last_lines__.lines

    local result = self:draw_lines(
        self:get_lines(x, y),
        x, y, align,
        nil, __max_char__
    )

    -- love.graphics.setColor(0.4, 0.4, 0.4, 1)
    -- love.graphics.line(self.__bounds.right, 0, self.__bounds.right, 600)

    return result
    ------------------------------------------------------------------------
end

return Phrase

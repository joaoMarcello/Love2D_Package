---@type string
local path = ...

---@type JM.Anima
local Anima = _G.JM_Anima

---@type JM.Utils
local Utils = _G.JM_Utils

---@type JM.Font.Glyph
local Glyph = require(path:gsub("jm_font_generator", "font.glyph"))

---@type JM.Font.GlyphIterator
local Iterator = require(path:gsub("jm_font_generator", "font.font_iterator"))

---@type JM.Font.Phrase
local Phrase = require(path:gsub("jm_font_generator", "font.Phrase"))

--====================================================================

local table_insert, string_find = table.insert, string.find
local love_draw, love_set_color = love.graphics.draw, love.graphics.setColor

---@enum JM.Font.FormatOptions
local FontFormat = {
    normal = 0,
    bold = 1,
    italic = 2,
    bold_italic = 3
}

---@alias JM.AvailableFonts
---|"consolas"
---|"JM caligraphy"

---@class JM.Font.Font
---@field __nicknames table
local Font = {
    buffer_time = 0.0
}

---@overload fun(self: table, args: JM.AvailableFonts)
---@param args {name: JM.AvailableFonts, font_size: number, line_space: number, tab_size: number, character_space: number, color: JM.Color}
---@return JM.Font.Font new_Font
function Font:new(args)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Font.__constructor__(obj, args)

    -- Affectable.__checks_implementation__(obj)

    return obj
end

---@overload fun(self: table, args: JM.AvailableFonts)
---@param args {name: JM.AvailableFonts, font_size: number, line_space: number, tab_size: number, character_space: number, color: JM.Color}
function Font:__constructor__(args)
    if type(args) == "string" then
        local temp_table = {}
        temp_table.name = args
        args = temp_table
    end

    self.__normal_img = love.graphics.newImage("/JM_love2d_package/data/Font/" .. args.name .. "/" .. args.name .. ".png")
    self.__normal_img:setFilter("linear", "nearest")

    self.__bold_img = love.graphics.newImage("/JM_love2d_package/data/Font/" ..
        args.name .. "/" .. args.name .. "_bold" .. ".png")
    self.__bold_img:setFilter("linear", "nearest")

    self.__italic_img = love.graphics.newImage("/JM_love2d_package/data/Font/" ..
        args.name .. "/" .. args.name .. "_italic" .. ".png")
    self.__italic_img:setFilter("linear", "nearest")

    self.img = self.__normal_img

    self.quad = love.graphics.newQuad(
        0, 0,
        20, 20,
        self.img:getDimensions()
    )

    self.__nicknames = {}

    self.__font_size = args.font_size or 20

    self.__character_space = args.character_space or 1
    self.__line_space = args.line_space or 10

    self.__normal_characters = {}
    self.__bold_characters = {}
    self.__italic_characters = {}

    self:__load_caracteres_from_csv(self.__normal_characters,
        args.name,
        self.__normal_img,
        nil,
        FontFormat.normal
    )
    self:__load_caracteres_from_csv(self.__bold_characters,
        args.name,
        self.__bold_img,
        "_bold",
        FontFormat.bold
    )
    self:__load_caracteres_from_csv(self.__italic_characters,
        args.name,
        self.__italic_img,
        "_italic",
        FontFormat.italic
    )

    self.__format = FontFormat.normal

    self.format_options = FontFormat

    self.__ref_height = self:__get_char_equals("A").h
        or self:__get_char_equals("0").h
        or self.__font_size

    self.__word_space = self.__ref_height * 0.6

    self.__tab_size = args.tab_size or 4

    self:set_font_size(self.__font_size)

    self.__tab_char = Glyph:new(self.img, {
        id = "\t",
        x = 0, y = 0,
        w = self.__word_space * self.__tab_size,
        h = self.__ref_height
    })

    self.__space_char = Glyph:new(self.img, {
        id = " ",
        x = 0, y = 0,
        w = self.__word_space,
        h = self.__ref_height
    })

    self.__normal_characters[" "] = self.__space_char
    self.__bold_characters[" "] = self.__space_char
    self.__italic_characters[" "] = self.__space_char

    self.__normal_characters["\t"] = self.__tab_char
    self.__bold_characters["\t"] = self.__tab_char
    self.__italic_characters["\t"] = self.__tab_char

    self.__default_color = args.color or { 0.1, 0.1, 0.1, 1 }

    self.__bounds = { left = 0, top = 0, right = love.graphics.getWidth(), bottom = love.graphics.getHeight() }

    self.batches = {
        [FontFormat.normal] = love.graphics.newSpriteBatch(self.__normal_img),
        [FontFormat.bold] = love.graphics.newSpriteBatch(self.__bold_img),
        [FontFormat.italic] = love.graphics.newSpriteBatch(self.__italic_img)
    }
end

---@return JM.Font.GlyphIterator
function Font:get_text_iterator(text)
    return Iterator:new(text, self)
end

---
---@param value JM.Font.FormatOptions
function Font:set_format_mode(value)
    self.__format = value
end

function Font:get_format_mode()
    return self.__format
end

function Font:__load_caracteres_from_csv(list, name, img, extend, format)
    if not extend then extend = "" end

    local lines = Utils:get_lines_in_file("/JM_love2d_package/data/Font/" .. name .. "/" .. name .. extend .. ".txt")

    for i = 2, #lines do
        local parse = Utils:parse_csv_line(lines[i])
        local id = (parse[1])
        if id == "" then
            id = ","
        elseif id == [[_"]] then
            id = [["]]
        end
        local left = tonumber(parse[2])
        local right = tonumber(parse[3])
        local top = tonumber(parse[4])
        local bottom = tonumber(parse[5])
        local offset_y = tonumber(parse[6])
        local offset_x = tonumber(parse[7])

        if not left then
            break
        end

        local character_obj = Glyph:new(img,
            { id = id, x = left, y = top, w = right - left, h = bottom - top, bottom = offset_y, format = format }
        )

        list[character_obj.__id] = character_obj
    end

    local nule_char = self:get_nule_character()

    list[nule_char.__id] = nule_char
end

function Font:get_nule_character()
    local char_ = Glyph:new(nil,
        { id = "__nule__", x = nil, y = nil, w = self.__word_space, h = self.__ref_height })

    return char_
end

local results_get_config = setmetatable({}, { __mode = 'kv' })

---@return {font_size: number, character_space: number, color: JM.Color, line_space: number, word_space: number, tab_size: number, format: JM.Font.FormatOptions }
function Font:__get_configuration()
    local index = string.format("%d %d %.1f %.1f %.1f %.1f %d %s",
        self.__font_size,
        self.__character_space,
        (self.__default_color[1]),
        (self.__default_color[2]),
        (self.__default_color[3]),
        (self.__default_color[4]),
        self.__line_space,
        self.__format)

    -- local index = "" ..
    --     self.__font_size ..
    --     self.__character_space
    --     .. (self.__default_color[1])
    --     .. (self.__default_color[2])
    --     .. (self.__default_color[3])
    --     .. (self.__default_color[4])
    --     .. self.__line_space
    --     --.. self.__word_space
    --     --.. self.__tab_size
    --     .. self.__format

    local result = results_get_config[self] and results_get_config[self][index]
    if result then return result end

    local config = {}
    config.font_size = self.__font_size
    config.character_space = self.__character_space
    config.color = self.__default_color
    config.line_space = self.__line_space
    config.word_space = self.__word_space
    config.tab_size = self.__tab_size
    config.format = self.__format

    results_get_config[self] = results_get_config[self] or setmetatable({}, { __mode = 'v' })
    results_get_config[self][index] = config

    return config
end

function Font:push()
    if not self.__config_stack__ then
        self.__config_stack__ = {}
    end

    assert(#self.__config_stack__ >= 0, "\nError: Too many push operations. Are you using more push than pop?")

    local config = self:__get_configuration()
    table.insert(self.__config_stack__, config)
end

function Font:pop()
    assert(self.__config_stack__ and #self.__config_stack__ > 0,
        "\nError: You're using a pop operation without using a push before.")

    local config = table.remove(self.__config_stack__, #self.__config_stack__)

    self:set_font_size(config.font_size)
    self.__character_space = config.character_space
    self.__default_color = config.color
    self.__line_space = config.line_space
    self.__word_space = config.word_space
    self.__tab_size = config.tab_size
    self.__format = config.format
end

function Font:set_character_space(value)
    self.__character_space = value
end

---@param color JM.Color
function Font:set_color(color)
    self.__default_color = color
end

function Font:set_line_space(value)
    self.__line_space = value
end

function Font:set_tab_size(value)
    self.__tab_size = value
    self.__tab_char.w = self.__word_space * self.__tab_size
end

function Font:set_word_space(value)
    self.__word_space = value
end

---@param value number
function Font:set_font_size(value)
    self.__font_size = value
    self.__scale = Utils:desired_size(nil, self.__font_size, nil, self.__ref_height, true).y
end

---@param nickname string
---@return string|nil
local function is_valid_nickname(nickname)
    return #nickname > 4 and nickname:match("%-%-[^%-][%w%p]-%-%-") or nil
end

---@param nickname string
--- @param args {img: love.Image|string, frames: number, frames_list: table,  speed: number, rotation: number, color: JM.Color, scale: table, flip_x: boolean, flip_y: boolean, is_reversed: boolean, stop_at_the_end: boolean, amount_cycle: number, state: JM.AnimaStates, bottom: number, kx: number, ky: number, width: number, height: number, ref_width: number, ref_height: number, duration: number, n: number}
function Font:add_nickname_animated(nickname, args)
    assert(is_valid_nickname(nickname),
        "\nError: Invalid nickname. The nickname should start and ending with '--'. \nExamples: --icon--, --emoji--.")

    local animation = Anima:new(args)

    local new_character = Glyph:new(nil, {
        id = nickname,
        anima = animation,
        w = self.__ref_height * 1.5,
        h = self.__ref_height
    })

    table_insert(self.__nicknames, nickname)

    self.__normal_characters[new_character.__id] = new_character
    self.__bold_characters[new_character.__id] = new_character
    self.__italic_characters[new_character.__id] = new_character

    return animation
end

---@param s string
---@return string|nil nickname
function Font:__is_a_nickname(s, index)
    for _, nickname in ipairs(self.__nicknames) do
        if s:sub(index, index + #nickname - 1) == nickname then
            return nickname
        end
    end
    return nil
end

---
function Font:string_is_nickname(s)
    return self:__is_a_nickname(s, 1)
end

---
function Font:update(dt)

    for i = 1, #(self.__nicknames), 1 do
        local character = self:__get_char_equals(self.__nicknames[i])
        local r = character and character:update(dt)
    end

    -- if self.buffer__ then
    --     -- self.buffer_time = self.buffer_time + dt

    --     -- if self.buffer_time >= 15.0 then
    --     --     self.buffer_time = 0.0
    --     --     self:clear_buffer()
    --     -- end
    -- end
end

---@param c string
---@return JM.Font.Glyph|nil
function Font:__get_char_equals(c)
    local list = self.__format == FontFormat.normal and self.__normal_characters
        or self.__format == FontFormat.bold and self.__bold_characters
        or self.__italic_characters

    return list[c]
end

local result_sep_text = setmetatable({}, { __mode = 'kv' })

---@param s string
function Font:separate_string(s, list)
    s = s .. " "
    local result = not list and result_sep_text[s]
    if result then return result end

    local sep = "\n "
    local current_init = 1
    local words = list or {}

    while (current_init <= #(s)) do
        local regex = string.format("[^[ ]]*.-[%s]", sep)
        --"[^[ ]]*.-[" .. sep .. "]"
        local tag_regex = "< *[%d, .%w/]*>"

        local tag = s:match(tag_regex, current_init)
        local find = not tag and s:match(regex, current_init)
        local nick = false --find and string.match(find, "%-%-%w-%-%-")

        if tag then
            local startp, endp = string_find(s, tag_regex, current_init)
            local sub_s = s:sub(startp, endp)
            local prev_s = s:sub(current_init, startp - 1)

            if prev_s ~= "" and prev_s ~= " " then
                self:separate_string(prev_s, words)
            end

            table_insert(words, sub_s)
            current_init = endp

        elseif nick and nick ~= "----" then
            local startp, endp = string.find(s, "%-%-%w-%-%-", current_init)
            local sub_s = s:sub(startp, endp)
            local prev_word = s:sub(current_init, startp - 1)

            if prev_word and prev_word ~= "" and prev_word ~= " " then
                self:separate_string(prev_word, words)
            end

            if sub_s ~= "" and sub_s ~= " " then
                table_insert(words, sub_s)
            end

            current_init = endp

        elseif find then

            local startp, endp = string_find(s, regex, current_init)
            local sub_s = s:sub(startp, endp - 1)

            if sub_s ~= "" and sub_s ~= " " then
                table_insert(words, sub_s)
            end

            if s:sub(endp, endp) == "\n" then
                table_insert(words, "\n")
            end

            current_init = endp
        else
            break
        end

        current_init = current_init + 1
    end

    local rest = s:sub(current_init, #s)

    if rest ~= "" and not rest:match(" *") then
        table_insert(words, s:sub(current_init, #s))
    end

    result_sep_text[s] = words

    return words
end

function Font:separate_string_2(s, list)
    s = s .. " "
    local sep = "\n " -- line break and space as separators
    local cur_init = 1
    local words = list or {}
    local N = #s
    while (cur_init <= N) do
        local regex = string.format("[^ ]*.-[%s]", sep)
        local tag_regex = "< *[%d, %.%w/]*>"

        local tag = false and s:match(tag_regex, cur_init)
        local find = not tag and string.match(s, regex, cur_init)

        if tag then
            local startp, endp = string.find(s, tag_regex, cur_init)
            local sub_s = s:sub(cur_init, endp)
            local prev_s = s:sub(cur_init, startp)

            -- local sep_p = 1

            local m1 = string.match(prev_s, string.format("[%s]<", sep))
            local t1, t2 = string.find(prev_s, ".* ")

            if not m1 and not t1 then
                local add = sub_s
                table.insert(words, sub_s)
            elseif m1 then
                local zz = s:sub(cur_init, startp - 1)
                self:separate_string_2(zz, words)
                local add = tag
                table.insert(words, tag)
            elseif t1 then
                local zz = prev_s:sub(1, t2)
                self:separate_string_2(zz, words)
                local add = prev_s:sub(t2 + 1, #prev_s - 1) .. tag
                table.insert(words, add)
            end

            cur_init = endp

        elseif find then
            local startp, endp = string.find(s, regex, cur_init)
            if startp then
                local sub_s = s:sub(startp, endp - 1)

                if sub_s and sub_s ~= "" then
                    table.insert(words, sub_s)
                end

                sub_s = s:sub(endp, endp)
                if sub_s == "\n" then table.insert(words, "\n") end
                if sub_s == "\t" then table.insert(words, "\t") end

                cur_init = endp
            end
        end


        cur_init = cur_init + 1
    end

    local rest = s:sub(cur_init, N)

    if rest ~= "" and not rest:match(" *") then
        table.insert(words, s:sub(cur_init, N))
    end

    return words
end

function Font:__is_a_command_tag(s)
    return (s:match("< *bold *>") and "<bold>")
        or (s:match("< */ *bold *>") and "</bold>")
        or (s:match("< *italic *>") and "<italic>")
        or (s:match("< */ *italic *>") and "</italic>")
        or (s:match("< *color[%d, .]*>") and "<color>")
        or (s:match("< */ *color *>") and "</color>")
        or (s:match("< *freaky *>") and "<freaky>")
        or false
end

---@param text string
function Font:print(text, x, y, w, h, __i__, __color__, __x_origin__, __format__)
    if not text or text == "" then return x, y end

    self:push()

    w = w or nil --love.graphics.getWidth() - 100
    h = h or love.graphics.getHeight()

    local tx = x
    local ty = y

    local current_color = __color__ or self.__default_color
    local original_color = self.__default_color

    local current_format = __format__ or self.__format
    local original_format = self.__format

    local x_origin = __x_origin__ or tx

    local i = __i__ or 1

    local text_size = #(text)

    -- self.batches[FontFormat.normal]:clear()
    -- self.batches[FontFormat.bold]:clear()
    -- self.batches[FontFormat.italic]:clear()

    for _, batch in pairs(self.batches) do
        batch:clear()
    end

    while (i <= text_size) do

        local char_string = text:sub(i, i)
        local is_a_nick = self:__is_a_nickname(text, i)

        if is_a_nick then
            char_string = is_a_nick
            i = i + #char_string - 1
        end

        local tag = text:match("<.->", i)
        if tag then
            local match = self:__is_a_command_tag(tag)

            local startp, endp = text:find("<.->", i)

            local r_tx, r_ty
            if match then
                r_tx, r_ty = self:print(text:sub(i, startp - 1),
                    tx, ty, w, h, 1,
                    current_color, x_origin, current_format
                )
            end

            if match == "<color>" then
                local parse = Utils:parse_csv_line(text:sub(startp - 1, endp - 1))
                local r = parse[2] or 1
                local g = parse[3] or 0
                local b = parse[4] or 0
                local a = parse[5] or 1

                current_color = Utils:get_rgba(r, g, b, a) --{ r, g, b, 1 }

            elseif match == "</color>" then
                current_color = original_color
            elseif match == "<bold>" then
                current_format = self.format_options.bold
            elseif match == "</bold>" then
                current_format = original_format
            elseif match == "<italic>" then
                current_format = self.format_options.italic
            elseif match == "</italic>" then
                current_format = original_format
            end

            if match then
                i = endp
                if endp == #text then
                    i = i + 1
                end
                tx = r_tx
                ty = r_ty
                char_string = ""
            end
        end

        self:set_format_mode(current_format)

        local char_obj = self:__get_char_equals(char_string)


        if not char_obj then
            char_obj = self:__get_char_equals(text:sub(i, i + 1))
        end

        if char_string == "\n"
            or (char_obj and w)
            and tx + self.__word_space + char_obj:get_width() >= x_origin + w
        then
            ty = ty + self.__ref_height * self.__scale + self.__line_space
            tx = x_origin
        end

        if char_obj then

            char_obj:set_color(current_color)

            char_obj:set_scale(self.__scale)

            if char_obj:is_animated() then
                char_obj:set_color({ 1, 1, 1, 1 })

                char_obj.__anima:set_size(
                    nil, self.__font_size * 1.4,
                    nil, char_obj.__anima:get_current_frame().h
                )

                char_obj:draw(tx + char_obj.w / 2 * char_obj.sx,
                    ty + char_obj.h / 2 * char_obj.sy
                )
            else

                local width = char_obj.w * char_obj.sx
                local height = char_obj.h * char_obj.sy

                -- char_obj:draw_rec(tx, ty + self.__font_size - height, width, height)

                local quad = char_obj:get_quad()
                local x, y = char_obj:get_pos_draw_rec(tx, ty + self.__font_size - height, width, height)

                if quad then
                    self.batches[current_format]:setColor(current_color)
                    self.batches[current_format]:add(quad, x, y, 0, char_obj.sx, char_obj.sy, char_obj.ox, char_obj.oy)
                end
            end

            tx = tx + char_obj:get_width() + self.__character_space
        end

        i = i + 1
    end

    love_set_color(1, 1, 1, 1)
    for _, batch in pairs(self.batches) do
        local r = batch:getCount() > 0 and love_draw(batch)
    end

    self:pop()
    return tx, ty
end

local get_char_obj
local len
local print
local line_width
local next_not_command_index
local get_words
--- The functions below are used in the printf method
do
    get_char_obj =
    ---@return JM.Font.Glyph
    function(param)
        return param
    end

    len =
    ---@param args table
    ---@return number width
    function(self, args)
        local width = 0
        for _, obj in ipairs(args) do
            local char_obj = get_char_obj(args[_])
            width = width + char_obj:get_width() + self.__character_space
        end
        return width - self.__character_space
    end

    print =
    ---@param self JM.Font.Font
    ---@param word_list table
    ---@param tx number
    ---@param ty number
    ---@param index_action table
    ---@param current_color {[1]:JM.Color}
    function(self, word_list, tx, ty, index_action, exceed_space, current_color)
        exceed_space = exceed_space or 0

        if ty > self.__bounds.bottom
            or ty + self.__ref_height * self.__scale * 1.5 < self.__bounds.top
        then
            return
        end

        for _, batch in pairs(self.batches) do
            batch:clear()
        end

        for k, word in ipairs(word_list) do

            if index_action then
                for _, action in ipairs(index_action) do
                    if action.i == k then
                        action.action()
                    end
                end
            end

            for i = 1, #(word) do
                ---@type JM.Font.Glyph
                local char_obj = word[i] --get_char_obj(word[i])
                if char_obj then

                    char_obj:set_color2(Utils:unpack_color(current_color[1]))

                    char_obj:set_scale(self.__scale)

                    if char_obj:is_animated() then
                        char_obj:set_color({ 1, 1, 1, 1 })

                        char_obj.__anima:set_size(
                            nil, self.__font_size * 1.4,
                            nil, char_obj.__anima:get_current_frame().h
                        )

                        char_obj:draw(tx + char_obj.w / 2 * char_obj.sx,
                            ty + char_obj.h / 2 * char_obj.sy
                        )
                    else

                        local width = char_obj.w * char_obj.sx
                        local height = char_obj.h * char_obj.sy

                        local quad = char_obj:get_quad()
                        local x, y = char_obj:get_pos_draw_rec(tx, ty + self.__font_size - height, width, height)

                        if quad then
                            self.batches[char_obj.format]:setColor(unpack(char_obj.color))
                            self.batches[char_obj.format]:add(quad, x, y, 0, char_obj.sx, char_obj.sy, char_obj.ox,
                                char_obj.oy)
                        end
                        -- char_obj:draw_rec(tx, ty + self.__font_size - height, width, height)
                    end

                    tx = tx + char_obj:get_width()
                        + self.__character_space
                end
            end

            tx = tx + exceed_space
        end

        love_set_color(1, 1, 1, 1)
        for _, batch in pairs(self.batches) do
            local r = batch:getCount() > 0 and love_draw(batch)
        end

        if index_action then
            for _, action in ipairs(index_action) do
                if action.i > #word_list then
                    action.action()
                end
            end
        end
    end


    line_width =
    ---@param self JM.Font.Font
    ---@param line table
    ---@return number
    function(self, line)
        local total = 0
        for _, word in ipairs(line) do
            total = total + len(self, word) + self.__character_space
        end
        return total
    end

    next_not_command_index =
    ---@param self JM.Font.Font
    ---@param index number
    ---@param separated table
    ---@return number|nil
    function(self, index, separated)
        local current_index = index + 1

        while (separated[current_index]
            and self:__is_a_command_tag(separated[current_index])) do

            current_index = current_index + 1
        end

        if not separated[current_index] then return nil end
        return current_index
    end

    local results_get_word = setmetatable({}, { __mode = 'kv' })

    ---@param self JM.Font.Font
    ---@param separated any
    ---@param list any
    ---@return unknown
    function get_words(self, separated, list)

        local result = results_get_word[self]
            and results_get_word[self][separated]
        if result then return result end

        list = list or {}

        local current_format = self.__format
        local original_format = self.__format
        local i = 1

        while (i <= #(separated)) do
            local cur_word = separated[i] or ""

            local match = self:__is_a_command_tag(cur_word)

            if match == "<bold>" then
                current_format = self.format_options.bold
            elseif match == "</bold>" then
                current_format = original_format
            elseif match == "<italic>" then
                current_format = self.format_options.italic
            elseif match == "</italic>" then
                current_format = original_format
            end

            self:set_format_mode(current_format)

            local characters = self:get_text_iterator(cur_word)
            characters = characters:get_characters_list()

            table_insert(list, characters)

            i = i + 1
        end

        results_get_word[self] = results_get_word[self] or setmetatable({}, { __mode = 'k' })
        results_get_word[self][separated] = list

        return list
    end
end --- End auxiliary methods for printf


local color_pointer = {}

---@param text string
---@param x number
---@param y number
---@param align "left"|"right"|"center"|"justify"|nil
---@param limit_right number|nil
function Font:printf(text, x, y, align, limit_right)
    if not text or text == "" then return { tx = x, ty = y } end

    self:push()

    local tx = x
    local ty = y
    align = align or "left"
    limit_right = limit_right or 500.0 --love.mouse.getX() - x
    limit_right = limit_right - x

    local current_color = color_pointer --{ self.__default_color }
    current_color[1] = self.__default_color

    local original_color = self.__default_color

    local current_format = self.__format
    local original_format = self.__format

    local i = 1
    local separated = self:separate_string(text)

    local words = get_words(self, separated)

    local total_width = 0
    local line = {}
    local line_actions = {}

    for m = 1, #(words) do
        local command_tag = self:__is_a_command_tag(separated[m])

        if command_tag and command_tag:match("color") then
            --local action = { i = #line + 1 }

            local action_i = #line + 1
            local action_func

            if command_tag == "<color>" then
                -- --- problem
                -- ---@diagnostic disable-next-line: duplicate-set-field
                -- action.action = function()
                --     local parse = Utils:parse_csv_line(separated[m]:sub(2, #separated[m] - 1))
                --     local r = parse[2] or 1
                --     local g = parse[3] or 0
                --     local b = parse[4] or 0
                --     local a = parse[5] or 1

                --     current_color[1] = Utils:get_rgba(r, g, b, a)
                -- end

                action_func = function()
                    local parse = Utils:parse_csv_line(separated[m]:sub(2, #separated[m] - 1))
                    local r = parse[2] or 1
                    local g = parse[3] or 0
                    local b = parse[4] or 0
                    local a = parse[5] or 1

                    current_color[1] = Utils:get_rgba(r, g, b, a)
                end
            elseif command_tag == "</color>" then
                -- --- problem
                -- ---@diagnostic disable-next-line: duplicate-set-field
                -- action.action = function()
                --     current_color[1] = original_color
                -- end

                action_func = function()
                    current_color[1] = original_color
                end
            end

            table_insert(line_actions, { i = action_i, action = action_func })
        end

        local current_is_break_line = separated[m] == "\n"

        if not command_tag then

            if not current_is_break_line or true then
                table_insert(
                    line,
                    words[m]
                )
            end

            local next_index = next_not_command_index(self, m, separated)

            total_width = total_width + len(self, words[m])
                + self.__space_char:get_width()
                + self.__character_space * 2

            if total_width + (next_index and words[next_index]
                and len(self, words[next_index]) or 0) > limit_right

                or current_is_break_line
            then
                local lw = line_width(self, line)

                local div = #line - 1
                div = div <= 0 and 1 or div
                div = separated[m] == "\n" and lw <= limit_right * 0.8
                    and 100 or div

                local ex_sp = align == "justify"
                    and (limit_right - lw) / div
                    or nil

                local pos_to_draw = (align == "left" and x)
                    or (align == "right" and (x + limit_right) - lw)
                    or (align == "center" and x + limit_right / 2 - lw / 2)
                    or x

                print(self, line, pos_to_draw, ty, line_actions, ex_sp, current_color)

                total_width = 0

                ty = ty + self.__ref_height * self.__scale
                    + self.__line_space

                line = {}
                line_actions = {}
            else
                local next_index = next_not_command_index(self, m, separated)

                local next_is_broken_line = next_index and separated[next_index]
                    and separated[next_index] == "\n"

                if m ~= #words and not next_is_broken_line then
                    table_insert(
                        line,
                        { self.__space_char }
                    )
                end
            end

        end

        if line and m == #words then
            local lw = line_width(self, line)

            local pos_to_draw = (align == "left" and x)
                or (align == "right" and tx + limit_right - lw)
                or (align == "center" and tx + limit_right / 2 - lw / 2)
                or x

            print(self, line, pos_to_draw, ty, line_actions, nil, current_color)
        end
    end

    self:pop()

    -- love.graphics.setColor(0, 0, 0, 0.3)
    -- love.graphics.line(x, 0, x, love.graphics.getHeight())
    -- love.graphics.line(x + limit_right, 0, x + limit_right, love.graphics.getHeight())
end

local AlignOptions = {
    left = 1,
    right = 2,
    center = 3,
    justified = 4
}
function Font:printx(text, x, y, right, align)
    align = align or "left"

    self.buffer__ = self.buffer__ or setmetatable({}, { __mode = 'v' })
    self.buffer_time = 0.0

    local index = string.format("%s %d %d %s", text, x, y, AlignOptions[align])

    if not self.buffer__[index] then
        local f = Phrase:new({ text = text, font = self })
        --f:set_bounds(nil, nil, right)
        self.buffer__[index] = f
    end

    ---@type JM.Font.Phrase
    local fr = self.buffer__[index]
    fr:set_bounds(nil, nil, right)
    local value = fr:draw(x, y, align)

    return value
end

function Font:clear_buffer()
    self.buffer__ = nil
end

---@return JM.Font.Phrase
function Font:get_phrase(text)
    if not self.buffer__[text] then
        local f = Phrase:new({ text = text, font = self })
        self.buffer__[text] = f
    end
    return self.buffer__[text]
end

---@class JM.Font.Generator
local Generator = {
    new = function(self, args)
        local f = Font
        return Font.new(Font, args)
    end
}

return Generator

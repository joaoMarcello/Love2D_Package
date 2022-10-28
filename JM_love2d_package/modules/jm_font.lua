local Character = require("/JM_love2d_package/modules/font/character")
local Utils = require("/JM_love2d_package/utils")
local Anima = require "/JM_love2d_package/animation_module"

---@enum JM.Font.FormatOptions
local FontFormat = {
    normal = 0,
    bold = 1,
    italic = 2,
    bold_italic = 3
}

---@alias JM.AvailableFonts
---|"calibri"
---|"JM caligraphy"

---@class JM.Font.Font
---@field __nicknames {nick: string, index: number}
local Font = {}

---@overload fun(self: table, args: JM.AvailableFonts): JM.Font.Font
---@param args {name: JM.AvailableFonts, font_size: number, line_space: number, tab_size: number}
---@return JM.Font.Font new_Font
function Font:new(args)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Font.__constructor__(obj, args)

    -- Affectable.__checks_implementation__(obj)

    return obj
end

---@overload fun(self: table, args: string)
---@param args {name: string, font_size: number, line_space: number, tab_size: number, character_space: number, color: JM.Color}
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

    self.__img = self.__normal_img

    self.__quad = love.graphics.newQuad(
        0, 0,
        20, 20,
        self.__img:getDimensions()
    )

    self.__nicknames = {}

    self.__font_size = args.font_size or 20

    self.__character_space = args.character_space or 1
    self.__line_space = args.line_space or 11

    self.__characters = {}
    self.__bold_characters = {}

    self:__load_caracteres_from_csv(self.__characters,
        args.name,
        self.__normal_img
    )
    self:__load_caracteres_from_csv(self.__bold_characters,
        args.name,
        self.__bold_img,
        "_bold"
    )

    self.__format = FontFormat.normal

    self.format_options = FontFormat

    self.__ref_height = self:__get_char_equals("A").h
        or self:__get_char_equals("0").h
        or self.__font_size


    self.__word_space = self.__ref_height * 0.6

    self.__tab_size = args.tab_size or 4


    self:set_font_size(self.__font_size)

    self.__tab_char = Character:new(self.__img, self.__quad, {
        id = "\t",
        x = 0, y = 0,
        w = self.__word_space * self.__tab_size,
        h = self.__ref_height
    })

    self.__space_char = Character:new(self.__img, self.__quad, {
        id = " ",
        x = 0, y = 0,
        w = self.__word_space,
        h = self.__ref_height
    })

    table.insert(self.__characters, self.__space_char)
    table.insert(self.__characters, self.__tab_char)
    table.insert(self.__bold_characters, self.__space_char)
    table.insert(self.__bold_characters, self.__tab_char)

    self.__default_color = args.color or { 0.1, 0.1, 0.1, 1 }

    self.__bounds = { left = 0, top = 0, right = love.graphics.getWidth(), bottom = love.graphics.getHeight() }
end

---
---@param value JM.Font.FormatOptions
function Font:set_format_mode(value)
    self.__format = value
end

function Font:get_format_mode()
    return self.__format
end

function Font:__load_caracteres_from_csv(list, name, img, extend)
    if not extend then extend = "" end

    local lines = Utils:get_lines_in_file("/JM_love2d_package/data/Font/" .. name .. "/" .. name .. extend .. ".txt")

    for i = 2, #lines do
        local parse = Utils:parse_csv_line(lines[i], ",")
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


        table.insert(list,
            Character:new(img, self.__quad,
                { id = id, x = left, y = top, w = right - left, h = bottom - top, bottom = offset_y })
        )
    end

    table.insert(list, self:get_nule_character())
end

function Font:get_nule_character()
    local char_ = Character:new(nil, nil,
        { id = "__nule__", x = nil, y = nil, w = self.__word_space, h = self.__ref_height })

    return char_
end

---@return {font_size: number, character_space: number, color: JM.Color, line_space: number, word_space: number, tab_size: number, format: JM.Font.FormatOptions }
function Font:__get_configuration()
    local config = {}
    config.font_size = self.__font_size
    config.character_space = self.__character_space
    config.color = self.__default_color
    config.line_space = self.__line_space
    config.word_space = self.__word_space
    config.tab_size = self.__tab_size
    config.format = self.__format
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
local function is_valid_nickname(nickname)
    if #nickname > 4
        and nickname:sub(1, 2) == "--"
        and nickname:sub(#nickname - 1) == "--" then
        return true
    end
    return false
end

---@param nickname string
---@param args {img: love.Image|string, frames: number, frames_list: table,  speed: number, rotation: number, color: JM.Color, scale: table, flip_x: boolean, flip_y: boolean, is_reversed: boolean, stop_at_the_end: boolean, amount_cycle: number, state: JM.AnimaStates, bottom: number, kx: number, ky: number, width: number, height: number, ref_width: number, ref_height: number, duration: number}
function Font:add_nickname_animated(nickname, args)
    assert(is_valid_nickname(nickname),
        "\nError: Invalid nickname. The nickname should start and ending with '--'. \nExamples: --icon--, -- emoji --.")

    local animation = Anima:new(args)

    local new_character = Character:new(nil, nil, {
        id = nickname,
        anima = animation,
        w = self.__ref_height * 1.5,
        h = self.__ref_height
    })

    table.insert(self.__nicknames, {
        nick = nickname, index = #self.__characters + 1
    })

    table.insert(self.__characters, new_character)
    table.insert(self.__bold_characters, new_character)

    return animation
end

---
---@param nickname string
---@param args {img: string|love.Image, frame: table, width: number, height: number}
function Font:add_nickname(nickname, args)
    assert(is_valid_nickname(nickname),
        "\nError: Invalid nickname. The nickname should start and ending with '--'. \nExamples: --icon--, -- emoji --.")

    if not args.bottom then args.bottom = self.__ref_height end
    if not args.width then args.width = args.bottom end

    local animation = Anima:new({
        img = args.img,
        frames_list = { args.frame },
        width = args.width,
        height = args.bottom,
    })

    local new_character = Character:new(nil, nil, {
        id = nickname,
        anima = animation,
        w = args.width,
        h = args.bottom
    })


    table.insert(self.__nicknames, {
        nick = nickname, index = #self.__characters + 1
    })

    table.insert(self.__characters, new_character)
    table.insert(self.__bold_characters, new_character)

    return animation
end

---@param s string
---@return string|nil nickname
function Font:__is_a_nickname(s, index)
    for i = 1, #self.__nicknames do
        local nick = self.__nicknames[i].nick
        if s:sub(index, index + #nick - 1) == nick then
            return nick
        end
    end
    return nil
end

function Font:string_is_nickname(s)
    return self:__is_a_nickname(s, 1)
end

function Font:update(dt)
    for i = 1, #(self.__nicknames) do
        local character = self.__characters[self.__nicknames[i].index]
        local r = character and character:update(dt)
    end
end

---@param index number
---@return JM.Font.Character|nil
function Font:__get_char_by_index(index)
    local list = self.__format == FontFormat.normal and self.__characters
        or self.__bold_characters
    return list[index]
end

---@param c string
---@return JM.Font.Character|nil
function Font:__get_char_equals(c)
    local list = self.__format == FontFormat.normal and self.__characters
        or self.__bold_characters

    for i = 1, #list do
        local char__ = self:__get_char_by_index(i)

        if c == self:__get_char_by_index(i).__id then
            -- if char__ and char__.__id:match(c) then
            return self:__get_char_by_index(i)
        end

        -- if self:string_is_nickname(c) then
        --     for i = 1, #self.__nicknames do
        --         local character = list[self.__nicknames[i].index]
        --         if c == character.__id then
        --             return character
        --         end
        --     end
        -- end
    end
    return nil
end

---@param s string
function Font:separate_string(s, list)
    s = s .. " "
    local sep = "\n "
    local current_init = 1
    local words = list or {}

    while (current_init <= #(s)) do
        local regex = "[^[ ]]*.-[" .. sep .. "]"
        local tag_regex = "< *[%d, .%w/]*>"

        local tag = s:match(tag_regex, current_init)
        local find = not tag and s:match(regex, current_init)
        local nick = find and string.match(find, "%-%-%w-%-%-") and false

        if tag then
            local startp, endp = string.find(s, tag_regex, current_init)
            local sub_s = s:sub(startp, endp)
            local prev_s = s:sub(current_init, startp - 1)

            if prev_s ~= "" and prev_s ~= " " then
                self:separate_string(prev_s, words)
            end

            table.insert(words, sub_s)
            current_init = endp

        elseif nick and nick ~= "----" then
            local startp, endp = string.find(s, "%-%-%w-%-%-", current_init)
            local sub_s = s:sub(startp, endp)
            local prev_word = s:sub(current_init, startp - 1)

            if prev_word and prev_word ~= "" and prev_word ~= " " then
                self:separate_string(prev_word, words)
            end

            if sub_s ~= "" and sub_s ~= " " then
                table.insert(words, sub_s)
            end

            current_init = endp

        elseif find then

            local startp, endp = string.find(s, regex, current_init)
            local sub_s = s:sub(startp, endp - 1)

            if sub_s ~= "" and sub_s ~= " " then
                table.insert(words, sub_s)
            end

            if s:sub(endp, endp) == "\n" then
                table.insert(words, "\n")
            end

            current_init = endp
        else
            break
        end

        current_init = current_init + 1
    end

    local rest = s:sub(current_init, #s)

    if rest ~= "" and not rest:match(" *") then
        table.insert(words, s:sub(current_init, #s))
    end

    return words
end

function Font:__is_a_command_tag(s)
    return (s:match("< *bold *>") and "<bold>")
        or (s:match("< */ *bold *>") and "</bold>")
        or (s:match("< *color[%d, .]*>") and "<color>")
        or (s:match("< */ *color *>") and "</color>")
        or false
end

---@param text string
function Font:print(text, x, y, w, h, __i__, __color__, __x_origin__, __format__)
    if not text or text == "" then return { tx = x, ty = y } end

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
    while (i <= #(text)) do
        local char_string = text:sub(i, i)
        local is_a_nick = self:__is_a_nickname(text, i)

        if is_a_nick then
            char_string = is_a_nick
            i = i + #char_string
        end

        local tag = text:match("<.->", i)
        if tag then
            local match = self:__is_a_command_tag(tag)

            local startp, endp = text:find("<.->", i)

            local result = match and self:print(text:sub(i, startp - 1),
                tx, ty, w, h, 1,
                current_color, x_origin, current_format
            )

            if match == "<color>" then
                local parse = Utils:parse_csv_line(text:sub(startp - 1, endp - 1))
                local r = parse[2] or 1
                local g = parse[3] or 0
                local b = parse[4] or 0

                current_color = { r, g, b, 1 }
            elseif match == "</color>" then
                current_color = original_color
            elseif match == "<bold>" then
                current_format = self.format_options.bold
            elseif match == "</bold>" then
                current_format = original_format
            end

            if match then
                i = endp
                if endp == #text then
                    i = i + 1
                end
                tx = result.tx
                ty = result.ty
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
                    nil, char_obj.__anima:__get_current_frame().h
                )

                char_obj:draw(tx + char_obj.w / 2 * char_obj.sx,
                    ty + char_obj.h / 2 * char_obj.sy
                )
            else

                local width = char_obj.w * char_obj.sx
                local height = char_obj.h * char_obj.sy

                char_obj:draw_rec(tx, ty + self.__font_size - height, width, height)
            end

            tx = tx + char_obj:get_width() + self.__character_space
        end

        i = i + 1
    end

    self:pop()
    return { tx = tx, ty = ty }
end

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
    limit_right = limit_right or love.mouse.getX() - x

    local current_color = self.__default_color
    local original_color = self.__default_color

    local current_format = self.__format
    local original_format = self.__format

    local i = 1
    local separated = self:separate_string(text)
    local words = {}

    while (i <= #(separated)) do
        local cur_word = separated[i] or ""

        local match = self:__is_a_command_tag(cur_word)

        if match == "<bold>" then
            current_format = self.format_options.bold
        elseif match == "</bold>" then
            current_format = original_format
        end

        self:set_format_mode(current_format)

        local characters = {}
        local j = 1
        while (j <= #cur_word) do

            local char_obj

            local is_a_nick = self:__is_a_nickname(cur_word, j)

            if is_a_nick then
                char_obj = self:__get_char_equals(is_a_nick)
                j = j + #is_a_nick - 1
            end

            char_obj = not char_obj
                and self:__get_char_equals(cur_word:sub(j, j))
                or char_obj

            if not char_obj then
                char_obj = self:__get_char_equals(cur_word:sub(j, j + 1))
                j = j + 1
            end

            if char_obj then
                table.insert(characters, char_obj)
            end

            j = j + 1
        end

        table.insert(words, characters)

        i = i + 1
    end


    local get_char_obj =
    ---@return JM.Font.Character
    function(param)
        return param
    end

    local len =
    ---@param args table
    ---@return number width
    function(args)
        local width = 0
        for _, obj in ipairs(args) do
            local char_obj = get_char_obj(args[_])
            width = width + char_obj:get_width() + self.__character_space
        end
        return width - self.__character_space
    end

    local print =
    ---@param word_list table
    ---@param tx number
    ---@param ty number
    ---@param index_action table
    function(word_list, tx, ty, index_action, exceed_space)
        exceed_space = exceed_space or 0

        if ty > self.__bounds.bottom
            or ty + self.__ref_height * self.__scale * 1.5 < self.__bounds.top
        then
            return
        end

        for k, word in ipairs(word_list) do

            if index_action then
                for _, action in ipairs(index_action) do
                    if action.i == k then
                        action.action(tx, ty)
                    end
                end
            end

            for i = 1, #(word) do
                local char_obj = get_char_obj(word[i])
                if char_obj then
                    char_obj:set_color(current_color)
                    char_obj:set_scale(self.__scale)

                    if char_obj:is_animated() then
                        char_obj:set_color({ 1, 1, 1, 1 })

                        char_obj.__anima:set_size(
                            nil, self.__font_size * 1.4,
                            nil, char_obj.__anima:__get_current_frame().h
                        )

                        char_obj:draw(tx + char_obj.w / 2 * char_obj.sx,
                            ty + char_obj.h / 2 * char_obj.sy
                        )
                    else

                        local width = char_obj.w * char_obj.sx
                        local height = char_obj.h * char_obj.sy

                        char_obj:draw_rec(tx, ty + self.__font_size - height, width, height)
                    end

                    tx = tx + char_obj:get_width()
                        + self.__character_space
                end
            end

            tx = tx + exceed_space
        end

        if index_action then
            for _, action in ipairs(index_action) do
                if action.i > #word_list then
                    action.action(tx, ty)
                end
            end
        end
    end

    local line_width =
    function(line)
        local total = 0
        for _, word in ipairs(line) do
            total = total + len(word) + self.__character_space
        end
        return total
    end

    local next_not_command_index =
    ---@param index number
    function(index)
        local current_index = index + 1

        while (separated[current_index]
            and self:__is_a_command_tag(separated[current_index])) do

            current_index = current_index + 1
        end

        if not separated[current_index] then return nil end
        return current_index
    end

    local total_width = 0
    local line = {}
    local line_actions = {}

    for m = 1, #(words) do
        local command_tag = self:__is_a_command_tag(separated[m])

        if command_tag and command_tag:match("color") then
            local action = { i = #line + 1 }

            if command_tag == "<color>" then
                action.action = function()
                    local parse = Utils:parse_csv_line(separated[m]:sub(2, #separated[m] - 1))
                    local r = parse[2] or 1
                    local g = parse[3] or 0
                    local b = parse[4] or 0

                    current_color = { r, g, b, 1 }
                end
            elseif command_tag == "</color>" then
                action.action = function()
                    current_color = original_color
                end
            end
            table.insert(line_actions, action)
        end

        if not command_tag then

            table.insert(
                line,
                words[m]
            )

            local next_index = next_not_command_index(m)

            total_width = total_width + len(words[m]) + self.__space_char:get_width() + self.__character_space * 2

            if total_width + (next_index and words[next_index]
                and len(words[next_index]) or 0) >= limit_right
            then
                local lw = line_width(line)

                local div = #line - 1
                div = div <= 0 and 1 or div

                local ex_sp = align == "justify"
                    and (limit_right - lw) / div
                    or nil

                local pos_to_draw = (align == "left" and x)
                    or (align == "right" and (x + limit_right) - lw)
                    or (align == "center" and x + limit_right / 2 - lw / 2)
                    or x

                print(line, pos_to_draw, ty, line_actions, ex_sp)


                total_width = 0

                ty = ty + self.__ref_height * self.__scale
                    + self.__line_space

                line = {}
                line_actions = {}
            else
                if m ~= #words then
                    table.insert(
                        line,
                        { self.__space_char }
                    )
                end
            end

            if line and m == #words then
                local lw = line_width(line)

                local pos_to_draw = (align == "left" and x)
                    or (align == "right" and tx + limit_right - lw)
                    or (align == "center" and tx + limit_right / 2 - lw / 2)
                    or x

                print(line, pos_to_draw, ty, line_actions)
            end
        end

    end

    self:pop()

    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.line(x, 0, x, 600)
    love.graphics.line(x + limit_right, 0, x + limit_right, 600)
end

return Font

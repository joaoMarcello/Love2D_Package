local EffectManager = require("/JM_love2d_package/modules/classes/EffectManager")
local Affectable = require("/JM_love2d_package/modules/templates/Affectable")
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
---@param args {name: string, font_size: number, line_space: number, tab_size: number, character_space: number}
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

    self.__default_color = { 0.1, 0.1, 0.1, 1 }

    self.__nicknames = {}

    self.__bounds = { x = 50, y = 110, w = 230, h = 500 }
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

    if not args.height then args.height = self.__ref_height end
    if not args.width then args.width = args.height end

    local animation = Anima:new({
        img = args.img,
        frames_list = { args.frame },
        width = args.width,
        height = args.height,
    })

    local new_character = Character:new(nil, nil, {
        id = nickname,
        anima = animation,
        w = args.width,
        h = args.height
    })

    -- animation:set_size(new_character.w, new_character.h, animation:__get_current_frame().w, args.height)

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

---@param s string
---@param index number
local function __is_command(s, index)
    local command = { "color", "italic", "bold" }

    for i = 1, #command do
        if s:sub(index, index) == "<" then
            local startp, endp = s:find(">", index)

            if startp then
                local start2, endp2 = s:find("</" .. command[i] .. ">", endp)
                if start2 then
                    local command_line = s:sub(index + 1, endp - 1)
                    local parse = Utils:parse_csv_line(command_line)

                    if parse[1] == command[i] then
                        local color = {
                            tonumber(parse[2]),
                            tonumber(parse[3]),
                            tonumber(parse[4]),
                            1
                        }
                        return {
                            command = command[i],
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
end

function Font:update(dt)
    for i = 1, #self.__nicknames do
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
    end
    return nil
end

---@param text string
---@param x number # Position to draw in the x-axis.
---@param y number # Position to draw in the y-axis.
---@param w number|nil
---@param h number|nil
function Font:print(text, x, y, w, h)
    local tx = x
    local ty = y

    local jump = -1
    local jumped = 0
    local last_was_nickname = nil
    local last_was_command = nil
    local color = self.__default_color
    local change_color = nil
    local italic = nil
    local bold = nil
    local animated_char_stack = {}

    for i = 1, #text do
        if jump > 0 then
            jump = jump - 1
            goto continue
        end

        local check_command = __is_command(text, i)

        -- Checking if current char is a valid tag
        if check_command then
            last_was_command = text:sub(i - 1, i - 1)

            if check_command.command == "color" then
                change_color = check_command
                color = change_color.color
            elseif check_command.command == "italic" then
                italic = check_command
                color = { 0, 0.5, 0.9, 1 }
            elseif check_command.command == "bold" then
                bold = check_command
                color = { 1, 0, 1, 1 }
            end
            jump = check_command.final1 - check_command.start1
            jumped = jump
            goto continue
        end -- END if current char is the start of a command

        -- If detected color command tag...
        if change_color then
            color = change_color.color

            if i > change_color.final2 then
                color = self.__default_color
                change_color = nil
            elseif i >= change_color.start2 then
                last_was_command = text:sub(i - 1, i - 1)
                jump = change_color.final2 - change_color.start2
                jumped = jump
                goto continue
            end
        end

        -- If detected italic command tag...
        if italic then
            if i > italic.final2 then
                italic = nil
                color = self.__default_color
            elseif i >= italic.start2 then
                last_was_command = text:sub(i - 1, i - 1)
                jump = italic.final2 - italic.start2
                jumped = jump
                goto continue
            end
        end

        -- If detected bold command tag...
        if bold then
            if i > bold.final2 then
                bold = nil
                color = self.__default_color
            elseif i >= bold.start2 then
                last_was_command = text:sub(i - 1, i - 1)
                jump = bold.final2 - bold.start2
                jumped = jump
                goto continue
            end
        end

        local current_char = text:sub(i, i)
        local prev_char = text:sub(i - 1 - jumped, i - 1 - jumped)
        local next_char = text:sub(i + 1, i + 1)

        -- Tells if current char is the init of a nickname. If true, this variable will store the whole nickname string.
        local found_a_nickname = self:__is_a_nickname(text, i)

        if found_a_nickname then
            current_char = found_a_nickname
        end

        if last_was_nickname then
            prev_char = last_was_nickname
            last_was_nickname = nil
        end

        if last_was_command then
            prev_char = last_was_command
            last_was_command = nil
        end

        local character = self:__get_char_equals(current_char)
        if not character then character = self:get_nule_character() end
        local last = self:__get_char_equals(prev_char)
        if not last and i ~= 1 then last = self:get_nule_character() end
        local next = self:__get_char_equals(next_char)

        -- The width in pixels from previous Character object
        local last_w = last and last.w

        if jump == 0 then
            jump = -1
            jumped = 0
        end

        -- The width in pixels from next Character object
        local next_w = (next and next.w)
        -- or (next_char) == " " and self.__word_space


        local condition_1 = current_char == "\n"

        -- The current x position will exceed the allowed width
        local condition_2 = w and character and last_w
            and tx + character.w * self.__scale + last_w * self.__scale + (self.__character_space * 2) > x + w

        -- Broken line or current x position will exceed the desired width.
        if condition_1 or condition_2 then

            ty = ty + self.__line_space + self.__ref_height * self.__scale
            tx = x

            -- Current char is "\n"
            if condition_1 then
                goto continue
            else -- Current x position is bigger than desired width
                last_w = nil
            end
        end

        -- Updating the x position to draw
        if last_w and character then
            tx = tx + self.__character_space + last_w * self.__scale
        end

        if h and ty >= y + h then
            break
        end

        if character then
            if character:is_animated() then
                table.insert(animated_char_stack, { char = character, x = tx, y = ty })
            else
                character:set_color(color)

                character:set_scale(self.__scale)

                local width = character.w * character.sx
                local height = character.h * character.sy
                character:draw_rec(tx, ty + self.__font_size - height, width, height)
            end
        end

        if found_a_nickname then
            jump = #found_a_nickname - 1
            jumped = jump
            last_was_nickname = found_a_nickname
        end

        -- The FOR loop end block
        ::continue::
    end -- END FOR each character in the text

    -- Drawing the animated characters
    for i = 1, #animated_char_stack do
        local get_ =
        ---@return JM.Font.Character
        function(arg)
            return arg.char
        end

        local character = get_(animated_char_stack[i])
        local tx = animated_char_stack[i].x
        local ty = animated_char_stack[i].y

        character:set_scale(self.__scale)

        character.__anima:set_size(
            nil, self.__font_size * 1.4,
            nil, character.__anima:__get_current_frame().h
        )

        character:draw(tx + character.w / 2 * character.sx,
            ty + character.h / 2 * character.sy
        )
    end
end

function Font:print2(text, x, y, w, h, __i__, __color__, __x_origin__, __format__)
    w = w or love.graphics.getWidth()
    h = h or love.graphics.getHeight()

    local tx = x
    local ty = y
    local current_color = __color__ or self.__default_color
    local current_format = __format__ or self.format_options.normal
    local x_origin = __x_origin__ or tx

    local i = __i__ or 1
    while (i <= #(text)) do
        local char_string = text:sub(i, i)
        local is_a_nick = self:__is_a_nickname(text, i)

        if is_a_nick then
            char_string = is_a_nick
            i = i + #char_string
        end

        local startp, endp = text:find("< *color[%d .,]*>", i)
        if startp then
            local parse = Utils:parse_csv_line(text:sub(startp - 1, endp - 1))
            local r = parse[2] or 1
            local g = parse[3] or 0
            local b = parse[4] or 0

            local result = self:print2(text:sub(i, startp - 1), tx, ty, w, h, 1, current_color, x_origin, current_format)

            current_color = { r, g, b, 1 }

            tx = result.tx
            ty = result.ty

            i = endp
            char_string = ""
        else
            startp, endp = text:find("< */ *color *>", i)
            if startp then
                local result = self:print2(text:sub(i, startp - 1), tx, ty, w, h, 1, current_color, x_origin)

                current_color = self.__default_color

                tx = result.tx
                ty = result.ty

                i = endp
                char_string = ""
            end
        end

        startp = nil
        startp, endp = text:find("<bold>", i)
        if startp then
            local r = self:print2(text:sub(i, startp - 1), tx, ty, w, h, 1, current_color, x_origin, current_format)

            current_format = self.format_options.bold
            tx = r.tx
            ty = r.ty

            i = endp
            char_string = ""
        else
            startp, endp = text:find("< */ *bold *>", i)

            if startp then
                local r = self:print2(text:sub(i, startp - 1), tx, ty, w, h, 1, current_color, x_origin, current_format)

                current_format = self.format_options.normal
                
                tx = r.tx
                ty = r.ty

                i = endp
                char_string = ""
            end
        end

        self:set_format_mode(current_format)

        local char_obj = self:__get_char_equals(char_string)

        if not char_obj then
            char_obj = self:__get_char_equals(text:sub(i, i + 1))
        end

        if char_string == "\n"
            or char_obj and tx + self.__word_space + char_obj:get_width() >= w
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

    return { tx = tx, ty = ty }
end

return Font

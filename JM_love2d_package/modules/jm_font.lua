local EffectManager = require("/JM_love2d_package/modules/classes/EffectManager")
local Affectable = require("/JM_love2d_package/modules/templates/Affectable")
local Character = require("/JM_love2d_package/modules/font/character")
local Utils = require("/JM_love2d_package/utils")
local Anima = require "/JM_love2d_package/animation_module"

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

    self.__img = love.graphics.newImage("/JM_love2d_package/data/Font/calibri/" .. args.name .. ".png")
    -- self.__img:setFilter("linear", "nearest")

    self.__quad = love.graphics.newQuad(
        0, 0,
        20, 20,
        self.__img:getDimensions()
    )

    self.__font_size = args.font_size or 20

    self.__character_space = args.character_space or 2
    self.__line_space = args.line_space or 13

    self.__characters = {}

    local lines = Utils:get_lines_in_file("/JM_love2d_package/data/Font/Calibri/" .. args.name .. ".txt")

    for i = 2, #lines do
        local parse = Utils:parse_csv_line(lines[i], ",")
        local id = (parse[1])
        if id == "" then
            id = ","
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
        table.insert(self.__characters,
            Character:new(self.__img, self.__quad,
                { id = id, x = left, y = top, w = right - left, h = bottom - top, bottom = offset_y })
        )
    end

    self.__ref_height = self:__get_char_equals("A").h
        or self:__get_char_equals("0").h
        or self.__font_size


    self.__word_space = self.__ref_height * 0.5

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

    self.__default_color = { 0.1, 0.1, 0.1, 1 }

    self.__nicknames = {}

    self.__bounds = { x = 50, y = 110, w = 230, h = 500 }
end

function Font:__get_configuration()
    local config = {}
    config.font_size = self.__font_size
    config.character_space = self.__character_space
    config.color = self.__default_color
    config.line_space = self.__line_space
    config.word_space = self.__word_space
    config.tab_size = self.__tab_size

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
function Font:add_nickname(nickname, args)
    assert(is_valid_nickname(nickname),
        "\nError: Invalid nickname. The nickname should start and ending with '--'. \nExamples: --icon--, -- emoji --.")

    args.height = self.__font_size * 1.5
    local animation = Anima:new(args)
    -- animation:set_size(nil, self.__font_size * 1.5, nil, animation:__get_current_frame().h)

    local new_character = Character:new(nil, nil, {
        id = nickname,
        anima = animation,
        w = animation:__get_current_frame().w, --self.__ref_height,
        h = self.__ref_height
    })

    table.insert(self.__nicknames, {
        nick = nickname, index = #self.__characters + 1
    })

    table.insert(self.__characters, new_character)

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
    return self.__characters[index]
end

---@param c string
---@return JM.Font.Character|nil
function Font:__get_char_equals(c)
    for i = 1, #self.__characters do
        if c == self:__get_char_by_index(i).__id then
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
        local last = self:__get_char_equals(prev_char)
        local next = self:__get_char_equals(next_char)

        -- The width in pixels from previous Character object
        local last_w = last and last.w
        -- or (prev_char == " " and self.__word_space)
        -- or (prev_char) == "\t"
        -- and self.__word_space * self.__tab_size

        if jump == 0 then
            jump = -1
            jumped = 0
        end

        -- The width in pixels from next Character object
        local next_w = (next and next.w)
        -- or (next_char) == " " and self.__word_space

        -- The current char is TAB
        -- if current_char == "\t" then
        --     tx = tx + (self.__word_space * self.__scale * self.__tab_size)

        --     if w and next_w and tx + (next_w * self.__scale) + self.__character_space * 2 > w then
        --         tx = x
        --         ty = ty + self.__line_space + self.__ref_height * self.__scale
        --     end
        -- end

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

        -- Current char is space
        -- if current_char == " " then
        --     tx = tx + (self.__word_space * self.__scale * 0) + (last_w and last_w * self.__scale or 0)
        --     goto continue
        -- end

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

                character:__draw__(tx, ty + self.__font_size - character.h * self.__scale)
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
        local character = animated_char_stack[i].char
        local tx = animated_char_stack[i].x
        local ty = animated_char_stack[i].y

        character:set_scale(self.__scale)
        character:__draw__(tx,
            ty + self.__font_size - (character.h * self.__scale)
        )
    end
end

return Font

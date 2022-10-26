local EffectManager = require("/JM_love2d_package/effect_generator_module")
local Affectable = require("/JM_love2d_package/modules/templates/Affectable")

---@class JM.Font.Word
local Word = {}

---@param args {text: string, font: JM.Font.Font, format: JM.Font.FormatOptions}
---@return JM.Font.Word phrase
function Word:new(args)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Word.__constructor__(obj, args)

    return obj
end

---@param args {text: string, font: JM.Font.Font, format: JM.Font.FormatOptions}
function Word:__constructor__(args)
    self.__text = args.text
    self.__font = args.font
    self.__args = args

    self.__font_config = self.__font:__get_configuration()

    self.__characters = {}

    local format = args.format or self.__font.format_options.normal
    self:__load_characters(format)
end

function Word:__load_characters(mode)
    local last_font_format = self.__font:get_format_mode()

    self.__font:set_format_mode(mode)
    self.__characters = {}

    local i = 1
    while (i <= #self.__text) do
        local cur_char = self.__text:sub(i, i)

        local is_nick = self.__font:__is_a_nickname(self.__text, i)
        if is_nick then
            cur_char = is_nick
            i = i + #is_nick - 1
        end

        local char_obj = self.__font:__get_char_equals(cur_char)

        -- Verifying if current char is a special character
        if not char_obj then
            char_obj = self.__font:__get_char_equals(self.__text:sub(i, i + 1))
            if char_obj then
                cur_char = self.__text:sub(i, i + 1)
                i = i + 1
            end
        end

        if not char_obj and cur_char ~= "\n" and cur_char ~= "\t" then
            char_obj = self.__font:get_nule_character()
        end

        if char_obj then
            local startp, endp = self.__text:find(cur_char, i)

            char_obj = char_obj:copy()
            char_obj:set_color(self.__font.__default_color)
            table.insert(self.__characters, char_obj)

            if char_obj:is_animated() then
                char_obj:set_color({ 1, 1, 1, 1 })
                char_obj.__anima:set_size(nil, self.__font.__font_size * 1.1, nil, nil)
            end
        else
            break
        end
        i = i + 1
    end

    self.__font:set_format_mode(last_font_format)
end

function Word:turn_into_bold(startp, endp)
    if not startp then startp = 1 end
    if not endp then endp = #(self.__characters) end
    local last_font_format = self.__font:get_format_mode()

    self.__font:set_format_mode(self.__font.format_options.bold)

    local i = startp
    while (i <= endp) do
        local current_char = self:__get_char_by_index(i)
        local bold_char = self.__font:__get_char_equals(current_char.__id)
        local color_char = current_char:get_color()

        self.__characters[i] = bold_char and bold_char:copy() or self.__characters[i]

        self.__characters[i]:set_color(color_char)

        i = i + 1
    end

    self.__font:set_format_mode(last_font_format)
end

---
function Word:copy()
    local cpy = Word:new(self.__args)
    return cpy
end

---@param startp number|nil
---@param endp number|nil
---@param effect_type "freaky"|"pump"
---@param offset number|nil
function Word:apply_effect(startp, endp, effect_type, offset)
    if not startp then startp = 1 end
    if not endp then endp = #self.__characters end
    if not offset then offset = 0 end

    for i = startp, endp, 1 do
        local eff

        if effect_type == "freaky" or true then
            eff = EffectManager:generate("float", {
                range = 1.0,
                speed = 0.2,
                rad = math.pi * (i % 4) + offset
            })
        elseif effect_type == "pump" then
            eff = EffectManager:generate("jelly")
        end

        local char__ = self:__get_char_by_index(i)
        if char__ and char__:is_animated() then
            eff:apply(char__.__anima)
        else
            eff:apply(self.__characters[i])
        end
    end

end

function Word:surge_effect(startp, endp, delay)
    if not startp then startp = 1 end
    if not endp then endp = #self.__characters end
    if not delay then delay = 1 end

    for i = startp, endp, 1 do
        local eff = EffectManager:generate("fadein", {
            delay = delay
        })
        eff:apply(self.__characters[i])
        delay = delay + 0.5
    end
    return delay
end

--- change the word color
---@param color JM.Color
function Word:set_color(color, startp, endp)
    -- if self.__font:__is_a_nickname(self.__text, 1) then
    --     local char__ = self:__get_char_by_index(1)
    --     if char__ and char__:is_animated() then char__.__anima:set_color(color) end
    --     return
    -- end

    if not startp then startp = 1 end
    if not endp then endp = #self.__characters end

    local i = startp
    while (i <= endp) do
        local char_ = self:__get_char_by_index(i)
        local r = char_ and char_:set_color(color)
        i = i + 1
    end
end

---
function Word:update(dt)
    for i = 1, #self.__characters, 1 do
        local char_ = self:__get_char_by_index(i)
        char_:update(dt)
    end
end

---@param index number
---@return JM.Font.Character
function Word:__get_char_by_index(index)
    return self.__characters[index]
end

---
function Word:get_width()
    local w = 0

    for i = 1, #self.__characters do
        local cur_char = self:__get_char_by_index(i)
        w = w + (cur_char.w * self.__font.__scale)
            + self.__font.__character_space
    end

    return w - self.__font.__character_space
end

---
function Word:get_height()
    local h = self.__font.__font_size + self.__font.__line_space
    return h
end

---@alias JM.Font.CharacterPosition {x: number, y:number, char: JM.Font.Character}

---@return JM.Font.CharacterPosition|nil
function Word:draw(x, y, __max_char__, __character_count__)
    love.graphics.setColor(0.9, 0, 0, 0.15)
    love.graphics.rectangle("fill", x, y, self:get_width(), self.__font.__font_size)


    local tx = x
    local font = self.__font
    local cur_char

    for i = 1, #self.__characters do
        cur_char = self:__get_char_by_index(i)

        cur_char:set_color(cur_char.__color)
        cur_char:set_scale(font.__scale)

        if not cur_char:is_animated() then
            cur_char:draw_rec(tx, y, cur_char.w * cur_char.sx, font.__font_size)
        else
            cur_char.__anima:set_size(
                nil, self.__font.__font_size * 1.4,
                nil, cur_char.__anima:__get_current_frame().h
            )

            local pos_y = y + cur_char.h / 2 * cur_char.sy

            local pos_x = tx + cur_char.w / 2 * cur_char.sx

            cur_char:draw(pos_x, pos_y)
        end

        tx = tx + cur_char.w * font.__scale + font.__character_space

        if __character_count__ then
            __character_count__[1] = __character_count__[1] + 1

            if __max_char__ and __character_count__[1] >= __max_char__ then
                return { x = tx, y = y, char = cur_char }
            end
        end
    end

    if self.__text ~= " " then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", x - 2, y - 2, self:get_width() + 4, self.__font.__font_size + 4)
    end
end

return Word

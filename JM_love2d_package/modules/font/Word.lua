local EffectManager = require("/JM_love2d_package/effect_generator_module")
local Affectable = require("/JM_love2d_package/modules/templates/Affectable")

---@class JM.Font.Word
local Word = {}

---@param args {text: string, font: JM.Font.Font}
---@return JM.Font.Word phrase
function Word:new(args)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Word.__constructor__(obj, args)

    return obj
end

---@param args {text: string, font: JM.Font.Font}
function Word:__constructor__(args)
    self.__text = args.text
    self.__font = args.font
    self.__args = args

    self.__font_config = self.__font:__get_configuration()

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

        if not char_obj and cur_char ~= "\n" and cur_char ~= "\t" then
            char_obj = self.__font:get_nule_character()
        end

        if char_obj then
            char_obj = char_obj:copy()
            table.insert(self.__characters, char_obj)

            if char_obj:is_animated() then
                char_obj.__anima:set_size(nil, self.__font.__font_size * 1.1, nil, nil)
            end
        end
        i = i + 1
    end
end

---
function Word:copy()
    local cpy = Word:new(self.__args)
    return cpy
end

---@param startp number|nil
---@param endp number|nil
---@param offset number|nil
function Word:freaky_effect(startp, endp, offset)
    if not startp then startp = 1 end
    if not endp then endp = #self.__characters end
    if not offset then offset = 0 end

    for i = startp, endp, 1 do
        local eff = EffectManager:generate("float", {
            range = 1.0,
            speed = 0.2,
            rad = math.pi * (i % 4) + offset
        })

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
    if self.__font:__is_a_nickname(self.__text, 1) then
        local char__ = self:__get_char_by_index(1)
        if char__ and char__:is_animated() then char__.__anima:set_color(color) end
        return
    end

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

---
function Word:draw(x, y)
    local tx = x
    local font = self.__font

    for i = 1, #self.__characters do
        local cur_char = self:__get_char_by_index(i)

        cur_char:set_color(cur_char.__color)
        cur_char:set_scale(self.__font.__scale)

        if not cur_char:is_animated() or true then
            -- cur_char:__draw__(tx,
            --     y + self.__font.__font_size - cur_char.h * cur_char.sy
            -- )

            cur_char:draw_rec(tx, y, cur_char.w * cur_char.sx, self.__font.__font_size)

        end

        tx = tx + cur_char.w * self.__font.__scale + self.__font.__character_space
    end

    love.graphics.setColor(0.9, 0, 0, 0.15)
    love.graphics.rectangle("fill", x, y, self:get_width(), self.__font.__font_size)

end

return Word

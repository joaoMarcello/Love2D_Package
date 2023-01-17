---@type string
local path = ...

---@class JM.Font.Manager
local Font = {}

Font.fonts = {}
do
    ---@type JM.Font.Generator
    local Generator = require(path:gsub("jm_font", "jm_font_generator"))
    Font.fonts[1] = Generator:new({ name = "consolas", font_size = 10, tab_size = 4 })
end

---@type JM.Font.Font
Font.current = Font.fonts[1]

function Font:update(dt)
    for i = 1, #self.fonts do
        ---@type JM.Font.Font
        local font = self.fonts[i]
        font:update(dt)
    end
end

---@param font JM.Font.Font
function Font:set_font(font)
    self.current = font
end

function Font:print(text, x, y, w, h)
    text = tostring(text)
    Font.current:print(text, x, y, w, h)
end

function Font:printf(text, x, y, align, limit_right)
    return Font.current:printf(text, x, y, align, limit_right)
end

function Font:printx(text, x, y, align, limit_right)
    local r = Font.current:printx(text, x, y, limit_right, align)
    return r
end

function Font:get_phrase(text)
    return Font.current:get_phrase(text)
end

return Font

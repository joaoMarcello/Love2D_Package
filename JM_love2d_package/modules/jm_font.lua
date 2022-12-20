---@type string
local path = ...

local Generator = require(path:gsub("jm_font", "jm_font_generator"))

local Font = {}

Font.fonts = {}
Font.fonts[1] = Generator:new({ name = "consolas", font_size = 12, tab_size = 4 })

---@type JM.Font.Font
Font.current = Font.fonts[1]

function Font:print(text, x, y, h)
    Font.current:print(text, x, y, y, h)
end

function Font:printf(text, x, y, align, limit_right)
    return Font.current:printf(text, x, y, align, limit_right)
end

function Font:printx(text, x, y, limit_right)
    return Font.current:printx(text, x, y, limit_right)
end

return Font

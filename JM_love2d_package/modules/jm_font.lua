---@type string
local path = ...

---@type JM.Font.Generator
local Generator = require(path:gsub("jm_font", "jm_font_generator"))

local Font = {}

Font.fonts = {}
Font.fonts[1] = Generator:new({ name = "consolas", font_size = 12, tab_size = 4 })

---@type JM.Font.Font
Font.current = Font.fonts[1]

function Font:update(dt)
    for _, font in ipairs(self.fonts) do
        ---@type JM.Font.Font
        local font = font
        font:update(dt)
    end
end

---@param font JM.Font.Font
function Font:set_font(font)
    self.current = font
end

function Font:print(text, x, y, h)
    Font.current:print(text, x, y, y, h)
end

function Font:printf(text, x, y, align, limit_right)
    return Font.current:printf(text, x, y, align, limit_right)
end

function Font:printx(text, x, y, limit_right, align)
    return Font.current:printx(text, x, y, limit_right, align)
end

return Font

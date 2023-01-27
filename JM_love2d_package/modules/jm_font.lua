---@type string
local path = ...

---@class JM.Font.Manager
local Font = {}

Font.fonts = {}
do
    ---@type JM.Font.Generator
    local Generator = require(path:gsub("jm_font", "jm_font_generator"))

    local glyphs = [[aAàÀáÁãÃâÂäÄeEéÉèÈêÊëËiIíÍìÌîÎïÏoOóÓòÒôÔõÕöÖuUúÚùÙûÛüÜbBcCçÇdDfFgGhHjJkKlLmMnNpPqQrRsStTvVwWxXyYzZ0123456789+-=/*%\#§@({[]})|_"'!?,.:;ªº°¹²³£¢<>¨¬~$&^--dots----trav--]]

    local glyphs_bold = [[aAàÀáÁãÃâÂäÄeEéÉèÈêÊëËiIíÍìÌîÎïÏoOóÓòÒôÔõÕöÖuUúÚùÙûÛüÜbBcCçÇdDfFgGhHjJkKlLmMnNpPqQrRsStTvVwWxXyYzZ0123456789+-=/*%\#§@({[]})|_"'!?,.:;ªº°¹²³£¢¬¨~$<>&]]

    local glyphs_italic = [[aAàÀáÁãÃâÂäÄeEéÉèÈêÊëËiIíÍìÌîÎïÏoOóÓòÒôÔõÕöÖuUúÚùÙûÛüÜbBcCçÇdDfFgGhHjJkKlLmMnNpPqQrRsStTvVwWxXyYzZ0123456789+-=/*%\#§@({[]})|_"'!?,.:;ªº°¹²³£¢¬¨<>&$~--heart----dots--]]


    Font.fonts[1] = Generator:new({
        name = "komika text",
        font_size = 12,
        tab_size = 4,
        glyphs = glyphs
    })

    -- Font.fonts[2] = Generator:new({
    --     name = "book antiqua",
    --     font_size = 12,
    --     tab_size = 4,
    --     glyphs = glyphs
    -- })

    -- Font.fonts[3] = Generator:new({
    --     name = "tribal",
    --     font_size = 32,
    --     tab_size = 4,
    --     glyphs = "aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVxXyYzZ0123456789"
    -- })

    Font.fonts[2] = Generator:new_by_ttf({
        name = "cyrodiil",
        font_size = 12,
        tab_size = 4
    })

    -- Font.fonts[3] = Generator:new({
    --     name = "consolas",
    --     font_size = 10,
    --     tab_size = 4,
    --     glyphs = glyphs,
    --     glyphs_bold = glyphs_bold,
    --     glyphs_italic = glyphs_italic
    -- })

    Font.name2font = {}
    for _, font in pairs(Font.fonts) do
        Font.name2font[font.name] = font
    end
end

---@type JM.Font.Font
Font.current = Font.fonts[2]
Font.current:set_format_mode(Font.current.format_options.normal)


function Font:update(dt)
    for i = 1, #self.fonts do
        ---@type JM.Font.Font
        local font = self.fonts[i]
        font:update(dt)
    end
end

function Font:set_font(name)
    self.current = self.name2font[name] or self.name2font["komika text"]
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

function Font:get_phrase(text, x, y, align, right)
    return Font.current:generate_phrase(text, x or 0, y or 0, right, align)
end

return Font

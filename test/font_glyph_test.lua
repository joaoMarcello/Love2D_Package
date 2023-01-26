local pack = require("/JM_love2d_package/init")
local Game = pack.Scene:new(32, 32, 1366 - 32, 768 - 32, 32 * 22, 32 * 16)
Game.camera:toggle_debug()
Game.camera:toggle_grid()
Game.camera:toggle_grid()
Game.camera:toggle_world_bounds()

local Font = pack.Font
local Glyph = require("/JM_love2d_package/modules/font/glyph")

local render
local glyph, width, height
local imgData, img
local info
local bx, by, bw, bh

---@type JM.Font.Glyph
local my_glyph

local count_glyphs

Game:implements({
    load = function()
        render = love.font.newRasterizer('/data/font/TRIBAL__.ttf', 256)

        glyph = render:getGlyphData("A")
        width, height = glyph:getDimensions()

        imgData = love.image.newImageData(width, height, "rgba8", glyph:getString():gsub("(.)(.)", "%1%1%1%2"))
        img = love.graphics.newImage(imgData)

        info = glyph:getString()
        bx, by, bw, bh = glyph:getBoundingBox()

        my_glyph = Glyph:new(img, { id = "A", x = 0, y = 0, w = width, h = height })
        -- width, height = img:getDimensions()

        count_glyphs = render:getGlyphCount()
    end,

    update = function(dt)

    end,

    draw = function()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, 32 * 3, 32 * 2)

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", 32 * 3, 32 * 2, width, height)
        Font:print("" .. width .. " - " .. height, 32 * 6, 32 * 2)
        Font:print("quant. " .. count_glyphs, 32 * 6, 32 * 3)

        my_glyph:draw(32 * 15, 32 * 7)
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle("line", my_glyph.x, my_glyph.y, my_glyph.w, my_glyph.h)
    end

})

return Game

local pack = require("/JM_love2d_package/init")
local Game = pack.Scene:new(32, 32, 1366 - 32, 768 - 32, 32 * 22, 32 * 12)
Game.camera:toggle_debug()
Game.camera:toggle_grid()
Game.camera:toggle_grid()
Game.camera:toggle_world_bounds()

local Font = pack.Font
local Glyph = require("/JM_love2d_package/modules/font/glyph")

local render

---@type love.GlyphData
local glyph

local width, height
local imgData, img
local info
local bx, by, bw, bh

---@type JM.Font.Glyph
local my_glyph

local count_glyphs

---@type love.ImageData
local bigImgData

Game:implements({
    load = function()
        render = love.font.newRasterizer('/data/font/Garamond Premier Pro_italic.otf', 64)

        glyph = render:getGlyphData("j")
        width, height = glyph:getDimensions()

        imgData = love.image.newImageData(width, height, "rgba8", glyph:getString():gsub("(.)(.)", "%1%1%1%2"))
        img = love.graphics.newImage(imgData)
        img:setFilter("linear", "nearest")

        info = glyph:getString()
        bx, by, bw, bh = glyph:getBoundingBox()

        count_glyphs = render:getGlyphCount()

        bigImgData = love.image.newImageData(229 * width * 1.2, height + 20, "rgba8")
        local ww, hh = bigImgData:getDimensions()

        my_glyph = Glyph:new(img, { id = "A", x = 0, y = 0, w = width, h = height, right = width + bx })
        my_glyph:apply_effect("stretchVertical")
        -- pack.FontGenerator:new_by_ttf()
    end,

    update = function(dt)
        my_glyph:update(dt)
    end,

    keypressed = function(key)
        if key == "t" then Game.camera:toggle_grid() end
    end,

    draw = function()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, 32 * 3, 32 * 2)

        local w, h = bigImgData:getDimensions()

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", 32 * 3, 32 * 2, width, height)
        Font:print("" .. width .. " -_" .. height, 32 * 6, 32 * 2)
        Font:print("quant. " .. count_glyphs, 32 * 6, 32 * 3)
        Font:print("Size. " .. w, 32 * 6, 32 * 4)

        my_glyph:set_scale(1.3)
        my_glyph:draw(32 * 16, 32 * 4)


        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle("line", my_glyph.x, my_glyph.y, (my_glyph.w - bx * 2) * my_glyph.sx,
            my_glyph.h * my_glyph.sy)
        love.graphics.rectangle("line", 32 * 3, 32 * 2, bw, bh)

        local b1, b2 = glyph:getBearing()
        Font:print("bear não " .. b1 .. "  " .. b2, 32 * 1, 32 * 7)
        Font:print("bbox: " .. bx .. "  " .. by, 32 * 1, 32 * 7 + 22)
        Font:printx("Size. <italic>AVoAoaJé</italic> não à bboax\npP <color><effect=wave><effect=ghost>1+3=(7)</effect></color> 'astha' "
            ..
            bw .. "  " .. bh,
            32 * 1, 32 * 9
            , "left", math.huge
        )
        love.graphics.print("\65", 32 * 10, 32 * 1)
    end

})

return Game

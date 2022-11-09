local Anima = require "/JM_love2d_package/animation_module"
local EffectGenerator = require("/JM_love2d_package/effect_generator_module")
local FontGenerator = require("/JM_love2d_package/modules/jm_font")
local Phrase = require("/JM_love2d_package/modules/font/Phrase")
local Word = require("/JM_love2d_package/modules/font/Word")

local current_test = require("/test/first_test")
local r

local canvas

SCREEN_WIDTH = 320 * 2
SCREEN_HEIGHT = 160 * 2

local function get_scaled_canvas()
    local canvas = love.graphics.newCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
    love.graphics.setCanvas(canvas)

    love.graphics.setCanvas()
    return canvas
end

function love.load()
    love.graphics.setDefaultFilter("linear", "nearest")
    love.graphics.setBackgroundColor(130 / 255., 221 / 255., 255 / 255.)
    -- love.graphics.setBackgroundColor(20 / 255., 52 / 255., 100 / 255.)
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1, 1)

    r = current_test.load and current_test:load()

    canvas = love.graphics.newCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
end

function love.update(dt)
    if love.keyboard.isDown("q") or love.keyboard.isDown("escape") then
        love.event.quit()
    end

    r = current_test.update and current_test:update(dt)
end

function love.keyreleased(key)
    r = current_test.keyreleased and current_test:keyreleased(key)
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha")

    r = current_test.draw and current_test:draw()

    love.graphics.setCanvas()
    local scale = love.graphics.getWidth() / (SCREEN_WIDTH)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(canvas, 0,
        love.graphics.getHeight() / 2 - SCREEN_HEIGHT * scale / 2,
        0,
        scale, scale)
end

local utf8 = require("utf8")
local current_test = require("/test/first_test")
local r

local canvas

-- SCREEN_WIDTH = 320 * 2
-- SCREEN_HEIGHT = 160 * 2
SCREEN_WIDTH = 1366 / 2
SCREEN_HEIGHT = 768 / 2

SCREEN_WIDTH = 1980 / 3
SCREEN_HEIGHT = 1080 / 3

function love.load()
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setBackgroundColor(0, 0, 0, 1)

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
    love.graphics.setBlendMode("alpha")

    r = current_test.draw and current_test:draw()

    love.graphics.setCanvas()


    local scale = love.graphics.getWidth() / (SCREEN_WIDTH)
    local pos_y = love.graphics.getHeight() / 2 - SCREEN_HEIGHT * scale / 2
    local pos_x = love.graphics.getWidth() / 2 - SCREEN_WIDTH * scale / 2

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(canvas,
        math.floor(pos_x),
        math.floor(pos_y),
        0,
        scale, scale)
end

local love = _G.love
local utf8 = require('utf8')

math.randomseed(os.time())
love.graphics.setBackgroundColor(0, 0, 0, 1)

-- local scene = require("/test/game_test")
-- local scene = require("/test/test_tile")
local scene = require("/test/font_glyph_test")
-- local scene = require("/test/font_new")
-- local scene = require("/test/test_gui")

local t = 0.0

function love.load()
    scene:load()
end

function love.keypressed(key)
    scene:keypressed(key)

    if key == "5" then
        collectgarbage()
    end
end

function love.keyreleased(key)
    scene:keyreleased(key)
end

function love.mousepressed(x, y, button, istouch, presses)
    scene:mousepressed(x, y, button, istouch, presses)
    --scene:mousepressed()
end

function love.mousereleased(x, y, button, istouch, presses)
    scene:mousereleased(x, y, button, istouch, presses)
end

local km = nil

function love.update(dt)
    km = collectgarbage("count") / 1024.0

    if love.keyboard.isDown("q") or love.keyboard.isDown("escape") then
        collectgarbage("collect")
        love.event.quit()
    end

    scene:update(dt)

    -- t = t + dt
    -- if t >= 5.0 then
    --     t = 0.0
    --     collectgarbage()
    -- end
end

function love.draw()
    scene:draw()

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 80, 120)
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print(string.format("Memory:\n\t%.2f Mb", km), 5, 10)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 5, 50)
    local maj, min, rev, code = love.getVersion()
    love.graphics.print(string.format("Version:\n\t%d.%d.%d", maj, min, rev), 5, 75)
    -- love.graphics.print("\n" .. code, 10, 90)
end

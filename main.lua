local love = _G.love

math.randomseed(os.time())
love.graphics.setBackgroundColor(0, 0, 0, 1)

local scene = require("/test/test_gui")

local t = 0.0

function love.load()
    scene:load()
end

function love.keypressed(key)
    scene:keypressed(key)
end

function love.keyreleased(key)
    scene:keyreleased(key)
end

function love.mousepressed(x, y, button, istouch, presses)
    scene:mousepressed(x, y, button, istouch, presses)
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

    t = t + dt
    if t >= 15.0 then
        t = 0.0
        collectgarbage()
    end
end

function love.draw()
    scene:draw()

    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print(string.format("Memory:\n\t%.2f Mb", km), 10, 10)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 50)
    love.graphics.print("Version: " .. love.getVersion(), 10, 70)
end

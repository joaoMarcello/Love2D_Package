math.randomseed(os.time())
love.graphics.setBackgroundColor(0, 0, 0, 1)

local a = {}
local tab = {}
tab[a] = 5

local scene = require("/test/game_test")

local t = 0

function love.load()
    scene:load()
end

function love.keypressed(key)
    scene:keypressed(key)
end

function love.keyreleased(key)
    scene:keyreleased(key)
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
    if t >= 10.0 then
        t = t - 10.0
        -- collectgarbage()
    end
end

function love.draw()
    scene:draw()

    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print(string.format("Memory:\n\t%.2f Mb", km), 10, 10)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 50)

    love.graphics.print(tostring(tab[{}]), 200, 10)
end

math.randomseed(os.time())

local scene = require("/test/game_test")

local t = 0

function love.load()
    local r
    love.graphics.setBackgroundColor(0, 0, 0, 1)
    r = scene.load and scene:load()
    r = nil
end

function love.keypressed(key)
    local r
    r = scene.keypressed and scene:keypressed(key)
    r = nil
end

function love.keyreleased(key)
    local r
    r = scene.keyreleased and scene:keyreleased(key)
    r = nil
end

local km = collectgarbage("count")
function love.update(dt)
    local r
    km = collectgarbage("count")

    if love.keyboard.isDown("q") or love.keyboard.isDown("escape") then
        love.event.quit()
    end

    r = scene.update and scene:update(dt)
    r = nil

    t = t + dt
    if t >= 2 then
        t = t - 2
        collectgarbage()
    end
end

function love.draw()


    local r
    r = scene.draw and scene:draw()
    r = nil

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(km, 100, 300)
end

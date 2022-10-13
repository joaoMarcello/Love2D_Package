local Anima = require "animaCell"

Test_anima = Anima:new({
    img = "/data/goomba.png",
    frames = 9,
    speed = 0.3,
    -- grid = { x = 4, y = 2 },
    scale = { x = 2, y = 2 },
    bottom = 90,
    flip_x = false,
    flip_y = false,
    is_reversed = false,
    frame_size = { x = 122, y = 104 }
})

-- Test_anima.__effect_manager:apply_effect("flash")

Test_anima2 = Anima:new({
    img = "/data/goomba.png",
    frames = 9,
    speed = 0.2,
    -- grid = { x = 4, y = 2 },
    scale = { x = 1, y = 1 },
    bottom = 90,
    flip_x = false,
    flip_y = false,
    frame_size = { x = 122, y = 104 }
})

function love.load()
    love.graphics.setBackgroundColor(130 / 255., 221 / 255., 255 / 255.)
end

function love.update(dt)
    Test_anima:update(dt)
    Test_anima2:update(dt)
end

function love.draw()
    Test_anima:draw_rec(200, 300, 100, 100)
    Test_anima2:draw_rec(300, 100, 100, 100)
    love.graphics.print((Test_anima.__current_frame), 0, 0)
end

local Anima = require "animaCell"

Test_anima = Anima:new({
    img = "/data/goomba.png",
    frames = 9,
    speed = 0.15,
    -- grid = { x = 4, y = 2 },
    scale = { x = 2, y = 2 },
    bottom = 90,
    flip_x = false,
    flip_y = false,
    is_reversed = false,
    frame_size = { x = 122, y = 104 }
})

local my_effect = Test_anima:apply_effect("flick")
local flash_eff = Test_anima:apply_effect("flash")


Test_anima2 = Anima:new({
    img = "/data/goomba.png",
    frames = 9,
    speed = 0.09,
    -- grid = { x = 4, y = 2 },
    scale = { x = 1, y = 1 },
    bottom = 90,
    flip_x = false,
    flip_y = false,
    frame_size = { x = 122, y = 104 }
})

function love.load()
    love.graphics.setBackgroundColor(0, 0, 0, 1)
    love.graphics.setBackgroundColor(130 / 255., 221 / 255., 255 / 255.)
end

function love.update(dt)
    if Test_anima:time_updating() >= 1. then
        Test_anima:stop_effect(my_effect:get_unique_id())
    end

    if Test_anima:time_updating() >= 2 then
        Test_anima:zera_time_updating()
        my_effect:restaure(true)
    end

    if Test_anima:time_updating() >= 1. then
        Test_anima:stop_effect(flash_eff:get_unique_id())
    end

    Test_anima:update(dt)
    Test_anima2:update(dt)
end

function love.draw()
    Test_anima:draw_rec(200, 300, 100, 100)
    Test_anima2:draw_rec(300, 100, 100, 100)
    love.graphics.print(tostring(Test_anima.__current_frame), 0, 0)
end

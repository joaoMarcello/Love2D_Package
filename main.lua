function love.load()
    Anima = require "animaCell3"

    TestAnima = Anima:new({
        img = "/data/goomba.png",
        frames = 9,
        speed = 0.2,
        scale = { x = 2, y = 2 },
        state = "come and back",
        frame_size = { x = 122, y = 90 }
    })

    love.graphics.setBackgroundColor(130 / 255., 221 / 255., 255 / 255.)
end

function love.update(dt)
    TestAnima:update(dt)
end

function love.draw()
    TestAnima:draw_rec(200, 300, 100, 100)
    love.graphics.print(TestAnima.__current_frame, 0, 0)
end

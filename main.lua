local Anima = require "/JM_love2d_package/animation_module"
local EffectGenerator = require("/JM_love2d_package/effect_generator_module")

Test_anima = Anima:new({
    img = "/data/goomba.png",
    duration = 1,
    height = 100,
    flip_x = true,
    flip_y = false,
    is_reversed = false,
    state = "looping",
    frames_list = {
        { 27, 18, 58, 70 },
        { 151, 21, 58, 68 },
        { 272, 21, 59, 68 },
        { 392, 25, 68, 63 },
        { 517, 26, 61, 63 },
        { 638, 25, 57, 63 },
        { 765, 24, 56, 65 },
        { 889, 27, 55, 61 },
        { 1007, 26, 63, 62 }
    }
})

Anima2 = Test_anima:copy()
Anima2:set_size(100, 120)
Anima2:toggle_flip_x()
Anima2:set_duration(5)
Anima2:set_reverse_mode(true)
Anima2:stop_at_the_end(true,
    ---@param args JM.Anima
    function(args)
        args:unpause()
        args:apply_effect("flick", { duration = 0.5 })
    end, Anima2)
Anima2:reset()

local my_effect = EffectGenerator:generate("float")
my_effect:apply(Test_anima)

-- local flick = EffectManager:generate_effect("flash")
-- flick:force(Test_anima)

-- Test_anima:apply_effect("colorFlick")


-- ---@param args {anima: JM.Anima, eff: JM.Effect}
-- local action = function(args)
--     if args.anima:time_updating() >= 2 then
--         args.anima:stop_effect(args.eff:get_unique_id())
--     end

--     if args.anima:time_updating() >= 4 then
--         args.anima:zera_time_updating()
--         args.eff:apply(args.anima)
--         args.eff:restart(true)
--     end
-- end
-- Test_anima:set_custom_action(action, { anima = Test_anima, eff = my_effect })


function love.load()
    love.graphics.setBackgroundColor(130 / 255., 221 / 255., 255 / 255.)
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1, 1)
end

function love.update(dt)
    if Test_anima:time_updating() >= 1 then
        -- Test_anima:stop_effect(my_effect)
        -- Test_anima2:stop_effect(my_effect)
    end

    if Test_anima:time_updating() >= 4 then
        -- Test_anima:zera_time_updating()
        -- my_effect:force(Test_anima2)
    end

    if Test_anima:time_updating() >= 1. then
        -- Test_anima:stop_effect(flash_eff:get_unique_id())
    end

    Test_anima:update(dt)
    Anima2:update(dt)
end

function love.draw()
    love.graphics.push()

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("fill", 200, 300, 100, 100)
    Test_anima:draw_rec(200, 300, 100, 100)

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("fill", 300, 100, 100, 100)
    Anima2:draw_rec(300, 100, 100, 100)

    love.graphics.pop()
end

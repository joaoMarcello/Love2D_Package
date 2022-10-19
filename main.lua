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
-- Anima2:stop_at_the_end(true,
--     ---@param args JM.Anima
--     function(args)
--         args:unpause()
--         args:apply_effect("flick", { duration = 0.5 })
--     end, Anima2)
Anima2:set_state("back and forth")
Anima2:set_speed(0.1)
Anima2:reset()

local pulse_eff = EffectGenerator:generate("pulse", { max_sequence = 2, speed = 0.3, range = 0.1 })
local idle_effect = EffectGenerator:generate("idle", { duration = 1 })

local hh = EffectGenerator:generate("disc", { delay = 1, duration = 5})

-- hh:set_final_action(
-- ---@param args {anima: JM.Anima}
--     function(args)
--         local pop = args.anima:apply_effect("popin")
--         args.anima:apply_effect("clockWise", {speed=0.3, duration=pop.__speed})
--     end,
--     { anima = Test_anima })

hh:apply(Test_anima)
-- Test_anima:apply_effect("swing")
-- Test_anima:apply_effect("float")


function love.load()
    love.graphics.setBackgroundColor(130 / 255., 221 / 255., 255 / 255.)
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1, 1)
end

function love.update(dt)
    if Test_anima:time_updating() >= 4 then
        -- Test_anima:stop_effect(hh)
        -- Anima2:stop_effect(hh)
    end

    if Test_anima:time_updating() >= 7 then
        -- Test_anima:zera_time_updating()
        -- hh:apply(Anima2)
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

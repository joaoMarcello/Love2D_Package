local Anima = require "/JM_love2d_package/load_animation_module"
local EffectManager = require("/JM_love2d_package/modules/classes/EffectManager")

Test_anima = Anima:new({
    img = "/data/goomba.png",
    frames = 9,
    -- speed = 0.15,
    duration = 1,
    -- width = 100,
    height = 100,
    -- ref_width = 60, ref_height = 69,
    bottom = 89,
    flip_x = true,
    flip_y = false,
    is_reversed = false,
    state = "looping",
    frame_size = { x = 122, y = 104 },
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

local my_effect = EffectManager:generate_effect("pulse")
my_effect:force(Test_anima)

-- local flick = EffectManager:generate_effect("flash")
-- flick:force(Test_anima)

-- Test_anima:apply_effect("colorFlick")


-- ---@param args {anima: JM_Anima, eff: JM_Effect}
-- local action = function(args)
--     if args.anima:time_updating() >= 2 then
--         args.anima:stop_effect(args.eff:get_unique_id())
--     end

--     if args.anima:time_updating() >= 4 then
--         args.anima:zera_time_updating()
--         args.eff:force(args.anima)
--         args.eff:restart(true)
--     end
-- end
-- Test_anima:set_custom_action(action, { anima = Test_anima, eff = my_effect })


-- local flash_eff = Test_anima:apply_effect("pulse")


-- Test_anima2 = Anima:new({
--     img = "/data/goomba.png",
--     frames = 9,
--     speed = 0.09,
--     -- grid = { x = 4, y = 2 },
--     scale = { x = 1, y = 1 },
--     bottom = 90,
--     flip_x = false,
--     flip_y = false,
--     frame_size = { x = 122, y = 104 }
-- })

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
    -- Test_anima2:update(dt)
end

function love.draw()
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("fill", 200, 300, 100, 100)
    Test_anima:draw_rec(200, 300, 100, 100)
    -- Test_anima2:draw_rec(300, 100, 100, 100)
end

local Anima = require "/JM_love2d_package/animation_module"
local EffectGenerator = require("/JM_love2d_package/effect_generator_module")
local FontGenerator = require("/JM_love2d_package/modules/jm_font")
local Phrase = require("/JM_love2d_package/modules/font/Phrase")
local Word = require("/JM_love2d_package/modules/font/Word")

Test_anima = Anima:new({
    img = "/data/goomba.png",
    duration = 1,
    height = 100,
    flip_x = true,
    flip_y = false,
    is_reversed = false,
    state = "looping",
    -- color = { 0, 0, 1, 1 },
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
Anima2:set_state("back and forth")
Anima2:set_speed(0.1)
Anima2:reset()

local pulse_eff = EffectGenerator:generate("pulse", { max_sequence = 2, speed = 0.3, range = 0.1 })
local idle_effect = EffectGenerator:generate("idle", { duration = 1 })

local hh = EffectGenerator:generate("swing", { delay = 1 })

Test_anima:apply_effect("flash")
Test_anima:apply_effect("jelly")


local Calibri = FontGenerator:new({
    name = "calibri",
    font_size = 14,
    tab_size = 4
})

local Consolas = FontGenerator:new({
    name = "consolas",
    font_size = 18,
    tab_size = 4
})

Calibri:add_nickname_animated("--goomba--", {
    img = Test_anima.__img,
    frames_list = { { 27, 18, 58, 70 },
        { 151, 21, 58, 68 },
        { 272, 21, 59, 68 },
        { 392, 25, 68, 63 },
        { 517, 26, 61, 63 },
        { 638, 25, 57, 63 },
        { 765, 24, 56, 65 },
        { 889, 27, 55, 61 },
        { 1007, 26, 63, 62 }
    },
    duration = 1,
    state = "back and forth"
})

Calibri:add_nickname_animated("--jean--", {
    img = Test_anima.__img,
    frames_list = { { 27, 18, 58, 70 },
        { 151, 21, 58, 68 },
        { 272, 21, 59, 68 },
        { 392, 25, 68, 63 },
        { 517, 26, 61, 63 },
        { 638, 25, 57, 63 },
        { 765, 24, 56, 65 },
        { 889, 27, 55, 61 },
        { 1007, 26, 63, 62 }
    },
    duration = 0.7,
    flip_y = true
})

Calibri:add_nickname_animated("--hh--", {
    img = Test_anima.__img,
    frames_list = { { 31, 40, 47, 25 },

    },
})

local button = Calibri:add_nickname_animated("--a--", {
    img = "/data/xbox.png",
    frames_list = {
        { 407, 831, 116, 117 },
        { 400, 1016, 117, 116 },
        { 407, 831, 116, 117 }
    },
    duration = 1
})

local aa = Calibri:add_nickname_animated("--nuvem--", {
    img = "/data/cloud.png"
})
-- aa:apply_effect("pulse", { range = 0.06 })

local text = " Em meio às sinuosas --hh-- e a confusas correntezas inimigas, o bom shinobi não precisa se ocultar. Para todos os inimigos, fadiga, descuido e cansaço o tempo trará--goomba--.\nPress --a-- to jump\t.\n\n\tÉ sábio o a shinobi. que tem o tempo como amigo e sabe esperar. Logo, vamos todos tentar ser um bom shinobi --nuvem--.\n\n\t({[Sasuke Uchiha]})."

local text2 = "Thanos aAáÁàÀãÃäÄ eEéÉèÈêÊëË iIíÍìÌîÎïÏ oOóÓòòôÔöÖõÕ uUúÚùÙûüÜ bBcCçÇdDfF gGhHjJkKlLmM nNpPqQrRsS {[(astha)]} |as_ \ntTvVwWxXyYzZ 0123456789 +-=/#@§ ?|!,.;: °º1ª¹²³£¢¬AsthaYuno"
    .. [["]]
local frase = Phrase:new({ text = text2, font = Consolas })

frase:color_pattern("jump", { 0.8, 0, 0, 1 }, 1)
frase:apply_freaky("shinobi", "all")
frase:color_sentence("bom shinobi", { 1, 0, 0, 1 }, "all")

frase:color_sentence("o tempo como amigo", { 0, 0, 1, 1 }, "all")

local current_max = 1
local time = 0
local speed = 0.05


local last_char
local adicional = 0

function love.load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1, 1)
    love.graphics.setBackgroundColor(130 / 255., 221 / 255., 255 / 255.)
end

function love.update(dt)
    time = time + dt
    if time >= speed + adicional then
        time = time - speed - adicional
        current_max = current_max + 1
    end

    if love.keyboard.isDown("q") or love.keyboard.isDown("escape") then
        love.event.quit()
    end

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

    Calibri:update(dt)
    frase:update(dt)
end

function love.draw()

    love.graphics.push()

    love.graphics.setColor(1, 1, 1, 0.8)
    local w = 230
    local h = 500
    -- love.graphics.rectangle("fill", 50, 110, w, h)

    -- Test_anima:draw_rec(200, 300, 100, 100)

    -- love.graphics.setColor(1, 1, 1, 0.8)
    -- love.graphics.rectangle("fill", 300, 100, 100, 100)
    -- Anima2:draw_rec(300, 100, 100, 100)

    love.graphics.pop()

    -- Calibri:print("mas que solidao\n <color, 1, 0, 0>ninguem --nuvem-- aqui--</color>ao lado\n\tachei a solucao\n \tnao sou\n <bold>mais</bold> maltratado --goomba-- --jean-- --goomba-- be gone!\t \tArroz"
    --     , 50, 110, w)

    Calibri:push()
    -- Calibri:set_font_size(14)
    Calibri:print("\t<color, 0,0,1>Hello </color>World", 0, 0)
    Calibri:pop()


    Calibri:push()
    Calibri:set_font_size(18)
    -- Calibri:set_tab_size(6)
    last_char = frase:draw(20, 50, "justified", nil)
    Calibri:pop()

    if last_char then
        if last_char.char.__id == "." or last_char.char.__id == "\n" then
            adicional = 0.8
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("fill", last_char.x + 6, last_char.y, 2, 18)
        elseif last_char.char.__id == "," then
            adicional = 0.2
        else
            adicional = 0
        end

    end
end

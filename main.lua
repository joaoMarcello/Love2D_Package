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

local Consolas = FontGenerator:new({
    name = "consolas",
    font_size = 18,
    tab_size = 4,
})

Consolas:add_nickname_animated("--goomba--", {
    img = Test_anima.__img,
    frames_list = { { 27, 85, 17, 89 },
        { 150, 209, 17, 89 },
        { 271, 331, 17, 89 },
        { 391, 460, 17, 88 },
        { 516, 579, 17, 89 },
        { 637, 695, 17, 88 },
        { 764, 821, 17, 89 },
        { 888, 944, 17, 88 },
        { 1006, 1070, 17, 88 }
    },
    duration = 1,
    state = "looping"
})

Consolas:add_nickname_animated("--jean--", {
    img = Test_anima.__img,
    frames_list = { { 27, 85, 17, 89 },
        { 150, 209, 20, 89 },
        { 271, 331, 20, 89 },
        { 391, 460, 24, 88 },
        { 516, 579, 25, 89 },
        { 637, 695, 24, 88 },
        { 764, 821, 23, 89 },
        { 888, 944, 26, 88 },
        { 1006, 1070, 25, 88 }
    },
    duration = 0.7,
    flip_y = true
})

Consolas:add_nickname_animated("--hh--", {
    img = Test_anima.__img,
    frames_list = { { 1010, 1037, 37, 56 },

    },
})

local button = Consolas:add_nickname_animated("--a--", {
    img = "/data/xbox.png",
    frames_list = {
        { 407, 525, 831, 948 },
        { 407, 525, 831, 948 },
        { 401, 517, 1016, 1133 }
    },
    duration = 1
})

local aa = Consolas:add_nickname_animated("--nuvem--", {
    img = "/data/cloud.png"
})
-- aa:apply_effect("pulse", { range = 0.06 })

local text = "Caro senhor <italic>Potter,</italic> \n \n \tChegou ao conhecimento do Ministério que o senhor executou o < color, 0, 0, 1 >feitiço do patrono <color>na <bold>presença de um trouxa.< /color >< /bold >\n \tSendo uma grave violação ao <bold>'Regulamento de <color, 1,0,1>Restrição à Prática de Magia <color, 0.7, 0.1, 0.6>por Menores',</bold> o senhor</color> está expulso da <bold>Escola de Magia e Bruxaria de Hogwarts.\n \n </bold>\t\t\tEsperando que esteja bem,\n \t\t\t\t\tMafalda Hopkins --goomba--</bold> "

local text2 = "<color>Thanos</color> aAáÁàÀãÃäÄ eEéÉèÈêÊëË iIíÍìÌîÎïÏ oOóÓòòôÔöÖõÕ uUúÚùÙûüÜ bBcCçÇdDfF gGhHjJkKlLmM nNpPqQrRsS {[(astha)]} |as_ \n tTvVwWxXyYzZ 0123456789 +-=/# @TMJ_por_JM & § ?|!,.;: °º1ª¹²³£¢¬AsthaYuno * ¨¬¬ ~ $ ~ --a--"
    .. [["]]

Consolas:push()
-- Consolas:set_format_mode(Consolas.format_options.italic)
local frase = Phrase:new({ text = text, font = Consolas })
Consolas:pop()

-- frase:color_pattern("s", { 0.8, 0, 0, 1 }, "all")
frase:color_sentence("e", { 1, 0, 0, 1 }, "all")
frase:apply_freaky("feitiço do patrono", "all")

-- frase:color_sentence("o tempo como amigo", { 0, 0, 1, 1 }, "all")

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

    frase:update(dt)
    Consolas:update(dt)
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



    -- Consolas:print("Caro senhor Potter, \n\n \tChegou ao conhecimento do Ministério que o senhor executou o < color, 0, 0, 1 >feitiço do patrono <color>na <bold>presença de um trouxa< /color >< /bold >.\n\tSendo uma grave violação ao <bold>'Regulamento de <color, 1,0,1>Restrição à Prática de Magia <color, 0.7, 1, 0.6?>por Menores'</bold>, o senhor</color> está expulso da <bold>Escola de Magia e Bruxaria de Hogwarts.</bold>\n\n \t\t\tEsperando que esteja bem,\n\t\t\t\t\tMafalda Hopkins --goomba--</bold> "
    --     ,
    --     0, 0, love.graphics.getWidth() - 300)
    Consolas:push()
    Consolas:set_font_size(16)
    -- Consolas:set_format_mode(Consolas.format_options.italic)
    -- Consolas:set_color({ 1, 1, 1, 1 })
    Consolas:printf("\tAquele que\n h--a-- habita no <italic>esconderijo</italic> do altíssimo, <color>à <color, 0, 0, 1>sombra do <color, 0.7, 0.5, 0.1>onipotente</color> --goomba-- descansará \n \n \tDiz ao Senhor, meu refúgio e meu baluarte. Deus meu em quem confio. \n \n \tPois ele te livrará do <color, 0,0,1>laço do <color, 1, 0, 0>passarinheiro</color> e da peste perniciosa. Cobrir-te-á com suas penas e sob suas asas estarás seguro. Tua verdade é <bold>pavê e escudo.</bold>"
        , 30, -0, "justify")
    Consolas:pop()

    Consolas:push()
    Consolas:set_font_size(14)
    frase:refresh()
    last_char = frase:draw(love.mouse.getX() + 20, 20, "justified", nil)
    Consolas:pop()

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

local Anima = require "/JM_love2d_package/animation_module"
local EffectGenerator = require("/JM_love2d_package/effect_generator_module")
local FontGenerator = require("/JM_love2d_package/modules/jm_font")
local Phrase = require("/JM_love2d_package/modules/font/Phrase")
local Word = require("/JM_love2d_package/modules/font/Word")

local Consolas = FontGenerator:new({
    name = "consolas",
    font_size = 18,
    tab_size = 4,
})

Consolas:add_nickname_animated("--goomba--", {
    img = "/data/goomba.png",
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
    is_reversed = false,
    state = "looping"
})

Consolas:add_nickname_animated("--jean--", {
    img = "/data/goomba.png",
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
    flip_y = true,
})

Consolas:add_nickname_animated("--hh--", {
    img = "/data/goomba.png",
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

local text = "<color, 0.2, 0.2, 0.2> Caro senhor --a--rroz<italic>Potter,</italic> \n \n \tChegou ao conhecimento do Ministério que o senhor executou o <italic>feitiço do patrono</italic> na presença de um trouxa.\n \tSendo uma grave violação ao <italic>'Regulamento de Restrição à Prática de Magia por Menores',</italic> o senhor está expulso da <bold>Escola de Magia e Bruxaria de Hogwarts.\n \n \n </bold>\t\t\tEsperando que esteja bem,\n \t\t\t\t\t<italic>Mafalda Hopkins --goomba--</bold> "

local text2 = "<color>Thanos</color> aAáÁàÀãÃäÄ eEéÉèÈêÊëË iIíÍìÌîÎïÏ oOóÓòòôÔöÖõÕ uUúÚùÙûüÜ bBcCçÇdDfF gGhHjJkKlLmM nNpPqQrRsS {[(astha)]} |as_ \n tTvVwWxXyYzZ 0123456789 +-=/# @TMJ_por_JM & § ?|!,.;: °º1ª¹²³£¢¬AsthaYuno * ¨¬¬ ~ $ ~ --a--"
    .. [["]]

Consolas:push()
-- Consolas:set_format_mode(Consolas.format_options.italic)
local frase = Phrase:new({ text = text, font = Consolas })
Consolas:pop()

-- frase:color_pattern("s", { 0.8, 0, 0, 1 }, "all")
frase:color_sentence("feitiço do patrono", { 0, 0, 1, 1 }, "all")
frase:apply_freaky("feitiço do patrono", "all")

-- frase:color_sentence("o tempo como amigo", { 0, 0, 1, 1 }, "all")

local current_max = 1
local time = 0
local speed = 0.05


local last_char
local adicional = 0
--=============================================================================
local t = {}

function t:update(dt)
    time = time + dt
    if time >= speed + adicional then
        time = time - speed - adicional
        current_max = current_max + 1
    end

    frase:update(dt)
    Consolas:update(dt)
end

function t:draw()
    Consolas:push()
    Consolas:set_font_size(12)
    -- Consolas:set_format_mode(Consolas.format_options.italic)
    -- Consolas:set_color({ 1, 1, 1, 1 })
    Consolas:printf("\tAquele que\n h--a-- habita no <italic>esconderijo</italic> do altíssimo, <color>à <color, 0, 0, 1>sombra do <color, 0.7, 0.5, 0.1>onipotente</color> --goomba-- descansará\n \n \tDiz ao Senhor, meu refúgio e meu baluarte. Deus meu em quem confio.\n \n \tPois ele te livrará do <color, 0,0,1>laço do <color, 1, 0, 0>passarinheiro</color> e da peste perniciosa. Cobrir-te-á com suas penas e sob suas asas estarás seguro. Tua verdade é <bold>pavê e escudo.</bold>"
        , 30, -0, "justify")
    Consolas:pop()

    Consolas:push()
    Consolas:set_font_size(12)
    last_char = frase:draw(love.mouse.getX() + 20, 20, "justified", nil)
    Consolas:pop()

    if last_char then
        if last_char.char.__id == "." or last_char.char.__id == "\n" then
            adicional = 0.8
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("fill", last_char.x + 6, last_char.y - last_char.char.h / 2, 2, 18)
        elseif last_char.char.__id == "," then
            adicional = 0.2
        else
            adicional = 0
        end

    end
end

return t

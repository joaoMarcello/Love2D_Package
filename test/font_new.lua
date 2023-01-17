local package = require("/JM_love2d_package/init")
local Font = package.Font
local Game = package.Scene:new(0, 0, 1366, 768, 32 * 24, 32 * 14,
    {
        left = -32 * 10,
        top = -32 * 10,
        right = 32 * 200,
        bottom = 32 * 200
    }
)
Game.camera:toggle_debug()

local button = Font.current:add_nickname_animated("--a--", {
    img = "/data/xbox.png",
    frames_list = {
        { 407, 525, 831, 948 },
        { 407, 525, 831, 948 },
        { 401, 517, 1016, 1133 }
    },
    duration = 1
})

local rad = 0
local function update(dt)
    Font:update(dt)

    -- Game.camera:update(dt)
    local mx, my = Game:get_mouse_position()
    -- Game.camera:follow(mx, my)
    --rad = rad + math.pi * 2 / 0.7 * dt
end

local text = "Hello <freaky>aqui quem fala \teh o seu<italic>capitão</italic>.astha nao sei mais oque escrever paraastasatsagstasga este texto ficar longo então vou ficar enrolando <bold>World <italic><color, 0, 0, 1, 1>Iupi <bold> World</color>test <color>Wo"

local text2 = "<color, 0, 0, 1>Thanos</color> aAáÁàÀãÃäÄ eEéÉèÈêÊëË iIíÍìÌîÎïÏ\n\toOóÓòòôÔ\n\töÖõÕ uUúÚùÙûüÜ bBcCçÇdDfF gGhHjJkKlLm M nNpPqQrRsS {[(astha)]} |as_ \n<effect=spooky>tTvVwW xXyYzZ</effect> 0123456789 +-=/# @TMJ_por_JM & § ?|!,.;: °º1ª¹²³£¢¬ AsthaYuno * ¨¬¬ ~ $ ~ --heart-- --dots-- \n</italic><effect=wave>Press --a-- to <bold><color>charge</effect> your laser</color> .  alfa"

-- local text3 = "aAàÀ <italic>çÇé fada <bold>dDeEfFgGhHiIjJkKlL</bold> mNoOpPqQrRsStT\n\t<freaky>uUvVwWxXyYzZ</freaky> <italic>0123456789</italic> +-=/*#§@ (){}[]\n|_'!?\n,.:;ªº°\n¹²³£¢\n <> ¨¬~$&\nEste é o mundo de Greg Uooôô ôô"
--     .. [["/]]

local text4 = "< effect =ghost, delay =0 , speed=1, min=0.2, max=1 >oi eu sou o goku"

local function draw(camera)
    local a = 0.7 + 0.4 * math.sin(rad)
    -- a = a % 1.1
    Font:printx(text2
        ,
        32 * 3,
        32 * 2
        , "left",
        32 * 3 + 32 * 6
    -- Game:get_mouse_position()
    )

    Font.current:push()
    Font.current:set_font_size(22)
    Font:printx(text4, 32 * 13, 32 * 3, "left", 32 * 13 + 32 * 6)
    Font.current:pop()

    local mx, my = Game:get_mouse_position()
    love.graphics.setColor(0, 0, 1, 1)
    love.graphics.circle('fill', mx, my, 5)
end

Game:implements({
    update = update,

    keypressed = function(key)
        if key == "g" then
            Game.camera:toggle_grid()
            Game.camera:toggle_world_bounds()
        end

        if key == "d" then
            Game.camera:toggle_debug()
        end
    end,

    layers = {
        {
            draw = draw
        }
    }
    --draw = draw
})

return Game

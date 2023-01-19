local package = require("/JM_love2d_package/init")
local Font = package.Font
local TextBox = require("/JM_love2d_package/modules/gui/textBox")
local Game = package.Scene:new(0, 0, 1366, 768, 32 * 24, 32 * 14,
    {
        left = -32 * 10,
        top = -32 * 10,
        right = 32 * 200,
        bottom = 32 * 200
    }
)
Game.camera:toggle_debug()
Game.camera:toggle_grid()

local button = Font.current:add_nickname_animated("--a--", {
    img = "/data/xbox.png",
    frames_list = {
        { 407, 525, 831, 948 },
        { 407, 525, 831, 948 },
        { 401, 517, 1016, 1133 }
    },
    duration = 1
})

local text = "Hello <freaky>aqui quem fala \teh o seu<italic>capitão</italic>.astha nao sei mais oque escrever paraastasatsagstasga este texto ficar longo então vou ficar enrolando <bold>World <italic><color, 0, 0, 1, 1>Iupi <bold> World</color>test <color>Wo"

local text2 = "<color, 1, 1, 1>Thanos.</color> eu nem gosto, ouviu? sas vefe sajs <italic>asasahs</italic> wtwrfaghsas\n   asd asss df \n\tiIíÍìÌîÎïÏ \n\toOóÓòòôÔ öÖõÕ uUúÚùÙûüÜ <effect=flash, speed=1><color, 1, 1, 0>bBcCçÇdDfF</color></effect> gGhHjJkKlLm\n <effect=spooky>tTvVwW xXyYzZ</effect> 01234 56789¬ AsthaYuno * ¨¬¬ ~ $ ~ --heart-- --dots-- </italic><effect = wave>\nPress --a-- to <bold><color>charge your laser</color> .  alfa</bold>\n<effect=scream>\n \n \n \nPARA DE GRITAAAAAAAR!!!"

local rad = 0
Font.current:push()
Font.current:set_font_size(22)
local box = TextBox:new(text2, Font.current, 32 * 10, 32 * 5, 32 * 6)
Font.current:pop()

box:on_event("glyphChange", function()
    local g = box:get_current_glyph()
    if g then
        g:apply_effect("stretchVertical", { range = 0.1 })
    end
end)

local A = Font.current:__get_char_equals("A"):copy()
-- A.sx = 1
-- A.sy = 1
A.ox = 7
A.oy = 7
A:apply_effect("clockWise")

local button = package.GUI.Button:new({ text = "Button 1", x = 32 * 17, y = 32, w = 32 * 2, h = 32 })
button:apply_effect("swing")
local function update(dt)
    Font:update(dt)

    A:update(dt)

    button:update(dt)

    box:update(dt)
    -- Game.camera:update(dt)
    local mx, my = Game:get_mouse_position()
    -- Game.camera:follow(mx, my)
    --rad = rad + math.pi * 2 / 0.7 * dt
end

-- local text3 = "aAàÀ <italic>çÇé fada <bold>dDeEfFgGhHiIjJkKlL</bold> mNoOpPqQrRsStT\n\t<freaky>uUvVwWxXyYzZ</freaky> <italic>0123456789</italic> +-=/*#§@ (){}[]\n|_'!?\n,.:;ªº°\n¹²³£¢\n <> ¨¬~$&\nEste é o mundo de Greg Uooôô ôô"
--     .. [["/]]

-- local text4 = "< effect=flickering, speed = 1 >oi eu sou o goku"


local function draw(camera)
    local a = 0.7 + 0.4 * math.sin(rad)
    -- a = a % 1.1
    A:draw(32 * 15, 32 * 2)
    button:draw()
    Font:printx(text2
        ,
        32 * 3,
        32 * 2
        , "justify",
        32 * 3 + 32 * 6
    -- Game:get_mouse_position()
    )

    Font.current:push()
    Font.current:set_font_size(9)
    Font:printx("< effect=scream>PARA DE GRITAAAAAR!", 32 * 13, 32 * 3, "left", 32 * 13 + 32 * 3)
    Font.current:pop()

    box:draw()

    Font:print("Ai --dots-- --heart-- --dots--", 500, 100)
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

        box:key_pressed(key)
    end,

    layers = {
        {
            draw = draw
        }
    }
    --draw = draw
})

return Game

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

local text = "Hello <freaky>aqui quem fala \teh o seu <italic>capitão.</italic> nao sei mais oque escrever para este texto ficar longo então vou ficar enrolando <bold>World <italic><color, 1, 0, 0, %.1f>Iupi <bold> World</color> Wo"
local function draw(camera)
    local a = 0.7 + 0.4 * math.sin(rad)
    -- a = a % 1.1
    Font:printx(string.format(text, 1),
        32 * 3,
        32 * 4
        , "left",
        32 * 3 + 32 * 5--,Game:get_mouse_position()
    )

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

local package = require("/JM_love2d_package/init")
local Font = package.Font
local Game = package.Scene:new(0, 0, 1366, 768, 32 * 24, 32 * 14)

local rad = 0
local function update(dt)
    rad = rad + math.pi * 2 / 0.7 * dt
end

local function draw(camera)
    local a = 0.7 + 0.4 * math.sin(rad)
    -- a = a % 1.1
    Font:printx(string.format("Hello aqui quem fala \teh o seu <italic>capitão.</italic> nao sei mais oque escrever para este texto ficar longo então vou ficar enrolando <bold>World <italic><color, 1, 0, 0, %.1f>Iupi <bold> World</color> Wo"
        , a),
        32 * 1,
        32 * 4
        , "justified",
        Game:get_mouse_position()
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

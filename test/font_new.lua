local package = require("/JM_love2d_package/init")
local Font = package.Font
local Game = package.Scene:new(0, 0, 1366, 768, 32 * 24, 32 * 14)

local function update(dt)

end

local function draw(camera)
    Font:printf("Hello <bold>World <italic><color, 1, 0, 0, 1>Iupi",
        32 * 4,
        32 * 4
        , "left",
        32 * 4
    )
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

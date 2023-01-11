local package = require("/JM_love2d_package/init")
local Font = package.Font
local Game = package.Scene:new(0, 0, 1366, 768, 32 * 24, 32 * 14)

local function update(dt)

end

local function draw(camera)
    Font:printx("Hello <bold>World <italic><color, 1, 0, 0, 1>Iupi",
        32 * 5,
        32 * 4
        , "left",
        32 * 4
    )
end

Game:implements({
    update = update,
    draw = draw
})

return Game

local Anima = require("/JM_love2d_package/init").Anima

local Monica = {}

function Monica:load()
    local monica_idle_normal =
    Anima:new(
        {
            img = "data/Monica/monica_idle_normal-Sheet.png",
            frames = 6,
            duration = 0.5,
            height = 64,
            ref_height = 64,
            amount_cycle = 2
        }
    )

    local monica_run =
    Anima:new(
        {
            img = "/data/Monica/monica-run.png",
            frames = 8,
            duration = 0.6,
            height = 64,
            ref_height = 64
        }
    )

    local monica_idle_blink =
    Anima:new(
        {
            img = "data/Monica/monica_idle_blink-Sheet.png",
            frames = 6,
            duration = 0.5,
            height = 64 * 1,
            ref_height = 64,
            amount_cycle = 1
        }
    )
end

return Monica

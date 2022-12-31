local package = require("/JM_love2d_package/init")
local Scene = package.Scene
local Physics = package.Physics
local Font = package.Font
local GUI = package.GUI

local Game = Scene:new()

local button_1 = GUI.Button:new({
    x = 200, y = 100, w = 100, h = 100
})

button_1.__effect_manager:apply_effect(button_1, "pulse", { speed = 1 })
-- button_1.__effect_manager:apply_effect(button_1, "float")

local manager = GUI.Container:new({
    x = 128, y = 128,
    w = 64 * 10, h = 64 * 6,
    type = "grid",
    -- mode = "right"
})

manager:add(button_1)
manager:add(GUI.Button:new({ x = 175, y = 170, w = 100, h = 100 }))
manager:add(GUI.Button:new({ x = 200, y = 250, w = 100, h = 100 }))
manager:add(GUI.Button:new({ x = 240, y = 250, w = 100, h = 100 }))
-- manager:add(GUI.Button:new({ x = 240, y = 250, w = 100, h = 100 }))

Game:implements({
    draw = function()
        manager:draw()
    end,

    mousepressed = function(x, y)
        manager:mouse_pressed(x, y)
    end,

    mousereleased = function(x, y)
        manager:mouse_released(x, y)
    end,

    update = function(dt)
        manager:update(dt)
    end
})

return Game

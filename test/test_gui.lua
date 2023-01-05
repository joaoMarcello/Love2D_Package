local package = require("/JM_love2d_package/init")
local Scene = package.Scene
local Physics = package.Physics
local Font = package.Font
local GUI = package.GUI

-- local Game = Scene:new(64, 10, 1366 * 0.9, nil, 1366 * 0.5, 768 * 0.5)
local Game = Scene:new(32, 64, 1366 - 64, 768
-- , 32 * 10
-- , 32 * 10
)

local button_1 = GUI.Button:new({
    x = 200, y = 100, w = 150, h = 100
})
button_1.is_button1 = true

-- button_1.__effect_manager:apply_effect(button_1, "pulse", { speed = 1, range = 0.05 })

-- button_1:apply_effect("swing")

local manager = GUI.Container:new({
    x = 128, y = 128,
    w = 64 * 10, h = 64 * 4,
    type = "grid",
    grid_y = 2
    -- mode = "right"
})

manager:add(button_1)
manager:add(GUI.Button:new({ x = 175, y = 170, w = 100, h = 100 }))
manager:add(GUI.Button:new({ x = 200, y = 250, w = 100, h = 100 }))
manager:add(GUI.Button:new({ x = 240, y = 250, w = 100, h = 100 }))
-- manager:add(GUI.Button:new({ x = 240, y = 250, w = 100, h = 100 }))

Game:implements({
    draw = function(camera)
        manager:draw(camera)
        -- Font:printx("button", 200, 100, "center", 150)
    end,

    mousepressed = function(x, y)
        x, y = x - Game.x, y - Game.y
        manager:mouse_pressed(x, y)
    end,

    mousereleased = function(x, y)
        x, y = x - Game.x, y - Game.y
        manager:mouse_released(x, y)
    end,

    keypressed = function(key)
        manager:key_pressed(key)
    end,

    update = function(dt)
        local speed = 128 * love.timer.getDelta()

        if love.keyboard.isDown("down") then
            manager:set_position(nil, manager.y + 128 * love.timer.getDelta())
        elseif love.keyboard.isDown("up") then
            manager:set_position(nil, manager.y - 128 * love.timer.getDelta())
        end

        if love.keyboard.isDown("left") then
            manager:set_position(manager.x - 128 * love.timer.getDelta())
        elseif love.keyboard.isDown("right") then
            manager:set_position(manager.x + 128 * love.timer.getDelta())
        end

        if love.keyboard.isDown("w") then
            manager:shift_objects(nil, -speed)
        elseif love.keyboard.isDown("s") then
            manager:shift_objects(nil, speed)
        end
        if love.keyboard.isDown("a") then
            manager:shift_objects(-speed)
        elseif love.keyboard.isDown("d") then
            manager:shift_objects(speed)
        end

        manager:update(dt)
    end
})

return Game

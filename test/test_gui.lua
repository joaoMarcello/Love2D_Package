local package = require("/JM_love2d_package/init")
local Scene = package.Scene
local Physics = package.Physics
local Font = package.Font
local GUI = package.GUI

local Game = Scene:new(32, 32, 1366 - 32, 768 - 32, 32 * 20, 32 * 16)
-- local Game = Scene:new(64, 64, 1366, 768
--     , 32 * 23
--     , 32 * 20
-- )
-- Game.camera.x = 64

local world = Physics:newWorld()
local rects = {
    { 64 * 2, 64 * 4, 64, 128 }
}
for _, rec in ipairs(rects) do
    Physics:newBody(world, rec[1], rec[2], rec[3], rec[4], "static")
end

local button_1 = GUI.Button:new({
    x = 200, y = 100, w = 150, h = 100
})
button_1.is_button1 = true

-- button_1.__effect_manager:apply_effect(button_1, "pulse", { speed = 1, range = 0.05 })

-- button_1:apply_effect("swing")

local manager = GUI.Container:new({
    scene = Game,
    x = 0, y = 0,
    w = 64 * 10, h = 32 * 8,
    type = "grid",
    grid_y = 2
    -- mode = "right"
})

local function stencilFunction()
    love.graphics.rectangle("fill", 225, 200, 350, 300)
end

manager:add(button_1)
manager:add(GUI.Button:new({ x = 175, y = 170, w = 64, h = 64 }))
manager:add(GUI.Button:new({ x = 200, y = 250, w = 64, h = 64 }))
manager:add(GUI.Button:new({ x = 240, y = 250, w = 64, h = 64 }))
-- manager:add(GUI.Button:new({ x = 240, y = 250, w = 100, h = 100 }))

Game:implements({
    draw = function(camera)
        manager:draw(camera)
        -- Font:printx("button", 200, 100, "center", 150)

        world:draw()

        love.graphics.setColor(1, 0, 0, 0.2)
        local x, y = Game:get_mouse_position()
        -- love.graphics.rectangle("fill", x, y, 32, 32)

        local tile = 32
        local cx = tile * (math.floor(x / tile))
        local cy = tile * (math.floor(y / tile))
        love.graphics.rectangle("fill", cx, cy, tile, tile)

        Font:print("On Screen: <color, 1, 0, 0>" .. tostring(Game.camera:rect_is_on_view(x, y, tile, tile)), 10, 32 * 10)

        -- love.graphics.stencil(stencilFunction, "replace", 1)
        -- love.graphics.setStencilTest("greater", 0)
    end,

    mousepressed = function(x, y)
        manager:mouse_pressed(x, y)

        local mx, my = Game:get_mouse_position()
        local tile = 32
        local cx = tile * math.floor(mx / tile)
        local cy = tile * math.floor(my / tile)

        if Game.camera:rect_is_on_view(cx, cy, tile, tile) then
            Physics:newBody(world, cx, cy, tile, tile, "static")
        end
    end,

    mousereleased = function(x, y)
        manager:mouse_released(x, y)
    end,

    keypressed = function(key)
        manager:key_pressed(key)
    end,

    update = function(dt)
        world:update(dt)

        local speed = 128 * dt

        if love.keyboard.isDown("down") then
            manager:set_position(nil, manager.y + speed)
        elseif love.keyboard.isDown("up") then
            manager:set_position(nil, manager.y - speed)
        end

        if love.keyboard.isDown("left") then
            -- Game.camera:set_position(Game.camera.x - speed)
            manager:set_position(manager.x - speed)
        elseif love.keyboard.isDown("right") then
            -- Game.camera:set_position(Game.camera.x + speed)
            manager:set_position(manager.x + speed)
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

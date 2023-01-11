local package = require("/JM_love2d_package/init")
local Font = package.Font

local Tile = require("/JM_love2d_package/modules/tile/tile")
local TileSet = require("/JM_love2d_package/modules/tile/tile_set")
local TileMap = require("/JM_love2d_package/modules/tile/tile_map")

local Game = package.Scene:new(0, 0, 1366, 768, 32 * 24, 32 * 16)

do
    Game:add_camera({
        -- camera's viewport
        x = Game.screen_w * 0.5,
        y = Game.screen_h * 0,
        w = Game.screen_w * 0.5,
        h = Game.screen_h * 0.5,

        color = { 153 / 255, 217 / 255, 234 / 255, 1 },
        scale = 1.2,

        type = "metroid",
        show_grid = true,
        show_world_bounds = true
    }, "red")
    Game:get_camera("main"):set_viewport(nil, nil, Game.screen_w * 0.5, Game.screen_h)
    Game.camera.focus_x = Game.screen_w * 0.5
    Game:add_camera({
        -- camera's viewport
        x = Game.screen_w * 0.5,
        y = Game.screen_h * 0.5,
        w = Game.screen_w * 0.5,
        h = Game.screen_h * 0.5,

        border_color = { 0, 0, 1, 1 },
        scale = 0.5,

        type = "metroid",
        show_grid = true,
        grid_tile_size = 32 * 4,
        show_world_bounds = true
    }, "blue")
end


local tile_img = love.graphics.newImage("/data/tileset_01.png")

local t1 = Tile:new("1", tile_img, 32 * 1, 32 * 1, 32)

local set = TileSet:new("data/tileset_01.png", 32)

local map = TileMap:new("test/my_map_data.lua",
    "data/tileset_01.png", 32, nil, nil
-- function(x, y, id) return x < 1500 and y < 1500 end
)


Game:implements({
    update = function(dt)

        for _, camera in ipairs(Game.cameras_list) do

            local speed = 32 * 7 * dt / camera.scale

            if love.keyboard.isDown("left") then
                camera:move(-3)
            elseif love.keyboard.isDown("right") then
                camera:move(3)
            end

            if love.keyboard.isDown("down") then
                camera:move(nil, speed)
            elseif love.keyboard.isDown("up") then
                camera:move(nil, -speed)
            end
        end


        local camera = Game.camera

        if camera.x + (camera.desired_canvas_w) / camera.scale > map.max_x then

            -- map:load_map(nil, function(x, y, id)
            --     return x >= map.min_x
            --         and
            --         x < map.max_x + (camera.desired_canvas_w) / camera.scale * 0.1
            --         and y < 1500
            -- end)
        end
        if map.min_x < camera.x and not Game.__load_beach then
            --map:load_map(nil, { "desert", "beach" }, nil)
            Game.__load_beach = true

        end
    end,
    draw = function(camera)

        love.graphics.setColor(1, 0, 0, 1)

        ---@type JM.TileMap.Cell
        local cell = map.cells_by_pos[map.min_y] and map.cells_by_pos[map.min_y][map.min_x]

        if cell then
            love.graphics.rectangle("fill", 32 * 30, 32 * 10, 32, 32)
        end

        love.graphics.rectangle("fill", 1280, 320, 32, 32)
    end,
    layers = {
        {
            draw = function(self, camera)
                -- love.graphics.setColor(0.5, 0.5, 0.5, 1)
                -- love.graphics.rectangle("fill", 0, 0,
                --     (camera.viewport_w) / camera.desired_scale / camera.scale,
                --     (camera.viewport_h) / camera.desired_scale / camera.scale)
                Font:printf("Hello World!", 32 * 3, 32 * 5, "left")
            end,
            factor_x = -1,
            factor_y = -1
        },
        {
            draw = function(self, camera)
                map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)

                -- map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)

                -- map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)

                -- map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)

                -- map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)
                -- map:draw(camera)
            end
        },

        {
            draw = function(self, camera)
                Font:print(tostring(map.n_cells), 300, 330)
            end,
            factor_x = -1, factor_y = -1
        }
    }
})

return Game

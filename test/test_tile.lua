local package = require("/JM_love2d_package/init")
local Font = package.Font

local Tile = require("/JM_love2d_package/modules/tile/tile")
local TileSet = require("/JM_love2d_package/modules/tile/tile_set")
local TileMap = require("/JM_love2d_package/modules/tile/tile_map")

local Game = package.Scene:new(0, 0, 1366, nil, 32 * 20, 32 * 12)

local tile_img = love.graphics.newImage("/data/tileset_01.png")

local t1 = Tile:new("1", tile_img, 32 * 1, 32 * 1, 32)

local set = TileSet:new("data/tileset_01.png", 32)

local map = TileMap:new("test/my_map_data.lua",
    "data/tileset_01.png", 32
-- function(x, y, id) return x < 1500 and y < 1500 end
)

Game:implements({
    update = function(dt)
        local speed = 32 * 7 * dt / Game.camera.scale
        if love.keyboard.isDown("left") then
            Game.camera:move(-speed)
        elseif love.keyboard.isDown("right") then
            Game.camera:move(speed)
        end

        if love.keyboard.isDown("down") then
            Game.camera:move(nil, speed)
        elseif love.keyboard.isDown("up") then
            Game.camera:move(nil, -speed)
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
            map:load_map(nil, "beach", true)
            Game.__load_beach = true
            -- for j = 1, #map.cells_by_pos, 32 do
            --     local row = map.cells_by_pos[j]
            --     if not row then break end
            --     for i = 1, #row, 32 do
            --         map.cells_by_pos[j][i] = nil
            --     end
            -- end
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

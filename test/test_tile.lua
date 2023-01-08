local package = require("/JM_love2d_package/init")
local Font = package.Font

local Tile = require("/JM_love2d_package/modules/tile/tile")
local TileSet = require("/JM_love2d_package/modules/tile/tile_set")
local TileMap = require("/JM_love2d_package/modules/tile/tile_map")

local Game = package.Scene:new(0, 0, 1366, nil, 32 * 29, 32 * 20)

local tile_img = love.graphics.newImage("/data/tileset_01.png")

local t1 = Tile:new("1", tile_img, 32 * 1, 32 * 1, 32)

local set = TileSet:new("/data/tileset_01.png", 32)

local map = TileMap:new("", "/data/tileset_01.png", 32)

Game:implements({
    update = function(dt)
        local speed = 32 * 7 * dt / Game.camera.scale
        if love.keyboard.isDown("left") then
            Game.camera:set_position(Game.camera.x - speed)
        elseif love.keyboard.isDown("right") then
            Game.camera:set_position(Game.camera.x + speed)
        end

        if love.keyboard.isDown("down") then
            Game.camera:move(nil, speed)
        elseif love.keyboard.isDown("up") then
            Game.camera:move(nil, -speed)
        end
    end,
    draw = function(camera)
        -- t1:draw(32, 64)

        -- local t = set:get_tile("9")
        -- local r = t and t:draw(32, 64 * 2)


        --map:draw(camera)

        love.graphics.setColor(1, 0, 0, 1)

        ---@type JM.TileMap.Cell
        local cell = map.map[#map.map]

        ---@type JM.TileMap.Cell
        local cell_1 = map.map[1]

        love.graphics.rectangle("fill", cell_1.x, cell_1.y, 32, 32)
        love.graphics.rectangle("fill", cell_1.x, cell.y, 32, 32)
    end,
    layers = {
        {
            draw = function(self, camera)
                map:draw(camera)
            end
        },

        {
            draw = function(self, camera)
                Font:print(tostring(map.operations), 300, 330)
            end,
            factor_x = -1, factor_y = -1
        }
    }
})

return Game

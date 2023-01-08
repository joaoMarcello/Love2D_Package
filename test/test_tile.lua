local package = require("/JM_love2d_package/init")
local Font = package.Font

local Tile = require("/JM_love2d_package/modules/tile/tile")
local TileSet = require("/JM_love2d_package/modules/tile/tile_set")
local TileMap = require("/JM_love2d_package/modules/tile/tile_map")

local Game = package.Scene:new(nil, nil, nil, nil, 32 * 22, 32 * 12)

local tile_img = love.graphics.newImage("/data/tileset_01.png")

local t1 = Tile:new("1", tile_img, 32 * 1, 32 * 1, 32)

local set = TileSet:new("/data/tileset_01.png", 32)

local map = TileMap:new("", "/data/tileset_01.png", 32)

Game:implements({
    update = function(dt)

    end,
    draw = function(camera)
        t1:draw(32, 64)

        local t = set:get_tile("9")
        local r = t and t:draw(32, 64 * 2)

        Font:print(tostring(#set.tiles), 300, 300)
        Font:print(tostring(camera), 300, 330)

        map:draw(camera)
    end
})

return Game

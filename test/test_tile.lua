local package = require("/JM_love2d_package/init")
local Tile = require("/JM_love2d_package/modules/tile/tile")
local TileSet = require("/JM_love2d_package/modules/tile/tile_set")

local Game = package.Scene:new(nil, nil, nil, nil, 32 * 22, 32 * 12)

local tile_img = love.graphics.newImage("/data/tileset_01.png")

local t1 = Tile:new("1", tile_img, 32 * 1, 32 * 1, 32)

local set = TileSet:new(tile_img)

Game:implements({
    update = function(dt)

    end,
    draw = function()
        t1:draw(32, 64)

        local t = set:get_tile("14")
        local r = t and t:draw(32, 64 * 2)
    end
})

return Game

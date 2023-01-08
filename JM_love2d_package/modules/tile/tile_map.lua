local love_set_color = love.graphics.setColor
local love_draw = love.graphics.draw

---@type JM.TileSet
local TileSet = require((...):gsub("tile_map", "tile_set"))

---@class JM.TileMap
local TileMap = {}
TileMap.__index = TileMap

---@param path_map string
---@param path_tileset string
---@param tile_size number
function TileMap:new(path_map, path_tileset, tile_size)
    local obj = setmetatable({}, self)
    TileMap.__constructor__(obj, path_map, path_tileset, tile_size)
    return obj
end

---@alias JM.TileMap.Cell {x:number, y:number, id:string}

---@param path_map string
---@param path_tileset string
---@param tile_size number
function TileMap:__constructor__(path_map, path_tileset, tile_size)
    self.tile_size = tile_size or 32
    self.tile_set = TileSet:new(path_tileset, self.tile_size)
    self.sprite_batch = love.graphics.newSpriteBatch(self.tile_set.img)

    self.map = {}
    self.map_width = 15
    self.map_height = 10

    for j = 1, 10 do
        self.map[j] = {}
        for i = 1, 15 do
            self.map[j][i] = {
                x = i * self.tile_size,
                y = j * self.tile_size,
                id = tostring(math.random(9))
            }

            -- local cell = self.map[j][i]
            -- local tile = self.tile_set:get_tile(cell.id)
            -- self.sprite_batch:add(tile.quad, cell.x, cell.y)
        end
    end

    -- local sort_func = function (a, b)
    --     return a.x
    -- end
    -- for j = 1, #(self.map) do
    --     for i = 1, #(self.map[j]) do
    --         table.sort()
    --     end
    -- end

end

---@param camera JM.Camera.Camera|nil
function TileMap:draw(camera)

    self.sprite_batch:clear()

    for j = 1, #(self.map) do

        for i = 1, #(self.map[j]) do

            ---@type JM.TileMap.Cell
            local cell = self.map[j][i]

            if (camera
                and camera:rect_is_on_view(
                    cell.x, cell.y,
                    self.tile_size, self.tile_size
                ))
                or not camera
            then

                local tile = self.tile_set:get_tile(cell.id)

                self.sprite_batch:add(tile.quad, cell.x, cell.y)
            end

        end
    end

    love_set_color(1, 1, 1, 1)
    love_draw(self.sprite_batch)
end

return TileMap

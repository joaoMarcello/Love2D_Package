---@type JM.Tile
local Tile = require((...):gsub("tile_set", "tile"))

---@class JM.TileSet
local TileSet = {}
TileSet.__index = TileSet

---@param img love.Image
---@param tile_size number|nil
---@return JM.TileSet
function TileSet:new(img, tile_size)
    local obj = setmetatable({}, self)
    TileSet.__constructor__(obj, img, tile_size)
    return obj
end

---@param self JM.TileSet
local function load_tiles(self)
    local qx = math.floor(self.img_width / self.tile_size)
    local qy = math.floor(self.img_height / self.tile_size)
    local current_id = 1

    for j = 1, qy do
        for i = 1, qx do
            local tile = Tile:new(
                tostring(current_id),
                self.img,
                self.tile_size * (i - 1),
                self.tile_size * (j - 1),
                self.tile_size
            )

            table.insert(self.tiles, tile)
            self.id_to_tile[tile.id] = tile

            current_id = current_id + 1
        end
    end
end

---@param img love.Image
---@param tile_size number|nil
function TileSet:__constructor__(img, tile_size)
    self.img = img
    self.tile_size = tile_size or 32
    self.img_width, self.img_height = self.img:getDimensions()
    self.tiles = {}
    self.id_to_tile = {}
    load_tiles(self)
end

---@param id string
---@return JM.Tile|nil
function TileSet:get_tile(id)
    return self.id_to_tile[id]
end

return TileSet

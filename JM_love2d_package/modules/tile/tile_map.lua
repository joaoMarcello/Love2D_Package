local love_set_color = love.graphics.setColor
local love_draw = love.graphics.draw
local math_floor, math_min, math_max = math.floor, math.min, math.max

local Font = _G.JM_Font

---@alias JM.TileMap.Cell {x:number, y:number, id:number}

---@type JM.TileSet
local TileSet = require((...):gsub("tile_map", "tile_set"))

local function clamp(value, A, B)
    return math_min(math_max(value, A), B)
end

--==========================================================================

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

---@param path_map string
---@param path_tileset string
---@param tile_size number
function TileMap:__constructor__(path_map, path_tileset, tile_size)
    self.tile_size = tile_size or 32
    self.tile_set = TileSet:new(path_tileset, self.tile_size)
    self.sprite_batch = love.graphics.newSpriteBatch(self.tile_set.img)

    -- will store each cell in path_map
    self.map = {}

    -- also will store the cells but indexed by cell position
    self.cells_by_pos = {}

    for j = 1, 400 do
        for i = 1, 400 do
            local cell = {
                x = 32 * 30 + (i - 1) * self.tile_size,
                y = 32 * 10 + (j - 1) * self.tile_size,
                id = (math.random(9))
            }

            if cell.x > 32 * 40 and cell.x < 32 * 43 then
                goto continue
            end

            table.insert(self.map, cell)
            ::continue::
        end
    end

    table.sort(self.map,
        ---@param a JM.TileMap.Cell
        ---@param b JM.TileMap.Cell
        function(a, b)
            local wa = a.y * 5000 + a.x * 10
            local wb = b.y * 5000 + b.x * 10
            return wa < wb
        end)

    self.cells_by_pos = {}
    self.min_x = math.huge
    self.min_y = math.huge
    self.max_x = -math.huge
    self.max_y = -math.huge
    self.n_cells = #self.map

    for i = 1, self.n_cells do
        ---@type JM.TileMap.Cell
        local cell = self.map[i]

        self.cells_by_pos[cell.y] = self.cells_by_pos[cell.y] or {}
        local row = self.cells_by_pos[cell.y]
        row[cell.x] = cell

        self.min_x = cell.x < self.min_x and cell.x or self.min_x
        self.min_y = cell.y < self.min_y and cell.y or self.min_y

        self.max_x = cell.x > self.max_x and cell.x or self.max_x
        self.max_y = cell.y > self.max_y and cell.y or self.max_y
    end

    self.map = nil
    collectgarbage()
end

---@param self JM.TileMap
local function draw_with_bounds(self, left, top, right, bottom)
    self.sprite_batch:clear()

    self.operations = 0

    local cx, cy = left, top

    cy = math_floor(cy / self.tile_size) * self.tile_size
    cy = clamp(cy, self.min_y, cy)

    cx = math_floor(cx / self.tile_size) * self.tile_size
    cx = clamp(cx, self.min_x, cx)

    for j = cy, bottom, self.tile_size do

        if cx > self.max_x or cy > self.max_y then break end

        for i = cx, right, self.tile_size do

            ---@type JM.TileMap.Cell
            local cell = self.cells_by_pos[j] and self.cells_by_pos[j][i]

            if cell
            -- and camera:rect_is_on_view(
            --     cell.x, cell.y,
            --     self.tile_size, self.tile_size
            -- )
            then

                self.operations = self.operations + 1

                local tile = self.tile_set:get_tile(cell.id)

                self.sprite_batch:add(tile.quad, cell.x, cell.y)
            end

        end

    end


    love_set_color(1, 1, 1, 1)
    love_draw(self.sprite_batch)

    Font:print("" .. #(self.tile_set.tiles), 32 * 15, 32 * 8)
end

---@param self JM.TileMap
local function draw_without_camera(self)
    self.sprite_batch:clear()

    for i = 1, #(self.map) do

        ---@type JM.TileMap.Cell
        local cell = self.map[i]

        local tile = self.tile_set:get_tile(cell.id)

        self.sprite_batch:add(tile.quad, cell.x, cell.y)
    end

    love_set_color(1, 1, 1, 1)
    love_draw(self.sprite_batch)
end

---@param camera JM.Camera.Camera|nil
function TileMap:draw(camera)

    if camera then
        draw_with_bounds(self,
            camera.x,
            camera.y,
            camera:x_screen_to_world(camera.desired_canvas_w),
            camera:y_screen_to_world(camera.desired_canvas_h)
        )
    else
        draw_without_camera(self)
    end
end

return TileMap

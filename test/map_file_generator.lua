math.randomseed(os.time())
local file = io.open("test/my_map_data.lua", "w")

local tile_size = 32

local block_w = 10
local block_h = 10

if file then
    file:write(
        [[
local map = {}
local insert = table.insert
local filter = _G.JM_Map_Filter

local Entry
if filter then
    Entry = function(x, y, id)
        if filter(x, y, id) then
            insert(map, {x=x, y=y, id=id})
        end
    end
else
    Entry = function(x, y, id)
        insert(map, {x=x,y=y,id=id})
    end
end

]]
    )

    local cells = {}
    local min_x = math.huge
    local min_y = math.huge
    local max_x = -math.huge
    local max_y = -math.huge

    for j = 1, 40, 1 do
        for i = 1, 256, 1 do
            local x = 32 * 30 + (i - 1) * tile_size
            local y = 32 * 10 + (j - 1) * tile_size
            local id = math.random(9)

            table.insert(cells, { x = x, y = y, id = id })
        end
    end

    for i = 1, #(cells) do
        local cell = cells[i]

        min_x = cell.x < min_x and cell.x or min_x
        min_y = cell.y < min_y and cell.y or min_y

        max_x = cell.x > max_x and cell.x or max_x
        max_y = cell.y > max_y and cell.y or max_y
    end

    for i = 1, #(cells) do
        local cell = cells[i]

        file:write(string.format("Entry(%d,%d,%d)\n", cell.x, cell.y, cell.id))
    end

    file:write("return map")

    file:close()
    print(">>> Done.\n")
else
    print(">> Error opening file.")
end

math.randomseed(os.time())
local file = io.open("test/my_map_data.lua", "w")

local tile_size = 32

local world = {
    { name = "desert", left = 32 * 30, top = 32 * 10, right = 32 * 30 + 32 * 10, bottom = 32 * 10 + 32 * 15, cells = {} },
    { name = "beach", left = 32 * 30 + 32 * 10, top = 32 * 10, right = 32 * 30 + 32 * 10 + 32 * 20,
        bottom = 32 * 10 + 32 * 15, cells = {} }
}

local function in_bounds(cell, region)
    return cell.x + tile_size - 1 >= region.left
        and cell.x < region.right
        and cell.y + tile_size - 1 >= region.top
        and cell.y < region.bottom
end

if file then
    file:write(
        [[
local map = {}
local insert = table.insert

_G.JM_Map_Filter = _G.JM_Map_Filter or nil
local filter = _G.JM_Map_Filter or function(x,y,id) return true end

_G.JM_World_Region = _G.JM_World_Region or nil
local region = _G.JM_World_Region

local function Entry(x,y,id)
    if filter(x,y,id) then
        insert(map,{x=x,y=y,id=id})
    end
end

local function select_region(id)
    if type(region) == "table" then
        for i=1, #region do
            if region[i] == id then
                return true
            end
        end
    else
        return not region or region == id
    end
end

]]
    )

    local cells = {}
    local no_region_cells = {}

    local min_x = math.huge
    local min_y = math.huge
    local max_x = -math.huge
    local max_y = -math.huge

    for j = 1, 256, 1 do
        for i = 1, 256, 1 do
            local x = 32 * 30 + (i - 1) * tile_size
            local y = 32 * 10 + (j - 1) * tile_size
            local id = math.random(9)
            local cell = { x = x, y = y, id = id }

            table.insert(cells, cell)
        end
    end

    for i = 1, #(cells) do
        local cell = cells[i]

        min_x = cell.x < min_x and cell.x or min_x
        min_y = cell.y < min_y and cell.y or min_y

        max_x = cell.x > max_x and cell.x or max_x
        max_y = cell.y > max_y and cell.y or max_y

        local has_region = false
        for _, region in ipairs(world) do
            if in_bounds(cell, region) then
                has_region = true
                table.insert(region.cells, cell)
            end
        end

        if not has_region then
            table.insert(no_region_cells, cell)
        end
    end


    local max_chunks = 5000

    for _, region in ipairs(world) do

        local N = #region.cells

        if N > 0 then

            for i = 1, N do
                if (i - 1) % max_chunks == 0 then
                    if i ~= 1 then
                        file:write("\nend")
                    end
                    file:write(string.format('\nif select_region("%s") then\n', region.name))
                end

                local cell = region.cells[i]
                file:write(string.format("    Entry(%d,%d,%d)\n", cell.x, cell.y, cell.id))
            end
            file:write("end")
        end
    end

    if #no_region_cells > 0 then
        for i = 1, #no_region_cells do
            if (i - 1) % max_chunks == 0 then
                if i ~= 1 then
                    file:write("\nend")
                end
                file:write('\nif not region then\n')
            end
            local cell = no_region_cells[i]
            file:write(string.format("    Entry(%d,%d,%d)\n", cell.x, cell.y, cell.id))
        end
        file:write("end")
    end

    file:write("\n_G.JM_Map_Filter = nil")
    file:write("\n_G.JM_World_Region = nil")
    file:write("\nreturn map")

    file:close()
    print(">>> Done.\n")
else
    print(">> Error opening file.")
end

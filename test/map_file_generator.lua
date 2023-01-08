math.randomseed(os.time())
local file = io.open("test/my_map_data.lua", "w")

local tile_size = 32

if file then
    file:write(
        [[
local map = {}
local insert = table.insert

local function Entry(cell)
    insert(map, cell)
end

]]
    )

    for j = 1, 20 do
        for i = 1, 34 do
            file:write(string.format("Entry {\n   x = %d,\n   y = %d,\n   id = %d\n}\n\n",
                32 * 30 + (i - 1) * tile_size,
                32 * 10 + (j - 1) * tile_size,
                math.random(9)
            ))
        end
    end

    file:write("\nreturn map")

    file:close()
    print(">>> Done.\n")
else
    print(">> Error opening file.")
end

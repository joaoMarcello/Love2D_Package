math.randomseed(os.time())
local file = io.open("test/my_map_data.lua", "w")

local tile_size = 32

if file then
    file:write(
        [[
local map = {}
local insert = table.insert

local function Entry(x, y, id)
    insert(map, {x=x, y=y, id=id})
end

]]
    )

    for j = 1, 256 do
        for i = 1, 256 do
            file:write(string.format("Entry(%d,%d,%d)\n",
                32 * 30 + (i - 1) * tile_size,
                32 * 10 + (j - 1) * tile_size,
                math.random(9)
            ))
        end
    end

    file:write("return map")

    file:close()
    print(">>> Done.\n")
else
    print(">> Error opening file.")
end

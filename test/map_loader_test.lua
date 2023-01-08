local count = 0
function Entry(...)
    count = count + 1
end

dofile("test/my_map_data.lua")

print("" .. count .. "-" .. (20 * 34))

local text = "à"
local utf8 = require("utf8")

local v = text:match(".") or text:match("..")
print(utf8.codepoint("ô"))
print(utf8.char(231))
print(utf8.codepoint("ç"))

local codes = {}
for p, c in utf8.codes("asthá e os amigos\n\toi\n\tteste") do
    local text = utf8.char(c)
    if text == "\t" then
        -- print("barra t")
    elseif text == "\n" then
        -- print("barra n")
    else
        -- print("-- " .. text)
    end

    table.insert(codes, c)
end

-- local converted_text = utf8.char(table.unpack(codes))
-- print(converted_text)

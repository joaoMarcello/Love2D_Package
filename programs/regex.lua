---@param line string
---@param sep string|nil
local function parse_csv_line(line, sep)
    local res = {}
    local pos = 1
    sep = sep or ','
    while true do
        local c = string.sub(line, pos, pos)
        if (c == "") then break end
        if (c == '"') then
            -- quoted value (ignore separator within)
            local txt = ""
            repeat
                local startp, endp = string.find(line, '^%b""', pos)
                txt = txt .. string.sub(line, startp + 1, endp - 1)
                pos = endp + 1
                c = string.sub(line, pos, pos)
                if (c == '"') then txt = txt .. '"' end
                -- check first char AFTER quoted string, if it is another
                -- quoted string without separator, then append it
                -- this is the way to "escape" the quote char in a quote. example:
                --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
            until (c ~= '"')
            table.insert(res, txt)
            assert(c == sep or c == "")
            pos = pos + 1
        else
            -- no quotes used, just look for the first separator
            local startp, endp = string.find(line, sep, pos)
            if (startp) then
                table.insert(res, string.sub(line, pos, startp - 1))
                pos = endp + 1
            else
                -- no separator found -> use rest of string and terminate
                table.insert(res, string.sub(line, pos))
                break
            end
        end
    end
    return res
end

local s = "</font-size>"

---@param s string
local function do_things(s)
    s = s:sub(2, #s - 1)
    if not s or s == "" then return {} end

    local N = #s
    local i = 1
    local result = {}

    while (i <= N) do
        local startp, endp = s:find("[=,]", i)

        if startp then
            local left = s:sub(i, endp - 1):match("[^ ].*[^ ]")
            local s2, e2 = s:find(",", i)

            i = endp
            local right

            if s2 then
                right = s:sub(endp + 1, e2 - 1)
                i = e2
            else
                right = s:sub(endp + 1)
            end

            if right then
                if right == "" then
                    right = true
                elseif tonumber(right) then
                    right = tonumber(right)
                elseif right:match("true") then
                    right = true
                elseif right:match("false") then
                    right = false
                else

                end
            end

            if left then
                result[left] = right
                print(left .. "==" .. tostring(right) .. "_ " .. type(right))
            end
        end

        i = i + 1
    end

    if #result <= 0 then result[s] = true end
    return result
end

local result = do_things(s)
print(s)
for l, r in pairs(result) do
    print(l .. " - " .. tostring(r))
end

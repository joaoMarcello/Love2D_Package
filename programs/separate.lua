-- local s = "t --a--syu--b--no"

-- local command = "color"
-- local r = string.match(s, "< *" .. command .. "[ %d,]*>", 1) -- find init tag
-- local r2 = string.match(s, "</ *color *>") -- find end tag


-- local r3 = string.match(s, "%-%-.-%-%-", 1)

---comment
---@param s string
local function find_tag(s)
    local words = {}
    local current_i = 1

    while (true) do
        local find = s:match("< *color[%d,]*>", current_i)
            or s:match("</ *color *>", current_i)

        if find then
            local startp, endp = s:find("< *color[%d,]*>", current_i)
            if not startp then
                startp, endp = s:find("</ *color *>", current_i)
            end

            local sub_s = s:sub(current_i, startp - 1)
            if sub_s and sub_s ~= "" and sub_s ~= " " then
                table.insert(words, sub_s)
            end

            table.insert(words, find)
            current_i = endp + 1
        else
            break
        end
    end

    local rest = s:sub(current_i, #s)
    if rest ~= "" and rest ~= " " then
        table.insert(words, rest)
    end
    return words
end

---@param s string
local function separate_string(s, list)
    s = s .. " "
    local sep = "\n\t "
    local current_init = 1
    local words = list or {}

    while (current_init <= #s) do
        local regex = "[^ ]*.-[" .. sep .. "]"
        local tag_regex = "< *[%d, %w/]*>"

        local tag = s:match(tag_regex, current_init)
        local find = not tag and string.match(s, regex, current_init)
        local nick = find and string.match(find, "%-%-%w-%-%-")

        if tag then
            local startp, endp = string.find(s, tag_regex, current_init)
            local sub_s = s:sub(startp, endp)
            local prev_s = s:sub(current_init, startp - 1)

            if prev_s ~= "" and prev_s ~= " " then
                -- table.insert(words, prev_s)
                separate_string(prev_s, words)
            end

            table.insert(words, sub_s)
            current_init = endp

        elseif nick then
            local startp, endp = string.find(s, "%-%-%w-%-%-", current_init)
            local sub_s = s:sub(startp, endp)
            local prev_word = s:sub(current_init, startp - 1)

            if startp ~= 1 and prev_word ~= "" and prev_word ~= " " then
                table.insert(words, prev_word)
            end

            if sub_s ~= "" then
                table.insert(words, sub_s)
            end

            current_init = endp

        elseif find then

            local startp, endp = string.find(s, regex, current_init)
            local sub_s = s:sub(startp, endp - 1)

            if sub_s ~= "" then
                table.insert(words, sub_s)
            end

            if s:sub(endp, endp) == "\n" then table.insert(words, "\n") end
            if s:sub(endp, endp) == "\t" then table.insert(words, "\t") end

            current_init = endp
        else
            break
        end

        current_init = current_init + 1
    end

    if s:sub(current_init, #s) ~= "" then
        table.insert(words, s:sub(current_init, #s))
    end

    return words
end

local function separate2(s, list)
    s = s .. " "
    local sep = "\n " -- line break and space as separators
    local cur_init = 1
    local words = list or {}
    local N = #s
    while (cur_init <= N) do
        local regex = string.format("[^ ]*.-[%s]", sep)
        local tag_regex = "< *[%d, %.%w/]*>"

        local tag = false and s:match(tag_regex, cur_init)
        local find = not tag and string.match(s, regex, cur_init)

        if tag then
            local startp, endp = string.find(s, tag_regex, cur_init)
            local sub_s = s:sub(cur_init, endp)
            local prev_s = s:sub(cur_init, startp)

            -- local sep_p = 1

            local m1 = string.match(prev_s, string.format("[%s]<", sep))
            local t1, t2 = string.find(prev_s, ".* ")

            if not m1 and not t1 then
                local add = sub_s
                table.insert(words, sub_s)
            elseif m1 then
                local zz = s:sub(cur_init, startp - 1)
                separate2(zz, words)
                local add = tag
                table.insert(words, tag)
            elseif t1 then
                local zz = prev_s:sub(1, t2)
                separate2(zz, words)
                local add = prev_s:sub(t2 + 1, #prev_s - 1) .. tag
                table.insert(words, add)
            end

            cur_init = endp

        elseif find then
            local startp, endp = string.find(s, regex, cur_init)
            if startp then
                local sub_s = s:sub(startp, endp - 1)

                if sub_s and sub_s ~= "" then
                    table.insert(words, sub_s)
                end

                sub_s = s:sub(endp, endp)
                if sub_s == "\n" then table.insert(words, "\n") end
                if sub_s == "\t" then table.insert(words, "\t") end

                cur_init = endp
            end
        end


        cur_init = cur_init + 1
    end

    local rest = s:sub(cur_init, N)

    if rest ~= "" and not rest:match(" *") then
        table.insert(words, s:sub(cur_init, N))
    end

    return words
end

local text = " Em- <bold>---a-- meio às sinuosas e confusas</bold> correntezas--c-- inimigas\nastha yuno    a   b "

text = "Hello <freaky>aqui quem fala eh o seu <italic>capitão</italic>. nao sei mais oque escrever para este texto ficar longo então vou ficar enrolando <bold>World <italic><color,1,0,0,1f>Iupi <bold> World</color> Wo"

-- local w = separate_string(" oi p--astha--goku--p-- ----a--b")

-- local w = separate_string(text)
-- for i = 1, #w do
--     print(tostring(i) .. "__" .. tostring(w[i]) .. "__")
-- end --]]
-- print('====================')
-- local w2 = find_tag(w[2])
-- for i = 1, #w2 do
--     print(tostring(i) .. "__" .. tostring(w2[i]) .. "__")
-- end

local w = separate2(text)
for i = 1, #w do
    print(tostring(i) .. "__" .. tostring(w[i]) .. "__")
end

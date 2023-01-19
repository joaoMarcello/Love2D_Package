---@type JM.Font.Phrase
local Phrase = require((...):gsub("gui.textBox", "font.Phrase"))

---@enum JM.GUI.TextBox.EventTypes
local Event = {
    finishScreen = 1,
    finishAll = 2,
    changeScreen = 3,
    glyphChange = 4
}
---@alias JM.GUI.TextBox.EventNames "finishScreen"|"finishAll"|"changeScreen"

---@class JM.GUI.TextBox
local TextBox = {}
TextBox.__index = TextBox

function TextBox:new(text, font, x, y, w)
    local obj = setmetatable({}, self)
    -- text = "<effect=goddess, delay=0.05>" .. text
    TextBox.__constructor__(obj, { text = text, x = x, y = y, font = font }, w)
    return obj
end

function TextBox:__constructor__(args, w)
    self.sentence = Phrase:new(args)
    self.sentence:set_bounds(nil, nil, args.x + w)
    self.lines = self.sentence:get_lines(self.sentence.x)

    self.align = "left"
    self.x = self.sentence.x
    self.y = self.sentence.y
    self.w = w
    self.h = -math.huge
    self.is_visible = true

    self.cur_glyph = 0
    self.time_glyph = 0.0
    self.max_time_glyph = 0.05
    self.extra_time = 0.0

    self.font = self.sentence.__font
    self.font_size = self.font.__font_size
    self.font_config = self.font:__get_configuration()

    self.amount_lines = 4
    self.amount_screens = math.ceil(#self.lines / self.amount_lines) --3

    local N = #self.lines

    self.screens = {}
    local j = 1
    while j <= N do
        table.insert(self.screens,
            { unpack(self.lines, j, j + self.amount_lines - 1) })

        -- defining the textBox height
        local h = self.sentence:text_height(self.screens[#self.screens])
        self.h = h > self.h and h or self.h

        local screen = self.screens[#self.screens]

        -- removing empty lines
        local k = 1
        while k <= #screen do
            local line = screen[k]

            if #line == 2 and line[1].text == "\n"
                and line[2].text == "\n"
            then
                table.remove(screen, k)
                k = k - 1
            end
            k = k + 1
        end --end removing empty lines

        -- removing empty screens
        if #screen <= 0 then
            table.remove(self.screens, #self.screens)
            self.amount_screens = self.amount_screens - 1
        end

        j = j + self.amount_lines
    end

    self.cur_screen = 1
end

function TextBox:rect()
    return self.x, self.y, self.w, self.h
end

function TextBox:key_pressed(key)
    if key == "space" then
        local r = self:go_to_next_screen()

        if not r and self:finish_screen() then
            self:restart()
        end
    end
end

function TextBox:refresh()
    self.cur_glyph = 0
    self.time_glyph = 0.0
    self.extra_time = 0.0
end

function TextBox:go_to_next_screen()
    if self:finish_screen() and self.cur_screen < self.amount_screens then
        self.cur_screen = self.cur_screen + 1
        self:refresh()
        return true
    end
    return false
end

function TextBox:restart()
    self.cur_screen = 1
    self:refresh()
end

function TextBox:update(dt)

    local glyph = self.sentence:get_glyph(self.cur_glyph, self.screens[self.cur_screen])
    if glyph then
        local id = glyph.__id

        if id:match("[%.;?]") or id == "--dots--" then
            self.extra_time = 0.8
        elseif id:match("[,!]") then
            self.extra_time = 0.3
        else
            self.extra_time = 0.0
        end
    end

    self.__finish = not glyph and self.cur_glyph ~= 0

    if love.keyboard.isDown("a") then self.cur_glyph = nil end

    self.sentence:update(dt)

    self.time_glyph = self.time_glyph + dt

    if self.time_glyph >= (self.max_time_glyph + self.extra_time) then

        self.time_glyph = self.time_glyph - self.max_time_glyph
            - self.extra_time

        if self.cur_glyph then
            self.cur_glyph = self.cur_glyph + 1
        end
    end

end

local Font = _G.JM_Font
function TextBox:draw()
    local x, y = self.x, self.y

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", self:rect())

    local screen = self.screens[self.cur_screen]

    self.font:push()
    self.font:set_configuration(self.font_config)
    local height = self.sentence:text_height(screen)

    local tx, ty, glyph = self.sentence:draw_lines(
        screen,
        x, y + self.h / 2 - height / 2,
        self.align, nil,
        self.cur_glyph
    )
    self.font:pop()

    -- if glyph then
    --     local id = glyph.__id

    --     if id:match("[%.;?]") or id == "--dots--" then
    --         self.extra_time = 0.8
    --     elseif id:match("[,!]") then
    --         self.extra_time = 0.3
    --     else
    --         self.extra_time = 0.0
    --     end
    -- end

    -- self.__finish = not tx

    -- local g = self.sentence:get_glyph(self.cur_glyph, screen)
    -- if g then
    --     Font:printf(tostring(g.__id), self.x, self.y - 20)
    -- end

    Font:print(self.__finish and "<color>true" or "<color, 1, 1, 1>false", self.x, self.y - 20)

    -- Font:print("qScreen=" .. tostring(self.amount_screens) .. "-" .. tostring(#self.lines), self.x, self.y - 40)

    if self:finish_screen() then
        Font:print("--a--", self.x + self.w + 5,
            self.y + self.h + 10)
    end
end

function TextBox:finish_screen()
    return self.__finish
end

function TextBox:finished()
    return self.__finish and self.cur_screen == self.amount_screens
end

function TextBox:on_event(name, action, args)
    local evt_type = Event[name]
    if not evt_type then return end

    self.events = self.events or {}

    self.events[evt_type] = {
        type = evt_type,
        action = action,
        args = args
    }
end

return TextBox

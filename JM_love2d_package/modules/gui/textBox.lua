---@type JM.Font.Phrase
local Phrase = require((...):gsub("gui.textBox", "font.Phrase"))

---@enum JM.GUI.TextBox.EventTypes
local Event = {
    finishScreen = 1,
    finishAll = 2,
    changeScreen = 3,
    glyphChange = 4
}
---@alias JM.GUI.TextBox.EventNames "finishScreen"|"finishAll"|"changeScreen"|"glyphChange"

local Mode = {
    normal = 1,
    goddess = 2,
    popin = 3,
    rainbow = 4
}

local function mode_goddess(g)
    g:apply_effect("fadein", { speed = 0.2 })
end

local function mode_popin(g)
    g:apply_effect("popin", { speed = 0.2 })
end

local function mode_rainbow(g)
    g:set_color2(math.random(), math.random(), math.random())
end

local ModeAction = {
    normal = function(...) return false end,
    goddess = mode_goddess,
    popin = mode_popin,
    rainbow = mode_rainbow
}
---@alias JM.GUI.TextBox.Modes "normal"|"goddess"|"popin"|"rainbow"|nil


local Align = {
    top = 1,
    bottom = 2,
    center = 3
}

---@param self JM.GUI.TextBox
---@param type_ JM.GUI.TextBox.EventTypes
local function dispatch_event(self, type_)
    local evt = self.events and self.events[type_]
    local r = evt and evt.action(evt.args)
end

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
    self.text_align = Align.center
    self.x = self.sentence.x
    self.y = self.sentence.y
    self.w = w
    self.h = -math.huge
    self.is_visible = true

    self.cur_glyph = 0
    self.time_glyph = 0.0
    self.max_time_glyph = 0.05
    self.extra_time = 0.0

    self.time_pause = 0.0

    self.simulate_speak = false

    self.font = self.sentence.__font
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

    self:set_mode()
end

---@param mode JM.GUI.TextBox.Modes
function TextBox:set_mode(mode)
    if mode == "goddess" then
        self.max_time_glyph = 0.12
    end
    self.glyph_change_action = ModeAction[mode]
end

function TextBox:get_current_glyph()
    return self.sentence:get_glyph(self.cur_glyph, self.screens[self.cur_screen])
end

function TextBox:rect()
    return self.x, self.y, self.w, self.h
end

function TextBox:key_pressed(key)
    if key == "space" then
        local r = self:go_to_next_screen()

        if not r and self:screen_is_finished() then
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
    if self:screen_is_finished() and self.cur_screen < self.amount_screens then
        self.cur_screen = self.cur_screen + 1
        self:refresh()
        return true
    end
    return false
end

function TextBox:restart()
    self.cur_screen = 1
    self.used_tags = nil
    self:refresh()
end

function TextBox:set_finish(value)
    if value then
        if not self.__finish then

            self.__finish = true
        end
    else
        if self.__finish then

            self.__finish = false
        end
    end
end

function TextBox:screen_is_finished()
    return self.__finish
end

function TextBox:finished()
    return self.__finish and self.cur_screen == self.amount_screens
end

---@param name JM.GUI.TextBox.EventNames
---@param action function
---@param args any
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

function TextBox:skip_screen()
    self.cur_glyph = nil
end

function TextBox:update(dt)

    self.sentence:update(dt)

    if self.time_pause > 0 then
        self.time_pause = self.time_pause - dt
        if self.time_pause <= 0 then
            self.time_pause = 0.0
        else
            return false
        end
    end

    if love.keyboard.isDown("a") then self:skip_screen() end

    self.time_glyph = self.time_glyph + dt

    if self.time_glyph >= (self.max_time_glyph + self.extra_time) then

        self.time_glyph = self.time_glyph - self.max_time_glyph
            - self.extra_time

        if self.cur_glyph then
            self.cur_glyph = self.cur_glyph + 1
            dispatch_event(self, Event.glyphChange)

            local g = self:get_current_glyph()
            local r = g and self.glyph_change_action
                and self.glyph_change_action(g)
        end
    end


    local glyph, word, endword = self.sentence:get_glyph(self.cur_glyph, self.screens[self.cur_screen])

    if glyph then
        if self.simulate_speak then
            local id = glyph.__id

            if id:match("[%.;?]") then
                self.extra_time = 0.8
            elseif id:match("[,!]") then
                self.extra_time = 0.3
            else
                self.extra_time = 0.0
            end
        end
        --===================================================
        if word then
            local tags = self.sentence.word_to_tag[word]

            if tags and endword then
                self.used_tags = self.used_tags or {}
                local N = #tags

                for i = 1, N do
                    local tag = tags[i]
                    if not self.used_tags[tag] and tag["pause"] then
                        self.used_tags[tag] = true
                        self.time_pause = tag["pause"]
                        return false
                    end
                end
            end
        end
    end

    self:set_finish(not glyph and self.cur_glyph ~= 0)
end

local Font = _G.JM_Font

function TextBox:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", self:rect())

    local screen = self.screens[self.cur_screen]

    self.font:push()
    self.font:set_configuration(self.font_config)

    local height = self.sentence:text_height(screen)

    local py = self.y
    if self.text_align == Align.center then
        py = py + self.h / 2 - height / 2
    elseif self.text_align == Align.bottom then
        py = py + self.h - height
    end

    local tx, ty, glyph = self.sentence:draw_lines(
        screen,
        self.x, py,
        self.align, nil,
        self.cur_glyph
    )

    self.font:pop()
    --==========================================================

    Font:print(self.__finish and "<color>true" or "<color, 1, 1, 1>false", self.x, self.y - 20)

    Font:print(tostring(self.sentence.tags[1]["pause"]), self.x, self.y + self.h + 10)

    if self:screen_is_finished() then
        Font:print("--a--", self.x + self.w + 5,
            self.y + self.h + 10)
    end
end

return TextBox

---@type JM.GUI.Component
local Component = require((...):gsub("container", "component"))

---@enum JM.GUI.Container.InsertMode
local INSERT_MODE = {
    normal = 1,
    left = 2,
    right = 3,
    center = 4,
    top = 5,
    bottom = 6
}


---@class JM.GUI.Container: JM.GUI.Component
local Container = setmetatable({}, Component)
Container.__index = Container

---@return JM.GUI.Container|JM.GUI.Component
function Container:new(args)

    ---@type JM.GUI.Container|JM.GUI.Component
    local obj = Component:new(args)
    self.__index = self
    setmetatable(obj, self)

    obj:__constructor__(args)

    return obj
end

function Container:__constructor__(args)
    args = args or {}
    self.components = {}
    self.space_vertical = 15
    self.space_horizontal = 15
    self.border_x = 15
    self.border_y = 15
    self.type = self.TYPE.container
    self:set_type(args.type or "", args.mode or "center", args.grid_x, args.grid_y)
end

function Container:set_position(x, y)
    x = x or self.x
    y = y or self.y

    local diff_x, diff_y = x - self.x, y - self.y

    self.x, self.y = x, y

    for _, gc in ipairs(self.components) do
        ---@type JM.GUI.Component
        local c = gc
        c:set_position(c.x + diff_x, c.y + diff_y)
    end
end

function Container:update(dt)
    for i = #(self.components), 1, -1 do

        ---@type JM.GUI.Component
        local gc = self.components[i]

        if gc.remove_ then
            table.remove(self.components, i)
        else
            local r = gc.is_enable and gc:update(dt)
        end
    end
end

function Container:mouse_pressed(x, y)
    for i = 1, #(self.components) do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_enable and not gc.remove_
            and gc:mouse_pressed(x, y)
    end
end

function Container:mouse_released(x, y)
    for i = 1, #(self.components) do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_enable and not gc.remove_
            and gc:mouse_released(x, y)
    end
end

function Container:key_pressed(key, scancode, isrepeat)
    for i = 1, #(self.components) do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_enable and not gc.remove_
            and gc:key_pressed(key, scancode, isrepeat)
    end
end

function Container:key_released(key, scancode)
    for i = 1, #(self.components) do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_enable and not gc.remove_
            and gc:key_released(key, scancode)
    end
end

function Container:draw()
    for i = 1, #(self.components) do
        ---@type JM.GUI.Component
        local gc = self.components[i]

        local r = gc.is_visible and not gc.remove_
            and gc:draw()
    end

    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("line", self:rect())

    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.rectangle("line", self.x + self.border_x, self.y + self.border_y, self.w - self.border_x * 2,
        self.h - self.border_y * 2)
end

---@param obj JM.GUI.Component
---@return JM.GUI.Component
function Container:add(obj)

    self.total_width = self.total_width or 0
    self.total_height = self.total_height or 0

    self.total_width = self.total_width + obj.w
    self.total_height = self.total_height + obj.h

    table.insert(self.components, obj)

    -- self:refresh_positions_x()
    self:__add_behavior__()
    return obj
end

function Container:set_type(type_, mode, grid_x, grid_y)
    mode = INSERT_MODE[mode]
    mode = mode or INSERT_MODE.center

    if type_ == "horizontal_list" then
        ---@diagnostic disable-next-line: duplicate-set-field
        self.__add_behavior__ = function(self)
            self:refresh_positions_x(mode)
        end
    elseif type_ == "vertical_list" then
        ---@diagnostic disable-next-line: duplicate-set-field
        self.__add_behavior__ = function(self)
            self:refresh_positions_y(mode)
        end
    elseif type_ == "grid" then
        ---@diagnostic disable-next-line: duplicate-set-field
        self.__add_behavior__ = function(self)
            self:refresh_pos_grid(grid_y, grid_x)
        end
    else -- free position

        ---@diagnostic disable-next-line: duplicate-set-field
        self.__add_behavior__ = function() end
    end
end

---@param mode JM.GUI.Container.InsertMode
function Container:refresh_positions_y(mode)
    local N = #self.components
    if N <= 0 then return end

    local x = self.x + self.border_x
    local y = self.y + self.border_y
    local w = self.w - self.border_x * 2
    local h = self.h - self.border_y * 2
    local space = (h - self.total_height) / (N - 1)

    for i = 1, N do
        ---@type JM.GUI.Component|nil
        local prev = self.components[i - 1]

        ---@type JM.GUI.Component
        local gc = self.components[i]

        local px = gc.x
        if mode == INSERT_MODE.left then
            px = x

        elseif mode == INSERT_MODE.right then
            px = x + w - gc.w

        elseif mode == INSERT_MODE.center then
            px = self.x + self.border_x
                + (self.w - self.border_x * 2) / 2
                - gc.w / 2
        end

        gc:set_position(
            px,
            prev and prev.bottom + space or y
        )
    end
end

---@param mode JM.GUI.Container.InsertMode
function Container:refresh_positions_x(mode)
    local N = #self.components
    if N <= 0 then return end

    local x = self.x + self.border_x
    local y = self.y + self.border_y
    local w = self.w - self.border_x * 2
    local h = self.h - self.border_y * 2
    local space = (w - self.total_width) / (N - 1)

    for i = 1, N do
        ---@type JM.GUI.Component|nil
        local prev = self.components[i - 1]

        ---@type JM.GUI.Component
        local gc = self.components[i]

        local py = gc.y
        if mode == INSERT_MODE.center then
            py = y + h / 2 - gc.h / 2
        elseif mode == INSERT_MODE.top then
            py = y
        elseif mode == INSERT_MODE.bottom then
            py = y + h - gc.h
        end

        gc:set_position(
            prev and prev.right + space or x,
            py
        )
    end
end

function Container:refresh_pos_grid(row, column)
    local N = #self.components
    if N <= 0 then return end

    row, column = row or 3, column or 2

    assert(N <= row * column, "\n>>Error: Many components added to container.")

    local x = self.x + self.border_x
    local y = self.y + self.border_y
    local w = self.w - self.border_x * 2
    local h = self.h - self.border_y * 2

    local cell_w = w / column
    local cell_h = h / row

    for i = 1, row do
        for j = 1, column do
            ---@type JM.GUI.Component
            local gc = self.components[column * (i - 1) + j]

            if gc then
                local py = y + (i - 1) * cell_h
                local px = x + (j - 1) * cell_w

                gc:set_position(
                    px + cell_w / 2 - gc.w / 2,
                    py + cell_h / 2 - gc.h / 2
                )
            else
                return
            end
        end
    end
end

return Container

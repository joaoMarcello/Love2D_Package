local path = (...)

local set_canvas = love.graphics.setCanvas
local clear_screen = love.graphics.clear
local set_blend_mode = love.graphics.setBlendMode
local set_color_draw = love.graphics.setColor
local love_draw = love.graphics.draw

---@param self JM.Screen
local function to_world(self, x, y)
    x, y = x - self.x, y - self.y
    x, y = x / self.scale_x, y / self.scale_y
    return x, y
end

---@class JM.Screen
local Screen = {}

---@param self JM.Screen
---@return JM.Screen
function Screen:new(x, y, w, h)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Screen.__constructor__(obj, x, y, w, h)

    return obj
end

function Screen:__constructor__(x, y, w, h)
    ---@type JM.Camera.Camera
    local Camera = require(string.gsub(path, "jm_screen", "jm_camera"))

    self.x = x or 0
    self.y = y or 0
    self.w = w or (1366 / 2) --love.graphics.getWidth()
    self.h = h or (768 / 2) --love.graphics.getHeight()

    self.scale_x = 1
    self.scale_y = self.scale_x

    self.camera = Camera:new(0, 0, self.w, self.h)

    self.canvas = love.graphics.newCanvas(self.w, self.h)
    self.canvas:setFilter("nearest", "nearest")
end

function Screen:to_world(x, y)
    return to_world(self, x, y)
end

function Screen:load()
    return self.load_action and self.load_action(self.load_args)
end

function Screen:get_camera()
    return self.camera
end

function Screen:keypressed(key)
    return self.keypressed_action
        and self.keypressed_action(key, self.keypressed_args)
end

function Screen:keyreleased(key)
    return self.keyreleased_action
        and self.keyreleased_action(key, self.keyreleased_args)
end

function Screen:set_background_draw(action, args)
    self.background_draw = action
    self.background_draw_args = args
end

function Screen:set_load_action(action, args)
    self.load_action = action
    self.load_args = args
end

function Screen:set_foreground_draw(action, args)
    self.foreground_draw = action
    self.foreground_draw_args = args
end

function Screen:set_update_action(action, args)
    self.update_action = action
    self.update_args = args
end

function Screen:set_draw_action(action, args)
    self.draw_action = action
    self.draw_args = args
end

function Screen:set_keypressed_action(action, args)
    self.keypressed_action = action
    self.keypressed_args = args
end

function Screen:set_keyreleased_action(action, args)
    self.keyreleased_action = action
    self.keyreleased_args = args
end

function Screen:update(dt)
    local r = self.update_action
        and self.update_action(dt, self.update_args)

    self.camera:update(dt)
    return r
end

function Screen:draw()
    set_canvas(self.canvas)
    clear_screen(0, 0, 0, 0)
    set_blend_mode("alpha")

    set_color_draw(0.4, 0.4, 0.4, 1)
    love.graphics.rectangle("fill", 0, 0, self.w * self.scale_x, self.h * self.scale_y)

    if self.background_draw then
        self.background_draw(self.background_draw_args)
    end

    self.camera:attach()

    local r = self.draw_action and self.draw_action(self.draw_args)

    self.camera:detach()

    if self.foreground_draw then
        self.foreground_draw(self.background_draw_args)
    end

    set_canvas()
    --============================================================
    set_color_draw(1, 1, 1, 1)
    set_blend_mode("alpha", "premultiplied")
    love_draw(self.canvas,
        self.x,
        self.y,
        0,
        self.scale_x, self.scale_y)

    return r
end

return Screen

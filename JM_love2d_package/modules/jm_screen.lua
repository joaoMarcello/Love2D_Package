local path = (...)

local set_canvas = love.graphics.setCanvas
local clear_screen = love.graphics.clear
local set_blend_mode = love.graphics.setBlendMode
local translate = love.graphics.translate
local scale = love.graphics.scale
local push = love.graphics.push
local pop = love.graphics.pop
local set_color_draw = love.graphics.setColor
local love_draw = love.graphics.draw
local set_shader = love.graphics.setShader

---@param self JM.Screen
local function to_world(self, x, y, camera)
    x = x / self.scale_x
    y = y / self.scale_y

    x = x - self.x
    y = y - self.y

    return x - camera.viewport_x, y - camera.viewport_y
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
    self.h = h or 600 --love.graphics.getHeight()

    self.scale_x = 1 --1366 / self.w
    self.scale_y = self.scale_x --768 / self.h --self.scale_x

    self.world_left = 32 * 10
    self.world_right = 32 * 35
    self.world_top = -32 * 4
    self.world_bottom = 32 * 12

    self.camera = Camera:new({
        -- camera's viewport
        x = self.w / 2,
        y = 32,
        w = self.w,
        h = 32 * 7,

        -- world bounds
        bounds = {
            left = self.world_left,
            right = self.world_right,
            top = self.world_top,
            bottom = self.world_bottom
        },

        --canvas size
        canvas_width = self.w,
        canvas_height = self.h,

        tile_size = 32,

        scale = 0.4,

        color = { 0.9, 0.8, 1, 1 },
    })

    self.camera2 = Camera:new({
        -- camera's viewport
        x = 0,
        y = 0,
        w = self.w / 2,
        h = self.h * 0.9,

        -- world bounds
        bounds = {
            left = self.world_left,
            right = self.world_right,
            top = self.world_top,
            bottom = self.world_bottom
        },

        --canvas size
        canvas_width = self.w,
        canvas_height = self.h,

        tile_size = 32,

        color = { 0.3, 0.3, 1, 1 },
        scale = 1
    })

    self.canvas = love.graphics.newCanvas(self.w, self.h)
    self.canvas:setFilter("linear", "nearest")

    self.color_r = 0.2
    self.color_g = 0.2
    self.color_b = 0.2
    self.color_a = 1

    self.cameras_list = {}
    self.amount_cameras = 0

    self:add_camera(self.camera)
    self:add_camera(self.camera2)
end

function Screen:add_camera(camera)
    self.amount_cameras = self.amount_cameras + 1
    self.cameras_list[self.amount_cameras] = camera
end

function Screen:get_color()
    return self.color_r, self.color_g, self.color_b, self.color_a
end

function Screen:set_color(r, g, b, a)
    self.color_r = r or self.color_r
    self.color_g = g or self.color_g
    self.color_b = b or self.color_b
    self.color_a = a or self.color_a
end

function Screen:to_world(x, y)
    return to_world(self, x, y, self.camera)
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

    for i = 1, self.amount_cameras do
        ---@type JM.Camera.Camera
        local camera = self.cameras_list[i]
        camera:update(dt)
    end

    return r
end

function Screen:set_shader(shader)
    self.shader = shader
end

function Screen:draw()
    set_canvas(self.canvas)
    set_blend_mode("alpha")
    clear_screen(self:get_color())

    if self.background_draw then
        self.background_draw(self.background_draw_args)
    end

    for i = 1, self.amount_cameras do
        ---@type JM.Camera.Camera
        local camera = self.cameras_list[i]

        camera:attach()
        local r = self.draw_action and self.draw_action(self.draw_args)
        camera:detach()
    end

    if self.foreground_draw then
        self.foreground_draw(self.background_draw_args)
    end

    set_canvas()
    --============================================================
    -- love.graphics.setShader(self.shader)

    set_color_draw(1, 1, 1, 1)
    set_blend_mode("alpha", "premultiplied")

    push()
    scale(self.scale_x, self.scale_y)
    translate(self.x, self.y)
    love_draw(self.canvas)
    pop()

    set_shader()
end

return Screen

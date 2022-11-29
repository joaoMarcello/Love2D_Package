--[[
    This modules need the 'jm_camera.lua' to work.
]]

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

---@alias JM.Scene.Layer {draw:function, update:function, factor_x:number, factor_y:number, name:string, fixed_on_ground:boolean, fixed_on_ceil:boolean, top:number, bottom:number, shader:love.Shader}

local function round(value)
    local absolute = math.abs(value)
    local decimal = absolute - math.floor(absolute)

    if decimal >= 0.5 then
        return value > 0 and math.ceil(value) or math.floor(value)
    else
        return value > 0 and math.floor(value) or math.ceil(value)
    end
end

-- ---@param self JM.Scene
-- local function to_world(self, x, y, camera)
--     x = x / self.scale_x
--     y = y / self.scale_y

--     x = x - self.x
--     y = y - self.y

--     return x - camera.viewport_x, y - camera.viewport_y
-- end

---@param self  JM.Scene
local function draw_tile(self)
    local tile, qx, qy

    tile = self.tile_size_x * 4
    qx = (self.w - self.x) / tile
    qy = (self.h - self.y) / tile

    clear_screen(0.35, 0.35, 0.35, 1)
    set_color_draw(0.9, 0.9, 0.9, 0.3)
    for i = 0, qx, 2 do
        local x
        x = self.x + tile * i

        for j = 0, qy, 2 do
            love.graphics.rectangle("fill", x, tile * j, tile, tile)
            love.graphics.rectangle("fill", x + tile,
                tile * j + tile,
                tile, tile)
        end
        x = nil
    end
    tile, qx, qy = nil, nil, nil
end

---@class JM.Scene
---@field load function
---@field keypressed function
---@field keyreleased function
---@field mousepressed function
---@field mousereleased function
---@field mousefocus function
local Scene = {}

---@param self JM.Scene
---@return JM.Scene
function Scene:new(x, y, w, h, canvas_w, canvas_h)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Scene.__constructor__(obj, x, y, w, h, canvas_w, canvas_h)

    return obj
end

function Scene:__constructor__(x, y, w, h, canvas_w, canvas_h)

    -- the dispositive's screen dimensions
    self.dispositive_w = love.graphics.getWidth() - 153
    self.dispositive_h = love.graphics.getHeight() - 137

    -- the scene viewport coordinates
    self.x = x or 0
    self.y = y or 0

    -- the scene viewport dimensions
    self.w = w or self.dispositive_w
    self.h = h or self.dispositive_h

    -- the game's screen dimensions
    self.screen_w = canvas_w or self.w
    self.screen_h = canvas_h or self.h

    self.tile_size_x = 32
    self.tile_size_y = 32

    self.world_left = -32 * 0
    self.world_right = 32 * 60
    self.world_top = -32 * 10
    self.world_bottom = 32 * 25

    self.max_zoom = 3

    local config = {
        -- camera's viewport in desired game screen coordinates
        x = self.screen_w * 0,
        y = self.y,
        w = self.screen_w,
        h = self.screen_h,

        -- world bounds
        bounds = {
            left = self.world_left,
            right = self.world_right,
            top = self.world_top,
            bottom = self.world_bottom
        },

        -- Device screen's dimensions
        device_width = self.dispositive_w,
        device_height = self.dispositive_h,

        desired_canvas_w = self.screen_w,
        desired_canvas_h = self.screen_h,

        tile_size = self.tile_size_x,

        color = { 0.3, 0.3, 1, 0.5 },

        border_color = { 1, 1, 0, 1 },

        scale = 1,

        type = "metroid",

        show_grid = true,

        grid_tile_size = self.tile_size_x * 2,

        show_world_bounds = true
    }

    self.cameras_list = {}
    self.amount_cameras = 0
    self.camera_names = {}

    self.camera = self:add_camera(config, "main")

    self.n_layers = 0

    self:implements({})
end

---@param config table
---@param name string
function Scene:add_camera(config, name)
    assert(name, "\n>> Error: You not inform the Camera's name.")
    assert(not self.cameras_list[name], "\n>> Error: A camera with the name '" .. tostring(name) .. "' already exists!")
    assert(not self.cameras_list[self.amount_cameras + 1])

    local Camera
    ---@type JM.Camera.Camera
    Camera = require(string.gsub(path, "jm_scene", "jm_camera"))

    assert(Camera, [[
        >> Error: Camera module not found. Make sure the file 'jm_camera.lua' is in same directory.
        ]])

    if self.camera then
        config.device_width = self.camera.device_width
        config.device_height = self.camera.device_height

        config.desired_canvas_w = self.screen_w
        config.desired_canvas_h = self.screen_h

        config.bounds = {
            left = self.camera.bounds_left,
            right = self.camera.bounds_right,
            top = self.camera.bounds_top,
            bottom = self.camera.bounds_bottom
        }
    end

    local camera = Camera:new(config)


    self.amount_cameras = self.amount_cameras + 1

    camera.viewport_x = camera.viewport_x + self.x / camera.desired_scale
    camera.viewport_y = camera.viewport_y + self.y / camera.desired_scale

    self.cameras_list[self.amount_cameras] = camera

    self.cameras_list[name] = camera
    self.camera_names[self.amount_cameras] = name

    Camera = nil
    return camera
end

function Scene:get_color()
    return self.color_r, self.color_g, self.color_b, self.color_a
end

function Scene:set_color(r, g, b, a)
    self.color_r = r or self.color_r
    self.color_g = g or self.color_g
    self.color_b = b or self.color_b
    self.color_a = a or self.color_a
end

-- function Scene:create_layer(draw_order, factor, action)
--     local layer = {
--         draw_order = draw_order or (-1 - math.random()),
--         factor = factor or 0.5,
--         action = action
--     }

--     table.insert(self.layers, layer)
--     self.n_layers = self.n_layers + 1
--     table.sort(self.layers, function(a, b)
--         return a.drar_order < b.drar_order
--     end)
-- end

-- function Scene:to_world(x, y, camera)
--     return to_world(self, x, y, camera or self.camera)
-- end

---@return JM.Camera.Camera
function Scene:get_camera(index)
    return self.cameras_list[index] --or self.camera
end

---@return JM.Camera.Camera
function Scene:main_camera()
    return self.camera
end

---
---@param param {load:function, init:function, update:function, draw:function, unload:function, keypressed:function, keyreleased:function, layers:table}
---
function Scene:implements(param)
    assert(param, "\n>> Error: No parameter passed to method.")
    assert(type(param) == "table", "\n>> Error: The method expected a table. Was given " .. type(param) .. ".")

    local function generic(callback)
        return function(self, args)
            local r = callback and callback(args)
        end
    end

    local love_callbacks = {
        "load", "init", "keypressed", "keyreleased", "update", "draw",
        "unload", "wheelmoved", "mousefocus", "mousemoved", "mousepressed",
        "mousereleased", "gamepadaxis", "gamepadpressed", "gamepadreleased",
        "joystickadded", "joystickaxis", "joystickhat", "joystickpressed",
        "joystickreleased", "joystickremoved", "filedropped", "errorhandler",
        "quit", "visible", "textinput", "textedited", "threaderror",
        "displayrotated", "displayrotated"
    }

    for _, callback in ipairs(love_callbacks) do
        self[callback] = generic(param[callback])
    end

    if param.layers then
        self.n_layers = #(param.layers)

        for i = 1, self.n_layers, 1 do
            local layer    = param.layers[i]
            layer.x        = layer.x or 0
            layer.y        = layer.y or 0
            layer.factor_y = layer.factor_y or 0
            layer.factor_x = layer.factor_x or 0
        end
    end

    self.update = function(self, dt)

        if param.layers then
            for i = 1, self.n_layers, 1 do
                local layer

                ---@type JM.Scene.Layer
                layer = param.layers[i]

                if layer.update then layer.update(dt) end
            end
        end

        local r = param.update and param.update(dt)

        for i = 1, self.amount_cameras do
            local camera
            ---@type JM.Camera.Camera
            camera = self.cameras_list[i]
            camera:update(dt)
            camera = nil
        end
    end



    self.draw = function(self)
        -- love.graphics.setCanvas(self.canvas)
        -- love.graphics.setBlendMode("alpha")
        -- love.graphics.setColor(1, 1, 1, 1)

        love.graphics.setScissor(
            self.x,
            self.y,
            self.w - self.x,
            self.h - self.y
        )

        if self:get_color() then
            clear_screen(self:get_color())
        else
            draw_tile(self)
        end

        --=====================================================

        for i = 1, self.amount_cameras, 1 do
            local camera, r

            ---@type JM.Camera.Camera
            camera = self.cameras_list[i]

            love.graphics.setColor(camera:get_color())
            love.graphics.rectangle("fill",
                camera.viewport_x * camera.desired_scale,
                camera.viewport_y * camera.desired_scale,
                camera.viewport_w,
                camera.viewport_h
            )

            if param.layers then
                for i = 1, self.n_layers, 1 do
                    local layer

                    ---@type JM.Scene.Layer
                    layer = param.layers[i]

                    camera:attach()

                    camera:set_shader(layer.shader)

                    love.graphics.push()

                    local px = -camera.x * layer.factor_x * camera.scale
                    local py = -camera.y * layer.factor_y * camera.scale

                    if layer.fixed_on_ground and layer.top then
                        if py < layer.top then py = 0 end
                    end

                    if layer.fixed_on_ceil and layer.bottom then
                        if py > layer.bottom then py = 0 end
                    end

                    love.graphics.translate(round(px), round(py))

                    r = layer.draw and layer.draw(camera)

                    love.graphics.pop()

                    camera:detach()

                    camera:set_shader()

                end
            end

            if param.draw then
                camera:attach()
                r = param.draw and param.draw()
                camera:detach()
            end

            camera = nil
        end

        love.graphics.setScissor()

        -- love.graphics.setScissor(
        --     self.x,
        --     self.y,
        --     self.w - self.x,
        --     self.h - self.y
        -- )
        -- love.graphics.setCanvas()
        -- love.graphics.setColor(1, 1, 1, 1)
        -- love.graphics.setBlendMode("alpha", "premultiplied")
        -- love.graphics.draw(self.canvas)
        -- love.graphics.setCanvas()
        -- love.graphics.setBlendMode("alpha")
        -- love.graphics.setScissor()

    end
end

function Scene:set_background_draw(action)
    self.background_draw = action
end

function Scene:set_foreground_draw(action)
    self.foreground_draw = action
end

function Scene:set_shader(shader)
    self.shader = shader
end

return Scene

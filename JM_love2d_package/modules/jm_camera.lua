local function round(value)
    local absolute = math.abs(value)
    local decimal = absolute - math.floor(absolute)

    if decimal >= 0.5 then
        return value > 0 and math.ceil(value) or math.floor(value)
    else
        return value > 0 and math.floor(value) or math.ceil(value)
    end
end

local love_translate = love.graphics.translate
local love_pop = love.graphics.pop
local love_push = love.graphics.push
local love_scale = love.graphics.scale
local sin, cos, atan2, sqrt, abs = math.sin, math.cos, math.atan2, math.sqrt, math.abs


---@class JM.Camera.Camera
local Camera = {}

---@return JM.Camera.Camera
function Camera:new(x, y, w, h, scale)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Camera.__constructor__(obj, x, y, w, h, scale)

    return obj
end

function Camera:__constructor__(x, y, w, h, scale)

    self.viewport_x = 0
    self.viewport_y = 0
    self.viewport_w = w or love.graphics.getWidth()
    self.viewport_h = h or love.graphics.getHeight()

    self.x = x or 0
    self.y = y or 0

    self.scale = 1
    self.angle = 0

    ---@type {x:number, y:number, angle:number, distance:number, range_x:number, range_y:number, last_x:number, last_y:number}|nil
    self.target = nil

    self.offset_x = round(self.viewport_w * 0.25 * 1 / self.scale)
    self.offset_x = 0 --round(32 * 6 * 1 / self.scale)
    -- self.offset_x = 0
    self.offset_y = 0

    self.platform_box_w = 64 * 1 / self.scale

    self.bounds_left = -32 * 0
    self.bounds_top = -100
    self.bounds_right = 32 * 35
    self.bounds_bottom = self.viewport_h
    self:set_bounds()

    self.follow_speed_x = (32 * 8)
    self.follow_acc = 32 * 3

    self.lock_x = false
    self.lock_y = false

    self.debug = false
end

function Camera:set_viewport(x, y, w, h)
    self.viewport_x = x
    self.viewport_y = y
    self.viewport_w = w
    self.viewport_h = h
end

function Camera:to_camera(x, y)
    y = y or 0
    x = x / self.scale
    y = y / self.scale
    return x + self.x, y + self.y
end

function Camera:to_screen(x, y)
    y = y or 0
    x = x - self.x
    y = y - self.y

    return x * self.scale, y * self.scale
end

function Camera:lock_x_axis(value)
    self.lock_x = (value and true) or false
end

function Camera:lock_y_axis(value)
    self.lock_y = (value and true) or false
end

function Camera:lock_movements()
    self:lock_x_axis(true)
    self:lock_y_axis(true)
end

function Camera:unlock_movements()
    self:lock_x_axis(false)
    self:lock_y_axis(false)
end

function Camera:follow(x, y)
    if not self.target then self.target = {} end
    local target = self.target or {}

    x = x - self.offset_x / self.scale

    target.last_x = target.x or x
    target.last_y = target.y or y
    target.x = x
    target.y = y
    target.range_x = (x - target.last_x)
    target.range_y = (y - target.last_y)

    local target_distance_x = (target.x - self.x)
    local target_distance_y = 0 --self.target.y - self.y

    target.distance = sqrt(
        target_distance_x ^ 2 + target_distance_y ^ 2
    )

    target.angle = atan2(
        target_distance_y, target_distance_x
    )
end

function Camera:set_offset_x(value)
    if self.offset_x ~= value then
        if self.target then
            self.target.x = nil
        end
        self.offset_x = value
    end
end

function Camera:set_position(x, y)
    self.x = (not self.lock_x and (x and x)) or self.x
    self.y = (not self.lock_y and (y and y)) or self.y
end

function Camera:move(dx, dy)
    self:set_position(
        dx and self.x + dx or self.x,
        dy and self.y + dy or self.y
    )
end

function Camera:set_bounds(left, right, top, bottom)
    self.bounds_left = (left and left) or self.bounds_left
    self.bounds_right = (right and right) or self.bounds_right
    self.bounds_top = (top and top) or self.bounds_top
    self.bounds_bottom = (bottom and bottom) or self.bounds_bottom

    if self.bounds_right - self.bounds_left < self.viewport_w then
        self.bounds_right = self.bounds_left + self.viewport_w
    end

    if self.bounds_bottom - self.bounds_top < self.viewport_h then
        self.bounds_bottom = self.bounds_top + self.viewport_h
    end
end

function Camera:rect_is_on_screen(left, right, top, bottom)
    local left, top = self:to_camera(left, top)
    local right, bottom = self:to_camera(right, bottom)

    local cLeft, ctop = self:to_camera(self.x, self.y)
    local cright, cbottom = self:to_camera(
        self.x + (self.viewport_w / self.scale),
        self.y + self.viewport_h / self.scale
    )

    return (right >= cLeft and left <= cright)
        and (bottom >= ctop and top <= cbottom)
end

function Camera:point_is_on_screen(x, y)
    return self:rect_is_on_screen(x, x, y, y)
end

--- Side scrolling platform.
---@param camera JM.Camera.Camera
local function platform_update(camera, dt)
    local self = camera
    if self.target then
        if self.x ~= self.target.x then
            local cos_r = cos(self.target.angle)

            self:move(self.follow_speed_x * dt * cos_r)

            self:move(abs(self.target.range_x) * cos_r)

            local temp = self.follow_speed_x * dt * cos_r * 0.5

            if (cos_r > 0 and self.x + temp > self.target.x)
                or (cos_r < 0 and self.x + temp < self.target.x)
            then
                self:set_position(self.target.x)
            end

            self.x = round(self.x)
        end
    end
    -- local px = self:to_camera(32 * 20)
    -- if self:to_camera(self.x + self.offset_x) > px then
    --     self:set_position(self:to_screen(px - self.offset_x))
    --     self:lock_movements()
    -- end
end

---@param self JM.Camera.Camera
local function no_lerp_update(self, dt)
    if self.target then
        self.offset_x = self.viewport_w * 0.5
        self:set_position(self.target.x)
    end
end

function Camera:update(dt)
    platform_update(self, dt)
    -- no_lerp_update(self, dt)

    local left = self:to_camera(self.bounds_left)
    local right = self:to_camera(self.bounds_right - self.viewport_w / self.scale)
    local px = self:to_camera(self.x)

    if px < left then
        self:set_position(self:to_screen(left))
    elseif px > right then
        self:set_position(self:to_screen(right))
    end
end

function Camera:attach()
    love_push()
    love_scale(self.scale, self.scale)
    love_translate(-self.x, self.y)
end

local function rad2degr(value)
    return value * 180 / math.pi
end

local function deg2rad(value)
    return value * math.pi / 180
end

function Camera:detach()
    love_pop()

    if not self.debug then return end

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("distance: " .. tostring(self.target.distance), 10, 75)
    love.graphics.print("angle: " .. tostring(self.target.angle), 10, 95)
    love.graphics.print("angle deg: " .. tostring(rad2degr(self.target.angle)), 10, 110)
    love.graphics.print("t_speed_x: " .. tostring(self.target.range_x), 10, 125)
    love.graphics.print(tostring(math.cos(self.target.angle)), 100, 200)
    love.graphics.print("Scale: " .. tostring(self.scale), self.viewport_w - 100)
    love.graphics.print("Cam_X: " .. tostring(self.x), self.viewport_w - 100, 25)
    love.graphics.print("Cam_X2: " .. tostring(self:to_camera(self.x)), self.viewport_w - 100, 50)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("fill", self.offset_x, 0, 2, self.viewport_h)
    -- love.graphics.rectangle("fill", self.offset_x, 0, 2, self.viewport.h)
    -- love.graphics.rectangle("fill", self.offset_x, 0, 2, self.viewport.h)
end

return Camera

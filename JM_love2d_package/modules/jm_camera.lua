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
local sin, cos, atan2, sqrt = math.sin, math.cos, math.atan2, math.sqrt


---@class JM.Camera.Camera
local Camera = {}

---@return JM.Camera.Camera
function Camera:new(x, y, w, h, scale, global_scale)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Camera.__constructor__(obj, x, y, w, h, scale, global_scale)

    return obj
end

function Camera:__constructor__(x, y, w, h, scale, global_scale)

    self.viewport_x = 0
    self.viewport_y = 0
    self.viewport_w = w or love.graphics.getWidth()
    self.viewport_h = h or love.graphics.getHeight()

    self.x = x or 0
    self.y = y or 0

    self.global_scale = global_scale or 1

    self.scale = 1
    self.angle = 0

    ---@type {x:number, y:number, angle:number, distance:number, range_x:number, range_y:number, last_x:number, last_y:number}|nil
    self.target = nil

    self.offset_x = round(self.viewport_w * 0.25 * 1 / self.scale)
    self.offset_x = 0 --round(32 * 6 * 1 / self.scale)
    -- self.offset_x = 0
    self.offset_y = 0

    self.platform_box_w = 64 * 1 / self.scale

    self.bounds_left = 0
    self.bounds_top = -100
    self.bounds_right = 32 * 22
    self.bounds_bottom = self.viewport_h

    self.follow_speed_x = (32 * 8)
    self.follow_acc = 32 * 3

    self.debug = true
end

function Camera:set_viewport(x, y, w, h)
    self.viewport_x = x
    self.viewport_y = y
    self.viewport_w = w
    self.viewport_h = h
end

function Camera:to_camera(x, y)
    x, y = x - self.viewport_x, y - self.viewport_y
    x, y = x / self.global_scale, y / self.global_scale

    x = x / self.scale
    y = y / self.scale
    return x + self.x, y + self.y
end

function Camera:to_screen(x, y)
    x, y = x - self.x, y - self.y
    x, y = x * self.scale, y * self.scale

    return x, y
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
    self.x = (x and x) or self.x
    self.y = (y and y) or self.y
end

function Camera:move(dx, dy)
    self:set_position(
        dx and self.x + dx or self.x,
        dy and self.y + dy or self.y
    )
end

---@param camera JM.Camera.Camera
local function platform_update(camera, dt)
    local self = camera
    if self.target then
        if self.x ~= self.target.x then
            local cos_r = cos(self.target.angle)

            self:move((self.follow_speed_x) * dt * cos_r)

            self:move(math.abs(self.target.range_x) * cos_r)

            local temp = self.follow_speed_x * dt * cos_r * 0.5

            if (cos_r > 0 and self.x + temp > self.target.x)
                or (cos_r < 0 and self.x + temp < self.target.x)
            then
                self:set_position(self.target.x)
            end

            self.x = round(self.x)
        end
    end

end

function Camera:update(dt)
    platform_update(self, dt)

    if self.x < self.bounds_left then self.x = self.bounds_left end

    if self.x > self.bounds_right then
        self:set_position(self.bounds_right)
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

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("distance: " .. tostring(self.target.distance), 10, 75)
    love.graphics.print("angle: " .. tostring(self.target.angle), 10, 95)
    love.graphics.print("angle deg: " .. tostring(rad2degr(self.target.angle)), 10, 110)
    love.graphics.print("t_speed_x: " .. tostring(self.target.range_x), 10, 125)
    love.graphics.print(tostring(math.cos(self.target.angle)), 100, 200)
    love.graphics.print("Scale: " .. tostring(self.scale), self.viewport_w - 100)

    if not self.debug then return end
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("fill", self.offset_x, 0, 2, self.viewport_h)
    -- love.graphics.rectangle("fill", self.offset_x, 0, 2, self.viewport.h)
    -- love.graphics.rectangle("fill", self.offset_x, 0, 2, self.viewport.h)
end

return Camera

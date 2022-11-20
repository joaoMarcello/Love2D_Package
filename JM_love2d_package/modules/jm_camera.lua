---@class JM.Camera.Camera
local Camera = {}

local love_translate = love.graphics.translate
local love_pop = love.graphics.pop
local love_push = love.graphics.push

---@return JM.Camera.Camera
function Camera:new(x, y, w, h)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    Camera.__constructor__(obj, x, y, w, h)

    return obj
end

local function round(value)
    local absolute = math.abs(value)
    local decimal = absolute - math.floor(absolute)

    if decimal >= 0.5 then
        return value > 0 and math.ceil(value) or math.floor(value)
    else
        return value > 0 and math.floor(value) or math.ceil(value)
    end
end

function Camera:__constructor__(x, y, w, h)

    self.viewport = {
        x = x or 0,
        y = y or 0,
        w = w or love.graphics.getWidth(),
        h = h or love.graphics.getHeight()
    }

    self.x = 0
    self.y = 0
    local scale = 1
    self.scale_x = scale
    self.scale_y = scale
    self.angle = 0

    ---@type {x:number, y:number, angle:number, distance:number}|nil
    self.target = nil
    self.offset_x = round(self.viewport.w * 0.25 * 1 / self.scale_x)
    self.offset_y = 0

    self.bounds = {
        left = 0,
        top = -100,
        right = 3000,
        bottom = self.viewport.h
    }

    self.follow_speed = (32 * 8)

end

function Camera:follow(x, y)
    if not self.target then self.target = {} end
    local target = self.target or {}

    target.last_x = target.x or x
    target.last_y = target.y or y
    target.x = x
    target.y = y
    target.speed_x = (x - target.last_x)
    target.speed_y = (y - target.last_y)

    self.target_distance_x = (target.x - self.x)
    self.target_distance_y = 0 --self.target.y - self.y

    target.distance = math.sqrt(
        self.target_distance_x ^ 2 + self.target_distance_y ^ 2
    )

    target.angle = math.atan2(
        self.target_distance_y, self.target_distance_x
    )
end

local rad = 0
function Camera:update(dt)
    if self.target then
        if self.x ~= self.target.x then
            local cos_r = math.cos(self.target.angle)

            self.x = self.x
                + (self.follow_speed)
                * dt * cos_r

            self.x = self.x + self.target.speed_x

            if cos_r > 0 and self.x > self.target.x then
                self.x = self.target.x
            elseif cos_r < 0 and self.x < self.target.x then
                self.x = self.target.x
            end

            self.x = round(self.x)
        end
    end

    rad = rad + math.pi * dt

    -- self.offset_x = round(self.viewport.w * 0.25 + 25 * math.sin(rad))
end

function Camera:attach()
    love_push()
    love.graphics.scale(self.scale_x, self.scale_y)
    love_translate(-self.x + self.offset_x * self.scale_x, self.y)
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
    love.graphics.print("distance_x: " .. tostring(self.target_distance_x), 10, 60)
    love.graphics.print("distance: " .. tostring(self.target.distance), 10, 75)
    love.graphics.print("angle: " .. tostring(self.target.angle), 10, 95)
    love.graphics.print("angle deg: " .. tostring(rad2degr(self.target.angle)), 10, 110)
    love.graphics.print("t_speed_x: " .. tostring(self.target.speed_x), 10, 125)
    love.graphics.print(tostring(math.cos(self.target.angle)), 100, 200)
end

return Camera

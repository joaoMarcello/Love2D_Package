local JM_package = require("JM_love2d_package.init")
local Camera = JM_package.Camera

local main = {}

local function to_world(x, y)
    x, y = x - POS_X, y - POS_Y
    x, y = x / SCALE, y / SCALE
    return x, y
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

local player = {
    x = 600,
    y = 100,
    w = 30,
    h = 32,
    speed = 32 * 7,
    get_cx = function(self) return self.x + self.w / 2 end,
    get_cy = function(self) return self.y + self.h / 2 end,
    ---@param camera JM.Camera.Camera
    update = function(self, dt, camera)
        if love.keyboard.isDown("up") then
            self.y = self.y - self.speed * dt
        elseif love.keyboard.isDown("down") then
            self.y = self.y + self.speed * dt
        end

        if love.keyboard.isDown("left") then
            self.x = self.x - self.speed * dt
        elseif love.keyboard.isDown("right") then
            self.x = self.x + self.speed * dt
        end

        if self.x + self.w > camera.bounds_right then
            self.x = camera.bounds_right - self.w
        end

        if self.x < camera.bounds_left then
            self.x = camera.bounds_left
        end

        if self.y < camera.bounds_top then
            self.y = camera.bounds_top
        end

        if self.y + self.h > camera.bounds_bottom then
            self.y = camera.bounds_bottom - self.h
        end

        self.x, self.y = round(self.x), round(self.y)
    end,
    draw = function(self)
        love.graphics.setColor(1, 0, 0, 0.6)
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    end
}

function main:load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    main.camera = Camera:new(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    main.camera:set_focus_x(SCREEN_WIDTH * 0.5)
    main.camera:set_focus_y(SCREEN_HEIGHT * 0.2)
    main.camera:jump_to(player:get_cx() + 300, player:get_cy() + 100)
end

function main:update(dt)
    local camera = self.camera

    player:update(dt, camera)
    -- camera:follow(player:get_cx(), player:get_cy())
    camera:update(dt)
end

function main:draw()
    love.graphics.setColor(0.2, 0.33, 0.8, 1)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    local camera = main.camera
    camera:attach()

    player:draw()

    do
        love.graphics.setColor(0, 0, 0, 0.1)
        for i = 1, 300 do
            local x = -32 * 45 + 32 * (i - 1)
            love.graphics.line(x, 0, x, SCREEN_HEIGHT * 10)
        end

        for i = 1, 300 do
            love.graphics.line(-32 * 45, 32 * (i - 1), SCREEN_WIDTH * 3, 32 * (i - 1))
        end

        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.rectangle("fill", -300, camera.bounds_bottom - 2, 3000, 2)
        love.graphics.rectangle("fill", -300, camera.bounds_top, 3000, 2)
        love.graphics.rectangle("fill", camera.bounds_left, camera.bounds_top, 2, 3000)
        love.graphics.rectangle("fill", camera.bounds_right - 2, camera.bounds_top, 2, 3000)
    end

    camera:detach()
end

return main

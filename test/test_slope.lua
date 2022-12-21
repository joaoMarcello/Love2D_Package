local package = require("/JM_love2d_package/init")
local Scene = package.Scene
local Physics = package.Physics
local Font = package.Font

local Game = Scene:new()

local slope = {
    x = 300, y = 300,
    w = 200, h = 200,
    type = "floor",
    pt_1 = function(self)
        return self.x, self.x + self.h
    end,
    pt_2 = function(self)
        return self.x + self.w, self.y
    end,
    draw = function(self)
        local x1, y1 = self:pt_1()
        local x2, y2 = self:pt_2()

        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h)

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.line(x1, y1, x2, y2)
    end
}
do
    slope.A = function(self)
        local x1, y1 = slope:pt_1()
        local x2, y2 = slope:pt_2()
        y1, y2 = -y1, -y2

        return (y1 - y2) / (x1 - x2)
    end

    slope.B = function(self)
        local x1, y1 = slope:pt_1()
        y1 = -y1

        return y1 - slope:A() * x1
    end

    slope.get_coll_point = function(self, x, y, w, h)
        local px = x + w
        local py = -(y + h)
        return px, py
    end

    slope.check_up_down = function(self, x, y, w, h)
        local px, py = slope:get_coll_point(x, y, w, h)

        return py <= slope:A() * px + slope:B() and "DOWN" or "UP"
    end

    slope.collision_check = function(self, x, y, w, h)
        local rec_col = Physics.collision_rect(
            self.x, self.y, self.w, self.h,
            x, y, w, h
        )
        if not rec_col then return false end

        local pos = slope:check_up_down(x, y, w, h)
        return pos == "DOWN"
    end

    slope.get_y = function(self, x, w)
        x = x + w
        local py = -(slope:A() * x + slope:B())
        py = (py < slope.y and slope.y + 0.05) or py

        return py
    end
end

local player = {
    x = 0, y = 0, w = 64, h = 64 * 2, speed = 32 * 12,
    color = { 0.4, 0.2, 0.9, 0.8 },
    color_col = { 0.8, 0.3, 0.3, 1 },
}
do
    player.get_color = function(self)
        return slope:collision_check(player:rect()) and player.color_col or player.color
    end
    player.update = function(self, dt)

        local last_px = player.x

        if love.keyboard.isDown("left") then
            player.x = player.x - player.speed * dt
        elseif love.keyboard.isDown("right") then
            player.x = player.x + player.speed * dt
        end

        if last_px - player.x ~= 0 then
            local col = slope:collision_check(player:rect())

            if col then
                local py = slope:get_y(player.x, player.w)
                player.y = py - player.h
            end
        end

        if love.keyboard.isDown("up") then
            player.y = player.y - player.speed * dt
        elseif love.keyboard.isDown("down") then
            player.y = player.y + player.speed * dt

            local col = slope:collision_check(player:rect())
            if col then
                local py = slope:get_y(player.x, player.w)
                player.y = py - player.h
            end
        end
    end

    player.draw = function(self)
        love.graphics.setColor(player:get_color())
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
    end

    player.rect = function()
        return player.x, player.y, player.w, player.h
    end
end


local function load()

end

local function update(dt)
    player:update(dt)
end

local function draw()
    slope:draw()

    player:draw()

    Font:print(slope:check_up_down(player:rect()), 100, 100)
end

Game:implements({
    load = load,
    update = update,
    draw = draw
})
return Game

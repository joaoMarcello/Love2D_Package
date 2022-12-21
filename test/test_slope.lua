local package = require("/JM_love2d_package/init")
local Scene = package.Scene
local Physics = package.Physics
local Font = package.Font

local Game = Scene:new()

local slope = {
    x = 300, y = 300,
    w = 230, h = 200,
    type = "floor",
    direction = "normal_",
    pt_1 = function(self)
        if self.direction == "normal" then
            return self.x, self.y + self.h
        end
        return self.x, self.y
    end,
    pt_2 = function(self)
        if self.direction == "normal" then
            return self.x + self.w, self.y
        end
        return self.x + self.w, self.y + self.h
    end,
    draw = function(self)
        local x1, y1 = self:pt_1()
        local x2, y2 = self:pt_2()

        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h)

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.line(x1, y1, x2, y2)

        love.graphics.setColor(0.3, 1, 0.3, 0.5)

        if self.type == "floor" then
            love.graphics.polygon("fill", x1, y1, x2, y2,
                self.x + self.w,
                self.y + self.h,
                self.x, self.y + self.h
            )
        else
            love.graphics.polygon("fill", x1, y1, x2, y2,
                self.x + self.w,
                self.y,
                self.x, self.y
            )
        end
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
        local px, py
        if x and w then
            px = slope.type == "floor"
                and (slope.direction == "normal" and x + w) or x

            if slope.type ~= "floor" then
                px = slope.type ~= "floor"
                    and (slope.direction == "normal" and x) or (x + w)
            end
        end

        if y and h then
            py = (slope.type == "floor" and (y + h)) or y
            py = -py
        end
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

        local up_or_down = slope:check_up_down(x, y, w, h)

        return (slope.type == "floor" and up_or_down == "DOWN")
            or (slope.type ~= "floor" and up_or_down == "UP")
    end

    slope.get_y = function(self, x, y, w, h)
        x = self:get_coll_point(x, y, w, h)
        local py = -(slope:A() * x + slope:B())
        py = (py < slope.y and slope.y - 0.05) or py
        py = (py > slope.y + slope.h and slope.y + slope.h) or py

        return (slope.type == "floor" and py - h)
            or (slope.type ~= "floor" and py)
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

        local last_px, last_py = player.x, player.y

        if love.keyboard.isDown("left") then
            player.x = player.x - player.speed * dt
        elseif love.keyboard.isDown("right") then
            player.x = player.x + player.speed * dt
        end



        if love.keyboard.isDown("up") then
            player.y = player.y - player.speed * dt
        elseif love.keyboard.isDown("down") then
            player.y = player.y + player.speed * dt
        end

        if last_px - player.x ~= 0
            or last_py ~= player.y
        then
            local col = slope:collision_check(player:rect())

            if col then
                local py = slope:get_y(player:rect())
                player.y = py
            end
        end
    end

    player.draw = function(self)
        love.graphics.setColor(player:get_color())
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h)

        local x, y = slope:get_coll_point(self:rect())
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.circle("fill", x, -y, 5)
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

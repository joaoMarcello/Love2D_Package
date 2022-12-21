local package = require("/JM_love2d_package/init")
local Scene = package.Scene
local Physics = package.Physics

local Game = Scene:new()

local x, y, w, h, x1, x2, y1, y2, angle
local player = { x = 0, y = 0, w = 64, h = 64 * 2, speed = 32 * 5 }
do
    player.update = function(self, dt)
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
    end

    player.draw = function(self)
        love.graphics.setColor(0.4, 0.2, 0.9, 0.8)
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
    end
end


local function load()
    x, y = 300, 300
    w, h = 200, 200
    x1, y1 = x, y + h
    x2, y2 = x + w, y
end

local function update(dt)
    player:update(dt)
end

local function draw()
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("line", x, y, w, h)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.line(x1, y1, x2, y2)

    player:draw()
end

Game:implements({
    load = load,
    update = update,
    draw = draw
})
return Game

local Anima = require("/JM_love2d_package/init").Anima
local Physics = require("/JM_love2d_package/init").Physics

local Monica = {
    x = 0,
    y = -100,
    w = 28,
    h = 58,
    jump = false,
    speed_y = 0,
    gravity = (32 * 3.5) * 9.8,
    max_speed = 64 * 5,
    speed_x = 0,
    acc = 64 * 3,
    dacc = 64 * 10,
    direction = 1,
    get_cx = function(self)
        return self.x + self.w / 2
    end,
    get_cy = function(self)
        return self.y + self.h / 2
    end,
    rect = function(self)
        return self.x, self.y, self.w, self.h
    end
}

function Monica:load(world, x, y)
    self.body = Physics:newBody(world, x, y, self.w, self.h, "dynamic")
    self.body.max_speed_x = self.max_speed
    self.body.allowed_air_dacc = true
end

return Monica

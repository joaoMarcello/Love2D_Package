local Screen = require("/JM_love2d_package/modules/jm_screen")
local JM_package = require("/JM_love2d_package/JM_package")
local Anima = JM_package.Anima
local FontGenerator = JM_package.Font
local EffectManager = JM_package.EffectGenerator

local Consolas = FontGenerator:new({ name = "consolas", font_size = 14 })
Consolas:add_nickname_animated("--goomba--", {
    img = "/data/goomba.png",
    frames_list = { { 27, 85, 17, 89 },
        { 150, 209, 17, 89 },
        { 271, 331, 17, 89 },
        { 391, 460, 17, 88 },
        { 516, 579, 17, 89 },
        { 637, 695, 17, 88 },
        { 764, 821, 17, 89 },
        { 888, 944, 17, 88 },
        { 1006, 1070, 17, 88 }
    },
    duration = 1,
    is_reversed = false,
    state = "looping"
})

local function round(value)
    local absolute = math.abs(value)
    local decimal = absolute - math.floor(absolute)

    if decimal >= 0.5 then
        return value > 0 and math.ceil(value) or math.floor(value)
    else
        return value > 0 and math.floor(value) or math.ceil(value)
    end
end

local Game = Screen:new(0, 0, 1366 / 2, 768 / 2)
Game.scale_x = 1.7
Game.scale_y = Game.scale_x
-- local camera = Game.camera
-- camera:set_bounds(nil, nil, 200, 32 * 15)


local monica_idle_normal = Anima:new({
    img = "data/Monica/monica_idle_normal-Sheet.png",
    frames = 6,
    duration = 0.5,
    height = 64,
    ref_height = 64,
    amount_cycle = 2
})
local monica_run = Anima:new({
    img = "/data/Monica/monica-run.png",
    frames = 8,
    duration = 0.6,
    height = 64,
    ref_height = 64
})
local monica_idle_blink = Anima:new({
    img = "data/Monica/monica_idle_blink-Sheet.png",
    frames = 6,
    duration = 0.5,
    height = 64 * 1,
    ref_height = 64,
    amount_cycle = 1
})

local my_effect = EffectManager:generate_effect("idle", { color = { 0.9, 0.9, 0.9, 1 } })
local current_animation = monica_idle_normal
my_effect:apply(current_animation)

---@param new_anima JM.Anima
---@param last_anima JM.Anima
local function change_animation(new_anima, last_anima)
    if new_anima == last_anima then return end

    new_anima:reset()
    current_animation = new_anima
    current_animation:set_flip_x(last_anima:__is_flipped_in_x())
    my_effect:apply(new_anima, false)
    my_effect:update(love.timer.getDelta())
end

monica_idle_normal:set_custom_action(
---@param self JM.Anima
---@param param {idle_blink: JM.Anima}
    function(self, param)
        if self.__stopped_time > 0 then
            change_animation(param.idle_blink, self)
        end
    end,
    { idle_blink = monica_idle_blink }
)

monica_idle_blink:set_custom_action(
---@param self JM.Anima
---@param param {idle_normal: JM.Anima}
    function(self, param)
        if self.__stopped_time > 0 then
            param.idle_normal:set_max_cycle(love.math.random(2, 4))
            change_animation(param.idle_normal, self)
        end
    end,
    { idle_normal = monica_idle_normal }
)

local rec

local function collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2
        and x1 < x2 + w2
        and y1 + h1 > y2
        and y1 < y2 + h2
end

local rects = {
    { x = 0, y = 32 * 10, w = 32 * 30, h = 32 * 2 },
    { x = 32 * 16, y = 32 * 7, w = 32 * 4, h = 32 * 3 },
    { x = 32 * 20, y = 32 * 4, w = 32 * 4, h = 32 * 3 },
    { x = 32 * 24, y = 32 * 1, w = 32 * 4, h = 32 * 3 },
}

local function check_collision(x, y, w, h)
    for _, rec in ipairs(rects) do
        if collision(x, y, w, h, rec.x, rec.y, rec.w, rec.h) then
            return rec
        end
    end
end

Game:set_load_action(
    function()
        -- love.graphics.setDefaultFilter("nearest", "nearest")

        rec = {
            x = 450,
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
            accelerate = function(self, dt, acc, direction)
                if self.speed_x == 0 then
                    self.speed_x = 32 * direction
                end
                self.speed_x = self.speed_x + acc * dt * direction

                if math.abs(self.speed_x) > self.max_speed then
                    self.speed_x = self.max_speed * direction
                end
            end,
            run = function(self, dt, acc)
                if math.abs(self.speed_x) ~= 0 then
                    self.x = self.x
                        + (self.speed_x * dt + (acc * dt * dt) / 2)
                end
            end,
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
        rec.y = 0

        Game.camera:look_at(rec.x, rec.y)
        Game.camera:set_offset_x(32 * 8)
        Game.camera:set_offset_y(Game.camera.viewport_h * 0.3)
    end
)

Game:set_keypressed_action(
    function(key)
        if key == "space" then
            if not rec.jump then
                rec.jump = true
                rec.speed_y = -math.sqrt(2 * rec.gravity * 32 * 3.5)
            end
        end
    end
)

Game:set_update_action(
    function(dt)
        if love.keyboard.isDown("left")
            -- and rec.x > 0
            and rec.speed_x <= 0
        then
            rec.direction = -1
            rec:accelerate(dt, rec.acc, -1)
            rec:run(dt, rec.acc)

            change_animation(monica_run, current_animation)
            current_animation:set_flip_x(true)

            -- t.camera:set_offset_x(SCREEN_WIDTH - 32 * 8)

        elseif love.keyboard.isDown("right")
            -- and rec.x + rec.w < t.camera.bounds_right
            and rec.speed_x >= 0
        then
            rec.direction = 1
            rec:accelerate(dt, rec.acc, 1)
            rec:run(dt, rec.acc)

            change_animation(monica_run, current_animation)
            current_animation:set_flip_x(false)

            -- t.camera:set_offset_x(32 * 8)

        elseif math.abs(rec.speed_x) ~= 0 then
            local dacc = rec.dacc
                * ((love.keyboard.isDown("left") or love.keyboard.isDown("right"))
                    and 1.5 or 1)
            rec:accelerate(dt, dacc, rec.speed_x > 0 and -1 or 1)
            rec:run(dt, dacc)
            if rec.direction > 0 and rec.speed_x < 0 then rec.speed_x = 0 end
            if rec.direction < 0 and rec.speed_x > 0 then rec.speed_x = 0 end
        end

        rec.y = rec.y + rec.speed_y * dt + (rec.gravity * dt * dt) / 2
        rec.speed_y = rec.speed_y + rec.gravity * dt

        if rec.jump and rec.speed_y < 0 and not love.keyboard.isDown("space") then
            rec.speed_y = math.sqrt(2 * rec.gravity * 1)
        end

        if rec.y + rec.h > Game.camera.bounds_bottom then
            rec.y = Game.camera.bounds_bottom - rec.h
            rec.jump = nil
        end

        local obj
        local rx, ry, rw, rh = rec:rect()
        obj = rec.speed_y >= 0 and check_collision(rx, ry, rw, rh + 15)
        if obj then
            rec.y = obj.y - rec.h - 1
            rec.speed_y = 0
            rec.jump = false
            obj = nil
        end

        obj = rec.speed_x >= 0 and check_collision(rx, ry, rw + 3, rh)
        if obj then
            rec.x = obj.x - rec.w
            rec.speed_x = 0
            obj = nil
        end

        obj = rec.speed_x <= 0 and check_collision(rx - 3, ry, rw, rh)
        if obj then
            rec.speed_x = 0
            rec.x = obj.x + obj.w
            obj = nil
        end

        rec.x = round(rec.x)
        rec.y = round(rec.y)
        current_animation:update(dt)
        my_effect:apply(current_animation, false)
        Consolas:update(dt)

        Game.camera:follow(rec:get_cx(), rec:get_cy())

        if rec.x + rec.w > Game.camera.bounds_right then
            rec.x = Game.camera.bounds_right - rec.w
            rec.speed_x = 0
        end

        if rec.x < Game.camera.bounds_left then
            rec.x = Game.camera.bounds_left
            rec.speed_x = 0
        end
    end
)

Game:set_keyreleased_action(
    function(key)
        if key == "left" or key == "right" then
            if current_animation == monica_run then
                monica_idle_normal:set_flip_x(rec.direction < 0 and true)
                change_animation(monica_idle_normal, current_animation)
            end
        end
    end
)

local shadercode = [[
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    vec4 pix = Texel(texture, texture_coords);
    if (pix.a != 0){
        return vec4(0, 0, 1, 1);
    }
    else{
        return pix;
    }
}
  ]]

local shadercode2 = [[
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    vec4 pix = Texel(texture, texture_coords);
    if (pix.r == 1 && pix.g == 0 && pix.b == 1){
        return vec4(0, 0, 0, 0);
    }
    else{
        return pix;
    }
}
  ]]
local pink_to_none = love.graphics.newShader(shadercode2)

local myShader = love.graphics.newShader(shadercode)
local graph_set_color = love.graphics.setColor
local graph_rect = love.graphics.rectangle

local function index_to_string(i, j, axis)
    i, j = round(i), round(j)
    return tostring(i) .. " " .. tostring(j) .. " " .. axis
end

local tile = {}
tile.img = love.graphics.newImage("/data/groundTile.png")
tile.size = 50
tile.scale = 32 / 50
tile.global_q = love.graphics.newQuad(0, 0, 50, 50, tile.img:getWidth(), tile.img:getHeight())
tile.quads = {}
for i = 1, 4 do
    for j = 1, 4 do
        local index_x = index_to_string(i, j, "x")
        local index_y = index_to_string(i, j, "y")

        tile.quads[index_x] = (i - 1) * tile.size
        tile.quads[index_y] = (j - 1) * tile.size
    end
end

tile.draw = function(self, i, j, x, y)
    local quad = tile.global_q
    local index_x = index_to_string(i, j, "x")
    local index_y = index_to_string(i, j, "y")

    quad:setViewport(tile.quads[index_x], tile.quads[index_y], 50, 50, tile.img:getWidth(), tile.img:getHeight())

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.img, quad, x, y, 0, self.scale, self.scale, 0, 0)
end

Game:set_draw_action(
    function()
        do

            graph_set_color(245 / 255, 160 / 255, 151 / 255, 1)
            graph_rect("fill", 0, Game.h - 64 * 3, 64 * 4, 64 * 3)

            graph_set_color(142 / 255, 82 / 255, 82 / 255, 1)
            graph_rect("fill", 0, Game.h - 64 * 3, 64 * 1, 64 * 3)

            -- graph_set_color(20 / 255, 160 / 255, 46 / 255, 1)
            -- graph_rect("fill", 0, SCREEN_HEIGHT - 64, SCREEN_WIDTH, 64)

            -- graph_set_color(89 / 255, 193 / 255, 56 / 255, 1)
            -- graph_rect("fill", 0, SCREEN_HEIGHT - 64, SCREEN_WIDTH, 8)
        end

        graph_set_color(1, 0, 1, 0.9)
        graph_rect("line", rec.x, rec.y, rec.w, rec.h)

        current_animation:draw_rec(math.floor(rec.x), math.floor(rec.y), rec.w, rec.h)

        -- love.graphics.setShader(pink_to_none)

        for i = 1, 2 do
            for j = 0, 35 do
                if i == 1 and j == 0 then
                    tile:draw(1, 1, 0, Game.h - 32 * 2)
                elseif i == 2 and j == 0 then
                    tile:draw(1, 2, 0, Game.h - 32 * 1)
                elseif i == 1 then
                    local left = j * 32
                    local right = left + 32
                    local top = Game.h - 64 + 32 * (i - 1)
                    local bottom = top + 32
                    local result = Game.camera:rect_is_on_screen(left, right, top, bottom)

                    if j % 2 == 0 and result then
                        tile:draw(2, 1, j * 32, Game.h - 64 + 32 * (i - 1))
                    elseif result then
                        tile:draw(3, 1, j * 32, Game.h - 64 + 32 * (i - 1))
                    end
                elseif i == 2 then
                    if j % 2 == 0 then
                        tile:draw(2, 2, j * 32, Game.h - 64 + 32 * (i - 1))
                    else
                        tile:draw(3, 2, j * 32, Game.h - 64 + 32 * (i - 1))
                    end
                end
            end
        end

        graph_set_color(0, 0, 0, 0.5)
        graph_rect("fill", 32 * 34, 32 * 4, 32, 32)
        graph_rect("fill", 32 * 10, 32 * 4, 32, 32)

        graph_set_color(0, 0, 0, 0.1)
        for i = 1, 300 do
            local x = -32 * 45 + 32 * (i - 1)
            love.graphics.line(x, 0, x, Game.h * 50)
        end

        for i = 1, 100 do
            love.graphics.line(-32 * 1, 32 * (i - 1), Game.w * 50, 32 * (i - 1))
        end

        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.circle("fill", rec:get_cx(), rec:get_cy(), 130)
        love.graphics.setColor(1, 0, 1, 1)
        love.graphics.circle("fill", rec:get_cx(), rec:get_cy(), 128)
        current_animation:draw_rec(math.floor(rec.x), math.floor(rec.y), rec.w, rec.h)

        for i = 1, #rects do
            graph_set_color(1, 0.1, 0.1, 1)
            graph_rect("line", rects[i].x, rects[i].y, rects[i].w, rects[i].h)
            graph_set_color(0, 0, 0, 0)
            graph_rect("fill", rects[i].x, rects[i].y, rects[i].w, rects[i].h)
        end
    end
)

return Game

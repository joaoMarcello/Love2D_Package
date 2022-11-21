local JM_package = require("/JM_love2d_package/JM_package")
local Anima = JM_package.Anima
local FontGenerator = JM_package.Font
local EffectManager = JM_package.EffectGenerator
local Camera = JM_package.Camera

local t = {}
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

local monica_idle_normal = Anima:new({
    img = "data/Monica/monica_idle_normal-Sheet.png",
    frames = 6,
    duration = 0.5,
    height = 64,
    ref_height = 64,
    -- amount_cycle = 2
})

local my_effect = EffectManager:generate_effect("idle", { color = { 0.9, 0.9, 0.9, 1 } })

-- monica_idle_normal:apply_effect("ufo")

local monica_run = Anima:new({
    img = "/data/Monica/monica-run.png",
    frames = 8,
    duration = 0.6,
    height = 64,
    ref_height = 64
})
-- monica_run:apply_effect("flash")

-- monica_idle_normal:apply_effect("eight")

local monica_idle_blink = Anima:new({
    img = "data/Monica/monica_idle_blink-Sheet.png",
    frames = 6,
    duration = 0.5,
    height = 64 * 1,
    ref_height = 64,
    amount_cycle = 1
})

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

function t:load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    rec = {
        x = 450,
        y = SCREEN_HEIGHT - 120 - 64,
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
        end
    }
    rec.y = SCREEN_HEIGHT - rec.h - 64

    t.camera = Camera:new(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 1)
    t.camera:set_offset_x(32 * 8)
end

function t:keypressed(key)
    if key == "space" then
        if not rec.jump then
            rec.jump = true
            rec.speed_y = -math.sqrt(2 * rec.gravity * 32 * 3.5)
        end
    end
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

local function to_world(x, y)
    x, y = x - POS_X, y - POS_Y
    x, y = x / SCALE, y / SCALE
    return x, y
end

function t:update(dt)
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
        rec.speed_y = 0
    end

    if rec.speed_y > 0 and rec.y + rec.h + 5 >= SCREEN_HEIGHT - 64 then
        rec.y = SCREEN_HEIGHT - 64 - rec.h
        rec.speed_y = 0
        rec.jump = false
    end

    rec.x = round(rec.x)
    rec.y = round(rec.y)
    current_animation:update(dt)
    my_effect:apply(current_animation, false)
    Consolas:update(dt)


    t.camera:follow(rec:get_cx(), rec:get_cy())
    t.camera:update(dt)

    if rec.x + rec.w > t.camera.bounds_right then
        rec.x = t.camera.bounds_right - rec.w
        rec.speed_x = 0
    end

    if rec.x < t.camera.bounds_left then
        rec.x = t.camera.bounds_left
        rec.speed_x = 0
    end
end

function t:keyreleased(key)
    if key == "left" or key == "right" then
        if current_animation == monica_run then
            monica_idle_normal:set_flip_x(rec.direction < 0 and true)
            change_animation(monica_idle_normal, current_animation)
        end
    end
end

local shadercode = [[
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    vec4 c = Texel(texture, texture_coords); // This reads a color from our texture at the coordinates LOVE gave us (0-1, 0-1)
    return vec4(1.0, 0.0, 0.0, 1.0);
}
  ]]

local myShader = love.graphics.newShader(shadercode)
local graph_set_color = love.graphics.setColor
local graph_rect = love.graphics.rectangle

local tile = {}
tile.img = love.graphics.newImage("/data/groundTile.png")
tile.size = 50
tile.scale = 32 / 50
tile.quads = {}
for i = 1, 4 do
    tile.quads[i] = {}
    for j = 1, 4 do
        tile.quads[i][j] = love.graphics.newQuad(
            (i - 1) * tile.size,
            (j - 1) * tile.size,
            50, 50,
            tile.img:getWidth(),
            tile.img:getHeight()
        )
    end
end

tile.draw = function(self, i, j, x, y)
    local quad = tile.quads[i][j]
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.img, quad, x, y, 0, self.scale, self.scale, 0, 0)
end

function t:draw()
    graph_set_color(130 / 255, 221 / 255, 255 / 255)
    graph_rect("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    -- love.graphics.push()
    -- local value = -(rec.x) + math.floor(SCREEN_WIDTH * 0.25)
    -- love.graphics.translate(value, 0)
    t.camera:attach()

    do

        graph_set_color(245 / 255, 160 / 255, 151 / 255, 1)
        graph_rect("fill", 0, SCREEN_HEIGHT - 64 * 3, 64 * 4, 64 * 3)

        graph_set_color(142 / 255, 82 / 255, 82 / 255, 1)
        graph_rect("fill", 0, SCREEN_HEIGHT - 64 * 3, 64 * 1, 64 * 3)

        -- graph_set_color(20 / 255, 160 / 255, 46 / 255, 1)
        -- graph_rect("fill", 0, SCREEN_HEIGHT - 64, SCREEN_WIDTH, 64)

        -- graph_set_color(89 / 255, 193 / 255, 56 / 255, 1)
        -- graph_rect("fill", 0, SCREEN_HEIGHT - 64, SCREEN_WIDTH, 8)
    end

    -- love.graphics.setShader(myShader)
    current_animation:draw_rec(math.floor(rec.x), math.floor(rec.y), rec.w, rec.h)
    love.graphics.setShader()

    graph_set_color(1, 0, 1, 0.9)
    graph_rect("line", rec.x, rec.y, rec.w, rec.h)


    for i = 1, 2 do
        for j = 0, 35 do
            if i == 1 and j == 0 then
                tile:draw(1, 1, 0, SCREEN_HEIGHT - 32 * 2)
            elseif i == 2 and j == 0 then
                tile:draw(1, 2, 0, SCREEN_HEIGHT - 32 * 1)
            elseif i == 1 then
                local left = j * 32
                local right = left + 32
                local top = SCREEN_HEIGHT - 64 + 32 * (i - 1)
                local bottom = top + 32
                local result = t.camera:rect_is_on_screen(left, right, top, bottom)

                if j % 2 == 0 and result then
                    tile:draw(2, 1, j * 32, SCREEN_HEIGHT - 64 + 32 * (i - 1))
                elseif result then
                    tile:draw(3, 1, j * 32, SCREEN_HEIGHT - 64 + 32 * (i - 1))
                end
            elseif i == 2 then
                if j % 2 == 0 then
                    tile:draw(2, 2, j * 32, SCREEN_HEIGHT - 64 + 32 * (i - 1))
                else
                    tile:draw(3, 2, j * 32, SCREEN_HEIGHT - 64 + 32 * (i - 1))
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
        love.graphics.line(x, 0, x, SCREEN_HEIGHT)
    end

    for i = 1, 16 do
        love.graphics.line(-32 * 45, SCREEN_HEIGHT - 32 * (i - 1), SCREEN_WIDTH * 3, SCREEN_HEIGHT - 32 * (i - 1))
    end

    graph_set_color(1, 0, 0, 0.7)
    local mx, my = love.mouse.getPosition()
    mx, my = to_world(mx, my)
    mx, my = t.camera:to_camera(mx, my)
    love.graphics.rectangle("fill", mx, my, 32, 32)

    local mx2, my2 = love.mouse.getPosition()
    mx2, my2 = to_world(mx2, my2)
    mx2, my2 = t.camera:to_camera(mx2, my2)
    local point_on_screen = t.camera:rect_is_on_screen(mx2,
        mx2 + 32,
        my2,
        my2 + 32
    )

    t.camera:detach()


    Consolas:push()
    Consolas:set_font_size(14)
    Consolas:print("--goomba--Mônica and friends", 10, 10)
    local mp = tostring(love.mouse.getX()) .. " - " .. tostring(love.mouse.getY())
    Consolas:print(tostring(mp), 10, 40)
    Consolas:print(tostring(mx2) .. " - " .. tostring(my2), 100, 55)
    Consolas:print("p:" .. tostring(point_on_screen), 200, 100)
    Consolas:pop()
end

return t

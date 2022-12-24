local JM_package = require("/JM_love2d_package/init")
local Screen = JM_package.Scene
local Anima = JM_package.Anima
local FontGenerator = JM_package.FontGenerator
local EffectManager = JM_package.EffectManager
local Physics = JM_package.Physics

local Consolas = FontGenerator:new({
    name = "consolas",
    font_size = 12,
    tab_size = 4,
})

local text = "<color, 0.2, 0.2, 0.2> Caro senhor --a--rroz<italic>Potter,</italic> \n \n \tChegou ao conhecimento do Ministério que o senhor executou o <italic>feitiço do patrono</italic> na presença de um trouxa.\n \tSendo uma grave violação ao <italic>'Regulamento de Restrição à Prática de Magia por Menores',</italic> o senhor está expulso da <bold>Escola de Magia e Bruxaria de Hogwarts.\n \n \n </bold>\t\t\tEsperando que esteja bem,\n \t\t\t\t\t<italic>Mafalda Hopkins --goomba--</bold> "

local text2 = "\tAquele que\n h--a-- habita no <italic>esconderijo</italic> do altíssimo, <color>à <color, 0, 0, 1>sombra do <color, 0.7, 0.5, 0.1>onipotente</color> --goomba-- descansará\n \n \tDiz ao Senhor, meu refúgio e meu baluarte. Deus meu em quem confio.\n \n \tPois ele te livrará do <color, 0,0,1>laço do <color, 1, 0, 0>passarinheiro</color> e da peste perniciosa. Cobrir-te-á com suas penas e sob suas asas estarás seguro. Tua verdade é <bold>pavê e escudo.</bold>"

text = ""


local function round(value)
    local absolute = math.abs(value)
    local decimal = absolute - math.floor(absolute)

    if decimal >= 0.5 then
        return value > 0 and math.ceil(value) or math.floor(value)
    else
        return value > 0 and math.floor(value) or math.ceil(value)
    end
end

local Game = Screen:new(0, 0, nil, nil, 32 * 20, 32 * 12)

-- Game:add_camera({
--     -- camera's viewport
--     x = Game.screen_w * 0.5,
--     y = Game.screen_h * 0,
--     w = Game.screen_w * 0.5,
--     h = Game.screen_h * 0.5,

--     color = { 153 / 255, 217 / 255, 234 / 255, 1 },
--     scale = 0.6,

--     type = "metroid",
--     show_grid = true,
--     show_world_bounds = true
-- }, "blue")

-- Game:get_camera("main"):set_viewport(0, 0, Game.screen_w * 0.5, Game.screen_h)

-- Game:add_camera({
--     -- camera's viewport
--     x = Game.screen_w * 0.5,
--     y = Game.screen_h * 0.5,
--     w = Game.screen_w * 0.5,
--     h = Game.screen_h * 0.5,

--     color = { 255 / 255, 174 / 255, 201 / 255, 1 },
--     scale = 0.5,

--     type = "metroid",
--     show_grid = true,
--     grid_tile_size = 32 * 4,
--     show_world_bounds = true
-- }, "pink")

-- local temp
-- temp = Game:get_camera("main")
-- temp:shake_in_x(nil, temp.tile_size * 2 / 4, nil, 7.587)
-- temp:shake_in_y(nil, temp.tile_size * 2.34 / 4, nil, 10.7564)
-- temp = nil

local monica_idle_normal =
Anima:new(
    {
        img = "data/Monica/monica_idle_normal-Sheet.png",
        frames = 6,
        duration = 0.5,
        height = 64,
        ref_height = 64,
        -- amount_cycle = 2
    }
)

local monica_run =
Anima:new(
    {
        img = "/data/Monica/monica-run.png",
        frames = 8,
        duration = 0.6,
        height = 64,
        ref_height = 64
    }
)

local monica_idle_blink =
Anima:new(
    {
        img = "data/Monica/monica_idle_blink-Sheet.png",
        frames = 6,
        duration = 0.5,
        height = 64 * 1,
        ref_height = 64,
        amount_cycle = 1
    }
)

local my_effect = EffectManager:generate_effect("idle", { color = { 0.9, 0.9, 0.9, 1 } })
local current_animation = monica_idle_normal
my_effect:apply(current_animation)

-- monica_idle_normal:apply_effect("pulse")

---@param new_anima JM.Anima
---@param last_anima JM.Anima
local function change_animation(new_anima, last_anima)
    if new_anima == last_anima then
        return
    end

    new_anima:reset()
    current_animation = new_anima
    current_animation:set_flip_x(last_anima:is_flipped_in_x())
    my_effect:apply(new_anima, false)
    my_effect:update(love.timer.getDelta())
end

monica_idle_normal:on_event("pause",
    function()
        -- if monica_idle_normal.time_paused > 0 then
        change_animation(monica_idle_blink, monica_idle_normal)
        -- end
    end
)

monica_idle_blink:on_event("pause",
    function()
        -- if monica_idle_blink.time_paused > 0 then
        monica_idle_normal:set_max_cycle(love.math.random(2, 4))
        change_animation(monica_idle_normal, monica_idle_blink)
        -- end
    end
)


local shader_code_darken,
shadercode2,
pink_to_none,
myShader,
graph_set_color,
graph_rect,
index_to_string,
tile,
darken_shader

do
    shader_code_darken =
    [[
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

    shadercode2 =
    [[
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    vec4 pix = Texel(texture, texture_coords);
    if (pix.r == 1 && pix.g == 0 && pix.b == 1) {
        return vec4(0, 0, 0, 0);
    }
    return vec4(pix[0]*1.2, pix[1]*1.2, pix[2]*1.2, pix[3]);

    /*if (pix.r == 1 && pix.g == 0 && pix.b == 1){
        return vec4(1, 0, 0, 1);
    }
    else{
        return pix;
    }*/
}
  ]]
    pink_to_none = love.graphics.newShader(shadercode2)

    myShader = love.graphics.newShader(shader_code_darken)
    graph_set_color = love.graphics.setColor
    graph_rect = love.graphics.rectangle

    function index_to_string(i, j, axis)
        i, j = round(i), round(j)
        return tostring(i) .. " " .. tostring(j) .. " " .. axis
    end

    tile = {}
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
        local quad
        quad = tile.global_q
        local index_x = index_to_string(i, j, "x")
        local index_y = index_to_string(i, j, "y")

        quad:setViewport(tile.quads[index_x], tile.quads[index_y], 50, 50, tile.img:getWidth(), tile.img:getHeight())

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.img, quad, x, y, 0, self.scale, self.scale, 0, 0)
        quad = nil
    end

    shader_code_darken =
    [[
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    vec4 pix = Texel(texture, texture_coords);
    vec4 c = vec4(232.0/255.0, 229.0/225.0, 196.0/255.0, 1);
    c = vec4(1, 1, 1, 1);
    float af = 0.1;

    //return vec4(pix[0]*0.3, pix[1]*0.3, pix[2]*0.3, pix[3]);

    if (texture_coords[1] < 0.5){
        af = 0.5 - texture_coords[1];
        //af = af + 0.2 * (texture_coords[0]);
        af = af * 0.9;

        if (c[0]*af < 0 ){
            af = 0;
        }
        pix = vec4(pix[0]+c[0]*af, pix[1]+c[1]*af, pix[2]+c[2]*af, pix[3]);

        return pix;
    }
    else{
        af = 1;
        return vec4(pix[0]*af, pix[1]*af, pix[2]*af, pix[3]);
    }
}
  ]]
    darken_shader = love.graphics.newShader(shader_code_darken)
end
--=========================================================================

local rec

local function collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2 and x1 < x2 + w2 and y1 + h1 > y2 and y1 < y2 + h2
end

local rects = {
    { x = 0, y = 32 * 10, w = 32 * 30, h = 32 * 2 },
    { x = 32 * 16, y = 32 * 7, w = 32 * 4, h = 32 * 3 },
    { x = 32 * 20, y = 32 * 4, w = 32 * 4, h = 32 * 3 },
    { x = 32 * 24, y = 32 * 1, w = 32 * 4, h = 32 * 3 },
    { x = -2, y = Game.world_top, w = 1, h = Game.world_bottom - Game.world_top },
    { x = 0, y = Game.world_bottom, w = Game.world_right - Game.world_left, h = 2 }
}

local function check_collision(x, y, w, h)
    for _, rec in ipairs(rects) do
        if collision(x, y, w, h, rec.x, rec.y, rec.w, rec.h) then
            return rec
        end
    end
end

local ship
local obj, ground
---@type JM.Physics.World
local world
local components
local bb
local light_eff, day_light_eff

---@type JM.Anima
local moon_eff

---@type JM.Anima
local light_lines

---@type JM.Anima
local light_lines2

local goomba_anim = Anima:new({
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
    state = "looping",
    -- stop_at_the_end = true
})
goomba_anim:config_frame(1, {})
goomba_anim:on_event("pause", function()
    -- goomba_anim:set_color({ math.random(), math.random(), math.random(), 1 })
    -- goomba_anim:reset()
end)
goomba_anim:on_event("frame_change", function()
    local frame = goomba_anim.current_frame
    if frame == 1 then
        -- goomba_anim:set_color({ math.random(), math.random(), math.random(), 1 })
    elseif frame == 5 then
        -- goomba_anim:set_color({ 1, 0, 0, 1 })
        -- Game:pause(0.3)
    end
end)


local text3 = "\tAquele que\n h--a-- habita no <italic>esconderijo</italic> do altíssimo, <color>à <color, 0, 0, 1>sombra do <color, 0.7, 0.5, 0.1>onipotente</color> --goomba-- descansará\n \n \tDiz ao Senhor, meu refúgio e meu baluarte. Deus meu em quem confio.\n \n \tPois ele te livrará do <color, 0,0,1>laço do <color, 1, 0, 0>passarinheiro</color> e da peste perniciosa. Cobrir-te-á com suas penas e sob suas asas estarás seguro. Tua verdade é <bold>pavê e escudo.</bold>"
text3 = text3 .. text3 .. text3
--==========================================================================
Game:implements(
    {
        load = function()
            -- Game:set_shader(darken_shader)
            Game:set_color(43 / 255, 78 / 255, 108 / 255, 1)

            local sx = 1.2
            light_eff = Anima:new(
                {
                    img = "/data/light_effect.png",
                    scale = { x = sx, y = sx }
                }
            )
            light_eff:apply_effect("pulse", { range = 0.1, speed = 2 })
            -- light_eff:apply_effect("ghost", { min = 0.7, max = 1, speed = 3.5 })

            ---@type JM.Anima
            moon_eff = light_eff:copy()
            moon_eff:set_scale(1, 1)
            -- moon_eff:set_color({ r = 0.1, g = 0.1, b = 0.8, a = 0.7 })
            moon_eff:apply_effect("ghost", { min = 0.7, max = 1, speed = 10 })

            day_light_eff =
            Anima:new(
                {
                    img = "/data/day_light_effect.png",
                    scale = { x = 14, y = 5 }
                }
            )
            -- day_light_eff:apply_effect("stretchVertical", { speed = 2, range = 0.05 })
            day_light_eff:apply_effect("ghost", { min = 0.1, max = 0.2, speed = 10 })

            light_lines = Anima:new({
                img = "/data/light_line.png",
                scale = { x = 1.8, y = 1.8 }
            })
            light_lines:set_color({ a = 0.6 })
            light_lines:apply_effect("clockWise", { speed = 20 })

            light_lines2 = light_lines:copy()
            light_lines2:set_scale(2.2, 2.2)
            light_lines2:set_color({ a = 0.2 })
            light_lines2:apply_effect("clockWise", { speed = 40 })

            Game:set_foreground_draw(
                function()
                    day_light_eff:update(love.timer.getDelta())
                    love.graphics.setBlendMode("add")
                    day_light_eff:draw_rec(0, 0, Game.dispositive_w, Game.dispositive_h * 0.3)
                    love.graphics.setBlendMode("alpha")
                end
            )

            components = {}

            world = Physics:newWorld()

            local ball = {
                speed = -64 * 1,
                time = 0
            }
            ball.body = Physics:newBody(world, 32 * 3 + 10, 0, 16, 16, "dynamic")
            ball.draw = function(self)
                love.graphics.setColor(0.9, 0.2, 0.3, 1)
                local x, y, w, h = ball.body:rect()
                -- x, y = round(x), round(y)
                love.graphics.rectangle("fill", x, y, w, h)
            end
            ball.body.bouncing_y = 0.5
            ball.body.bouncing_x = 1
            ball.body.speed_x = -64 * 1
            ball.body.acc_x = 0
            ball.body.dacc_x = 0 --32 * 5
            ball.body.allowed_air_dacc = false
            ball.update = function(self, dt)
                ball.time = ball.time + dt
                if ball.time >= 1.5 then
                    ball.time = ball.time - 1.5
                    ball.body:jump(32 / 4)
                end
            end
            ball.body:on_event(
                "axis_x_collision",
                function()
                    ball.body:jump(32 / 4)
                end
            )

            components[ball] = true


            obj = {
                acc = -32 * 4,
                speed = -math.sqrt(2 * 32 * 4 * 32)
            }
            obj.body = Physics:newBody(world, 32 * 5, 32 * 2, 32, 64, "kinematic")
            obj.body.id = "box"
            obj.draw = function(self)
                local body
                ---@type JM.Physics.Body
                body = self.body
                love.graphics.setColor(0.6, 0.8, 0.1, 1)
                love.graphics.rectangle("fill", body:rect())
                body = nil
            end
            obj.body:set_mass(obj.body.mass)
            obj.update = function(self, dt)
                -- if obj.body.y < 32 * 3 then
                --     obj.body:refresh(nil, 32 * 3)
                --     obj.speed = -obj.speed
                -- end
                -- obj.body.speed_y = obj.speed
            end
            obj.body:on_event("ground_touch",
                function()
                    -- obj.body:jump(32 * 2)
                end
            )

            components[obj] = true




            local rampa = {}
            rampa.body = Physics:newSlope(world, 32 * 14, 32 * 7, 32 * 2, 32 * 3, "normal")
            rampa.draw = function()
                -- rampa.body:A()
                rampa.body:draw()
            end

            components[rampa] = true




            ground = {}
            ground.body = Physics:newBody(world, 0, 32 * 10, 32 * 30, 32 * 2, "static")
            ground.draw = function(self)
                love.graphics.setColor(0.4, 0.4, 0.7, 1)
                love.graphics.rectangle("fill", self.body:rect())
            end

            for _, rect in ipairs(rects) do
                local block = {
                    body = Physics:newBody(world, rect.x, rect.y, rect.w, rect.h, "static"),
                    draw = function(self)
                        love.graphics.setColor(0.1, 0.4, 0.5)
                        love.graphics.rectangle("fill", self.body:rect())
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.rectangle("line", self.body:rect())
                    end
                }
                -- components[block] = true
            end

            bb = {}
            bb.body = Physics:newBody(world, 32 * 10, 32 * 6, 32, 32, "static")
            bb.draw = function(self)
                love.graphics.setColor(0.1, 0.4, 0.5)
                love.graphics.rectangle("fill", self.body:rect())
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("line", self.body:rect())
            end
            components[bb] = true

            -- love.graphics.setDefaultFilter("nearest", "nearest")
            ship = {
                x = 0,
                y = 32 * 8,
                w = 64,
                h = 32,
                spx = 0,
                spy = 0,
                acc = 32 * 20,
                rad = 0,
                fspeed = 1,
                max_speed = function(self)
                    return math.sqrt(2 * self.acc * 32 * 6)
                end,
                move = function(self, dt)
                    if love.keyboard.isDown("a") then
                        self.spx = self.spx - self.acc * dt
                    elseif love.keyboard.isDown("d") then
                        self.spx = self.spx + self.acc * dt
                    else
                        local direction = self.spx / math.abs(self.spx)
                        self.spx = self.spx + self.acc * dt * -direction
                        if direction ~= self.spx / math.abs(self.spx) then
                            self.spx = 0
                        end
                    end

                    if love.keyboard.isDown("w") then
                        self.spy = self.spy - self.acc * dt
                    elseif love.keyboard.isDown("s") then
                        self.spy = self.spy + self.acc * dt
                    else
                        local direction = self.spy / math.abs(self.spy)
                        self.spy = self.spy + self.acc * dt * -direction
                        if direction ~= self.spy / math.abs(self.spy) then
                            self.spy = 0
                        end
                    end

                    if math.abs(self.spx) >= self:max_speed() then
                        self.spx = self:max_speed() * ((self.spx / math.abs(self.spx)) < 0 and -1 or 1)
                    end

                    if self.spx ~= 0 then
                        self.x = self.x + self.spx * dt + self.acc * dt * dt / 2
                    end
                    if self.spy ~= 0 then
                        self.y = self.y + self.spy * dt + self.acc * dt * dt / 2
                    end

                    if self.x <= Game.world_left then
                        self.spx = 0
                        self.x = Game.world_left
                    end

                    if self.x + self.w >= Game.world_right then
                        self.spx = 0
                        self.x = Game.world_right - self.w
                    end

                    if self.y <= Game.world_top then
                        self.spy = 0
                        self.y = Game.world_top
                    end

                    if self.y + self.h >= Game.world_bottom then
                        self.spy = 0
                        self.y = Game.world_bottom - self.h
                    end
                end,
                update = function(self, dt)
                    self:move(dt)

                    self.rad = self.rad + (math.pi * 2) / self.fspeed * dt
                end,
                draw = function(self)
                    love.graphics.setColor(1, 0, 0, 0.8)
                    love.graphics.rectangle(
                        "fill",
                        round(self.x),
                        round(self.y) + 10 * math.cos(self.rad),
                        self.w,
                        self.h
                    )
                end,
                get_cx = function(self)
                    return self.x + self.w * 0.5
                end,
                get_cy = function(self)
                    return self.y + self.h / 2
                end
            }

            rec = {
                x = 0,
                y = -100,
                w = 28,
                h = 58,
                body = Physics:newBody(world, 32 * 2, 32 * 7, 28, 58, "dynamic"),
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
            rec.body.max_speed_x = rec.max_speed
            rec.body.allowed_air_dacc = true
            -- rec.body.mass = rec.body.mass * 1.5
            rec.body:on_event("ground_touch",
                function()
                    -- rec.body.mass = world.default_mass

                    -- current_animation:set_color({ math.random(), math.random(), math.random(), 1 })

                    -- if rec.body.speed_y > 180 then
                    --     Game:main_camera():shake_in_y(0.05, 5, 0.2, 0.1)
                    -- end
                end
            )
            rec.body:on_event(
                "speed_x_change_direction",
                function()
                    -- Game:main_camera():shake_in_y(0.05, 5, 0.2, 0.1)
                end
            )
            rec.body:on_event(
                "start_falling",
                function()
                    -- rec.body.mass = world.default_mass * 0.2

                    -- current_animation:set_color({ math.random(), math.random(), math.random(), 1 })
                    -- rec.body.speed_y = 200 * 2
                end
            )
            rec.body:on_event(
                "leaving_ground",
                function()
                    -- rec.body.speed_y = 0
                    -- rec.body:jump(32 * 3.5)
                end
            )
            rec.body:on_event("axis_x_collision", function()
                -- rec.body.speed_y = 0
                -- rec.body:jump(32 * 1)
            end)
            rec.body:on_event("leaving_x_axis_body", function()
                -- rec.body.speed_y = 0
                -- rec.body:jump(32 * 8)
            end)
            rec.update = function(self, dt)
                local rbody
                ---@type JM.Physics.Body
                rbody = rec.body

                if love.keyboard.isDown("left")
                    and rbody.speed_x <= 0
                then
                    rec.direction = -1
                    rbody:apply_force(-rec.acc)

                    change_animation(monica_run, current_animation)
                    current_animation:set_flip_x(true)

                    local col =
                    rbody.ground and
                        rbody:check(
                            rbody.x - 5,
                            nil,
                            function(obj, item)
                                return item.id == "box"
                            end
                        )

                    if col and col.n > 0 then
                        ---@type JM.Physics.Body
                        local box = col.items[1]
                        -- box:apply_force(-32 * 7)
                        box.speed_x = -32 * 3
                        rbody:refresh(box:right())
                    end
                elseif love.keyboard.isDown("right")
                    and rbody.speed_x >= 0
                then
                    rec.direction = 1
                    rbody:apply_force(rec.acc)

                    change_animation(monica_run, current_animation)
                    current_animation:set_flip_x(false)

                    local col =
                    rbody.ground and
                        rbody:check(
                            rbody.x + 5,
                            nil,
                            function(obj, item)
                                return item.id == "box"
                            end
                        )

                    if col and col.n > 0 then
                        ---@type JM.Physics.Body
                        local box = col.items[1]
                        -- box:apply_force(32 * 7)
                        box.speed_x = 32 * 3
                        rbody:refresh(box.x - rbody.w)
                    end
                elseif math.abs(rbody.speed_x) ~= 0 then
                    local dacc = rec.dacc *
                        ((love.keyboard.isDown("left") or love.keyboard.isDown("right")) and 1.5 or 1)
                    rbody.dacc_x = dacc
                end

                if love.keyboard.isDown("up") then
                    rbody:apply_force(nil, -rbody:weight())
                    rbody.speed_y = 0
                else
                    rbody.acc_y = 0
                end

                if not love.keyboard.isDown("space") and rbody.speed_y < 0 then
                    -- and rbody.speed_y > -math.sqrt(2 * rbody:weight() * 32)
                    rbody:apply_force(nil, rbody:weight() * 2.5)
                end

                if rbody.ground and love.keyboard.isDown("down") then
                    rec.last_y = rbody.ground.y
                    rbody:jump(32 / 4)
                    rbody:extra_collisor_filter(
                        function(obj, item)
                            return item.y ~= rec.last_y
                        end
                    )
                elseif rbody.ground then
                    rbody:remove_extra_filter()
                end

                if rbody:bottom() > Game.world_bottom then
                    rbody:refresh(nil, Game.world_bottom - rec.h)
                    -- rec.jump = false
                    rbody.speed_y = 0
                    rec.jump = false
                end

                if rbody.speed_y == 0 or true then
                    rec.jump = false
                else
                    rec.jump = true
                end

                if rbody:right() > Game.world_right then
                    rbody:refresh(Game.world_right - rec.w)
                    rec.speed_x = 0
                end

                if rbody:left() <= Game.world_left then
                    rbody:refresh(Game.world_left)
                    rec.speed_x = 0
                end

                rec.x = round(rbody.x)
                rec.y = round(rbody.y)

                current_animation:update(dt)
            end

            components[rec] = true

            Game.camera:jump_to(ship.x, ship.y)
            Game.camera:set_position(0, 0)

            if Game:get_camera("blue") then
                Game:get_camera("blue"):jump_to(ship:get_cx(), ship:get_cy())
            end

            if Game:get_camera("pink") then
                Game:get_camera("pink"):jump_to(rec:get_cx(), rec:get_cy())
            end
        end,

        update = function(dt)
            world:update(dt)

            goomba_anim:update(dt)

            for c in pairs(components) do
                local r = c.update and c:update(dt)
            end

            local cam1, cam_blue, cam_pink
            cam1, cam_blue = Game:get_camera(1), Game:get_camera("blue")
            cam_pink = Game:get_camera("pink")

            ship:update(dt)



            -- local obj
            -- local rx, ry, rw, rh = rec:rect()
            -- obj = rec.speed_y >= 0 and check_collision(rx, ry, rw, rh + 15)
            -- if obj then
            --     if rec.speed_y > math.sqrt(2 * rec.gravity * 3) then
            --         -- cam1:shake_in_y(0.05, 3, 0.2, 0.1)
            --         -- local r = cam_blue and cam_blue:shake_in_y(0.05, 3, 0.2, 0.1)
            --         -- r = cam_pink and cam_pink:shake_in_y(0.05, 3, 0.2, 0.1)
            --     end

            --     rec.y = obj.y - rec.h - 1
            --     rec.speed_y = 0

            --     rec.jump = false
            --     obj = nil
            -- end

            -- my_effect:apply(current_animation, false)

            if love.keyboard.isDown("up") and false then
                cam1:follow(rec:get_cx(), rec:get_cy() - 32 * 3, "up monica")
            else
                cam1:follow(rec:get_cx(), rec:get_cy(), "monica")
            end

            if cam_pink then
                cam_pink:follow(ship:get_cx(), ship:get_cy())
            end

            if cam_blue then
                cam_blue:follow(ship:get_cx(), ship:get_cy())
            end

            cam1, cam_blue, cam_pink = nil, nil, nil
        end,

        keypressed = function(key)
            if key == "space" then
                local h = math.abs(rec.body.speed_x) >= rec.body.max_speed_x and 4.5 or 3.5
                rec.body:jump(32 * h)
            end

            if key == "s" then
                if love.keyboard.isDown("left") then
                    rec.body:dash(32 * 5, -1)
                else
                    rec.body:dash(32 * 5, 1)
                end
            end

            if key == "p" then
                Game:pause(1)
            end

            if key == "f" then
                Game:set_frame_skip(3, 1.5, function()
                    local dt = love.timer.getDelta()
                    -- world:update(love.timer.getDelta())
                    -- rec:update(love.timer.getDelta())
                    -- Game:main_camera():update(dt)
                end)
            end

            if key == "g" then
                Game:turn_off_frame_skip()
                current_animation:set_color({ math.random(), math.random(), math.random(), 1 })
            end
        end,

        keyreleased = function(key)
            if key == "left" or key == "right" then
                if current_animation == monica_run then
                    monica_idle_normal:set_flip_x(rec.direction < 0 and true)
                    change_animation(monica_idle_normal, current_animation)
                end
            end
        end,

        layers = {
            -- MOON
            {
                draw = function()
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.circle("fill", 199, 44, 28)

                    -- moon_eff:update(love.timer.getDelta())
                    -- love.graphics.setBlendMode("add")
                    -- local r = moon_eff and moon_eff:draw(200, 45)
                    -- love.graphics.setBlendMode("alpha")
                end,
                factor_x = -1,
                factor_y = -1
            },

            {
                draw = function()
                    love.graphics.setColor(0.2, 0, 0.1, 1)
                    for i = 1, 10 * 20, 10 do
                        love.graphics.rectangle("fill", 10 * (i), 32, 56, 32 * 9)
                    end
                end,
                factor_x = 0.2 / 5,
                factor_y = 0.1,
                fixed_on_ground = true,
                -- fixed_on_ceil = true,
                bottom = 32 * 9,
                top = 32,
                name = "violet rect"
            },

            -- Green rectangles
            {
                draw = function()
                    love.graphics.setColor(0, 0.4, 0.1, 1)
                    for i = 1, 50, 4 do
                        love.graphics.rectangle("fill", 32 * (i), 0, 32, 32 * 10)
                    end
                end,
                factor_x = 0.2,
                factor_y = 0.2,
                -- fixed_on_ceil = true,
                fixed_on_ground = true,
                bottom = 32 * 10,
                top = 0,
                name = "green rect"
            },

            {
                draw = function()
                    -- love.graphics.setShader(pink_to_none)
                    do
                        graph_set_color(245 / 255, 160 / 255, 151 / 255, 1)
                        graph_rect("fill", 0, 32 * 12 - 64 * 3, 64 * 4, 64 * 3)

                        graph_set_color(142 / 255, 82 / 255, 82 / 255, 1)
                        graph_rect("fill", 0, 32 * 12 - 64 * 3, 64 * 1, 64 * 3)
                    end

                    graph_set_color(1, 0, 1, 0.9)
                    graph_rect("line", rec.x, rec.y, rec.w, rec.h)

                    for i = 1, #rects do
                        graph_set_color(1, 0.1, 0.1, 1)
                        graph_rect("line", rects[i].x, rects[i].y, rects[i].w, rects[i].h)
                        graph_set_color(0.5, 0.1, 0.9, 1)
                        graph_rect("fill", rects[i].x, rects[i].y, rects[i].w, rects[i].h)
                    end

                    for i = 1, 2 do
                        for j = 0, 35 do
                            if i == 1 and j == 0 then
                                tile:draw(1, 1, 0, 32 * 12 - 32 * 2)
                            elseif i == 2 and j == 0 then
                                tile:draw(1, 2, 0, 32 * 12 - 32 * 1)
                            elseif i == 1 then
                                local left = j * 32
                                local right = left + 32
                                local top = Game.h - 64 + 32 * (i - 1)
                                local bottom = top + 32
                                local result = Game.camera:rect_is_on_screen(left, right, top, bottom) or true

                                if j % 2 == 0 and result then
                                    tile:draw(2, 1, j * 32, 32 * 12 - 64 + 32 * (i - 1))
                                elseif result then
                                    tile:draw(3, 1, j * 32, 32 * 12 - 64 + 32 * (i - 1))
                                end
                            elseif i == 2 then
                                if j % 2 == 0 then
                                    tile:draw(2, 2, j * 32, 32 * 12 - 64 + 32 * (i - 1))
                                else
                                    tile:draw(3, 2, j * 32, 32 * 12 - 64 + 32 * (i - 1))
                                end
                            end
                        end
                    end

                    graph_set_color(0, 0, 0, 0.5)
                    graph_rect("fill", 32 * 34, 32 * 4, 32, 32)
                    graph_rect("fill", 32 * 10, 32 * 4, 32, 32)

                    for b in pairs(components) do
                        local r = b.draw and b:draw()
                    end

                    -- love.graphics.setColor(0.1, 0.1, 0.1, 1)
                    -- love.graphics.circle("fill", rec:get_cx(), rec:get_cy(), 32 * 2 + 2)
                    -- love.graphics.setColor(1, 0, 1, 1)
                    -- love.graphics.circle("fill", rec:get_cx(), rec:get_cy(), 32 * 2)

                    -- love.graphics.circle("fill", rec:get_cx(), rec:get_cy(), 32 * 3)

                    ship:draw()

                    -- graph_set_color(1, 0, 0, 0.7)
                    -- local mx, my = love.mouse.getPosition()
                    -- mx, my = Game:to_world(mx, my, Game:get_camera(3))
                    -- mx, my = Game:get_camera(3):screen_to_world(mx, my)
                    -- love.graphics.rectangle("fill", mx, my, 32, 32)

                    -- love.graphics.setShader()
                end,
                factor_x = 0,
                factor_y = 0,
                -- shader = pink_to_none,

                name = "main background"
            },
            {
                name = "Light",
                rad = 0.5,
                alpha = 1,
                update = function(self, dt)
                    self.rad = self.rad + (math.pi * 2) / 1 * dt
                    self.alpha = 0.3 * math.sin(self.rad * 2)
                    self.alpha = 0.1
                    light_eff:update(dt)
                    light_lines:update(dt)
                    light_lines2:update(dt)
                end,
                draw = function(self)
                    ---@type JM.Anima
                    local anim = light_eff

                    -- love.graphics.setBlendMode("add")
                    -- light_lines2:draw(rec:get_cx(), rec:get_cy())
                    -- light_lines:draw(rec:get_cx(), rec:get_cy())
                    -- anim:draw(rec:get_cx(), rec:get_cy())
                    -- love.graphics.setBlendMode("alpha")

                end
            },

            {
                draw = function()
                    current_animation:draw_rec(round(rec.x), round(rec.y), rec.w, rec.h)
                    -- Consolas:print(tostring(getmetatable(current_animation)), rec.x, rec.y - 35)
                end,
                name = "player"
            },

            {
                draw = function(self)
                    obj:draw()
                    -- ground:draw()
                end,
                name = "physics bodies"
            }
        },

        draw = function()
            Consolas:printf(text, 20, 20, "left", 300)
            goomba_anim:draw(300, 200)
            Consolas:printf("Oi eu sou o Goku.", 20, 100, "center", 200)
            -- Consolas:print(tostring(getmetatable(goomba_anim)), 300, 200 - 35)
            -- Consolas:printf(text3, 10, 150, "left", Game.screen_w)
        end
    }
)

Game:set_background_draw(
    function()
        -- love.graphics.setColor(0, 0, 1, 1)
        -- love.graphics.rectangle("fill", 0, 0, Game.w, Game.h)
    end
)

return Game

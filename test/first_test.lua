local Anima = require "/JM_love2d_package/animation_module"
local EffectGenerator = require("/JM_love2d_package/effect_generator_module")
local FontGenerator = require("/JM_love2d_package/modules/jm_font")
local Phrase = require("/JM_love2d_package/modules/font/Phrase")
local Word = require("/JM_love2d_package/modules/font/Word")
local Camera = require("/Camera")

local t = {}

local monica_idle_normal = Anima:new({
    img = "data/Monica/monica_idle_normal-Sheet.png",
    frames = 6,
    duration = 0.5,
    height = 64 * 1,
    ref_height = 64,
    amount_cycle = 2
})
-- monica_idle_normal:apply_effect("jelly")
-- monica_idle_normal:apply_effect("ufo")

local monica_run = Anima:new({
    img = "/data/Monica/monica-run-dust.png",
    frames = 8,
    duration = 0.6,
    height = 64 * 1,
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

monica_idle_normal:set_custom_action(
---@param self JM.Anima
---@param param {idle_blink: JM.Anima}
    function(self, param)
        if self.__stopped_time > 0 then
            param.idle_blink:reset()
            current_animation = param.idle_blink
            current_animation:set_flip_x(self:__is_flipped_in_x())
        end
    end,
    { idle_blink = monica_idle_blink }
)

monica_idle_blink:set_custom_action(
---@param self JM.Anima
---@param param {idle_normal: JM.Anima}
    function(self, param)
        if self.__stopped_time > 0 then
            param.idle_normal:reset()
            param.idle_normal:set_max_cycle(love.math.random(2, 4))
            current_animation = param.idle_normal
            current_animation:set_flip_x(self:__is_flipped_in_x())
        end
    end,
    { idle_normal = monica_idle_normal }
)

local rec

local camera
function t:load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    -- love.graphics.setBackgroundColor(0.1, 0.1, 0.1, 1)
    -- love.graphics.setBackgroundColor(130 / 255., 221 / 255., 255 / 255.)
    -- love.graphics.setBackgroundColor(20 / 255., 52 / 255., 100 / 255.)
    rec = {
        x = SCREEN_WIDTH * 0.25,
        y = SCREEN_HEIGHT - 120 - 64,
        w = 28,
        h = 58
    }
    rec.y = SCREEN_HEIGHT - rec.h - 64

    camera = Camera(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    camera:setFollowLerp(0.2)
    camera:setFollowLead(0)
    camera:setFollowStyle("PLATFORMER")
end

function t:keypressed(key)

end

local direction = 1
function t:update(dt)
    local speed = 64 * 3
    if love.keyboard.isDown("left") and rec.x > 0 then
        direction = -1
        rec.x = rec.x - speed * dt
        current_animation = monica_run
        current_animation:set_flip_x(true)
    elseif love.keyboard.isDown("right") and rec.x + rec.w < SCREEN_WIDTH then
        direction = 1
        rec.x = rec.x + speed * dt
        current_animation = monica_run
        current_animation:set_flip_x(false)
    end

    current_animation:update(dt)
    camera:update(dt)
    camera:follow(rec.x, rec.y)
end

function t:keyreleased(key)
    if key == "left" or key == "right" then
        if current_animation == monica_run then
            monica_idle_normal:set_flip_x(direction < 0 and true)
            current_animation = monica_idle_normal
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

function t:draw()
    -- camera:attach()
    do
        love.graphics.setColor(130 / 255, 221 / 255, 255 / 255)
        love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

        -- love.graphics.setColor(245 / 255, 160 / 255, 151 / 255, 1)
        -- love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 64 - 64 * 5, 64 * 4, 64 * 5)

        -- love.graphics.setColor(142 / 255, 82 / 255, 82 / 255, 1)
        -- love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 64 - 64 * 5, 64 * 1, 64 * 5)

        love.graphics.setColor(20 / 255, 160 / 255, 46 / 255, 1)
        love.graphics.rectangle("fill", 0, SCREEN_HEIGHT - 64, SCREEN_WIDTH, 64)

        love.graphics.setColor(89 / 255, 193 / 255, 56 / 255, 1)
        love.graphics.rectangle("fill", 0, SCREEN_HEIGHT - 64, SCREEN_WIDTH, 8)
    end

    -- love.graphics.setShader(myShader)
    current_animation:draw_rec(math.floor(rec.x), math.floor(rec.y), rec.w, rec.h)
    love.graphics.setShader()

    love.graphics.setColor(1, 0, 1, 0.6)
    love.graphics.rectangle("line", rec.x, rec.y, rec.w, rec.h)

    -- camera:detach()
end

return t

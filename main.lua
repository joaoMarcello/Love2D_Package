local scene = require("/test/game_test")

function love.load()
    -- love.mouse.setVisible(false)
    -- love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setBackgroundColor(0, 0, 0, 1)
    scene:load()
end

function love.keypressed(key)
    local r = scene.keypressed and scene:keypressed(key)
end

function love.keyreleased(key)
    local r = scene.keyreleased and scene:keyreleased(key)
end

function love.update(dt)
    if love.keyboard.isDown("q") or love.keyboard.isDown("escape") then
        love.event.quit()
    end

    local r = scene.update and scene:update(dt)
end

function love.draw()
    local r = scene.draw and scene:draw()
end

-- local utf8 = require("utf8")
-- local current_test = require("/test/first_test")

-- local canvas

-- local set_canvas = love.graphics.setCanvas
-- local grap_clear = love.graphics.clear
-- local set_blend_mode = love.graphics.setBlendMode
-- local grap_set_color = love.graphics.setColor
-- local grap_draw = love.graphics.draw

-- -- SCREEN_WIDTH = 320 * 2
-- -- SCREEN_HEIGHT = 160 * 2
-- SCREEN_WIDTH = 1366 / 2
-- SCREEN_HEIGHT = 768 / 2

-- function love.load()
--     -- love.mouse.setVisible(false)
--     love.graphics.setDefaultFilter("nearest", "nearest")
--     love.graphics.setBackgroundColor(0.4, 0.4, 0.4, 1)

--     local r = current_test.load and current_test:load()

--     canvas = love.graphics.newCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
-- end

-- function love.keypressed(key)
--     local r = current_test.keypressed and current_test:keypressed(key)
-- end

-- function love.update(dt)
--     if love.keyboard.isDown("q") or love.keyboard.isDown("escape") then
--         love.event.quit()
--     end

--     local r = current_test.update and current_test:update(dt)
-- end

-- function love.keyreleased(key)
--     local r = current_test.keyreleased and current_test:keyreleased(key)
-- end

-- local scale = love.graphics.getHeight() / (SCREEN_HEIGHT)
-- scale = 1.55
-- local pos_y = math.floor(love.graphics.getHeight() / 2 - SCREEN_HEIGHT * scale / 2)
-- local pos_x = math.floor(love.graphics.getWidth() / 2 - SCREEN_WIDTH * scale / 2)

-- pos_x, pos_y = 300, 75
-- SCALE = scale
-- POS_X = pos_x
-- POS_Y = pos_y

-- local shadercode = [[
--     vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
-- {
--     vec4 pix = Texel(texture, texture_coords);
--     if ( (pix.r == 1 && pix.g == 0 && pix.b == 1) || (pix.r == 1 && pix.g == 1 && pix.b == 0)){
--         return vec4(0, 0, 0, 0);
--     }
--     else{
--         return pix;//return vec4(pix[0]*0.3, pix[1]*0.3, pix[2]*0.3, 1);
--     }
-- }
--   ]]
-- local my_shader = love.graphics.newShader(shadercode)

-- function love.draw()

--     love.graphics.setColor(130 / 255, 221 / 255, 255 / 255)
--     love.graphics.rectangle("fill", pos_x, pos_y, SCREEN_WIDTH * SCALE, SCREEN_HEIGHT * SCALE)

--     set_canvas(canvas)
--     grap_clear(0, 0, 0, 0)

--     -- love.graphics.setColor(1, 1, 0, 1)
--     -- love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH * SCALE, SCREEN_HEIGHT * SCALE)

--     set_blend_mode("alpha")

--     local r = current_test.draw and current_test:draw()

--     set_canvas()
--     -----------------------------------------------------------------------

--     love.graphics.setShader(my_shader)

--     grap_set_color(1, 1, 1, 1)
--     set_blend_mode("alpha", "premultiplied")
--     grap_draw(canvas,
--         pos_x,
--         pos_y,
--         0,
--         scale, scale)

--     love.graphics.setShader()
-- end

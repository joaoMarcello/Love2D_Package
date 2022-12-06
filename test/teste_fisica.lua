local Scene = require("/JM_love2d_package/modules/jm_scene")
local JM_package = require("/JM_love2d_package/JM_package")
local Anima = JM_package.Anima
local FontGenerator = JM_package.Font
local EffectManager = JM_package.EffectGenerator
local Physics = require("/JM_love2d_package/modules/jm_physics")

local Game = Scene:new()

local player
---@type JM.Physics.World
local world

local components

Game:implements({
    load = function()
        components = {}

        world = Physics:newWorld()

        player = {
            body = Physics:newBody(world, 64, 0, 25, 25, "dynamic"),
            acc = 32 * 8,
            max_speed = 32 * 7,

            update = function(self, dt)
                local body
                ---@type JM.Physics.Body
                body = self.body

                -- if love.keyboard.isDown("down") then
                --     body.acc_y = self.acc
                -- elseif love.keyboard.isDown("up") then
                --     body.acc_y = -self.acc
                -- else
                --     body.speed_y = 0
                --     body.acc_y = 0
                -- end

                if love.keyboard.isDown("left") then
                    body.acc_x = -self.acc
                elseif love.keyboard.isDown("right") then
                    body.acc_x = self.acc
                elseif body.speed_x ~= 0 then
                    body.acc_x = body.speed_x > 0 and (-self.acc * 2) or self.acc * 5
                else
                    body.acc_x = 0
                end
            end,

            keypressed = function(self, key)
                if key == "space" then
                    self.body:jump(32 * 2)
                end
            end,

            draw = function(self)
                love.graphics.setColor(0.4, 0.4, 1)
                love.graphics.rectangle("fill", self.body:rect())
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("line", self.body:rect())
            end
        }
        -- player.body.acc_y = 0

        for i = 0, 0 do
            local block = {
                body = Physics:newBody(world, 128 + 32, 64 * 5, 32 * 4, 10, "static"),
                draw = function(self)
                    love.graphics.setColor(0.1, 0.4, 0.5)
                    love.graphics.rectangle("fill", self.body:rect())
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.rectangle("line", self.body:rect())
                end
            }
            components[block] = true
        end

        local block = {
            body = Physics:newBody(world, 128, 64 * 4, 32 * 4, 64, "static"),
            draw = function(self)
                love.graphics.setColor(0.1, 0.4, 0.5)
                love.graphics.rectangle("fill", self.body:rect())
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("line", self.body:rect())
            end
        }

        world.debug.block = block
        components[block] = true

        components[player] = true

        Game.count_cells = world:count_Cells()
    end,

    keypressed = function(key)
        player:keypressed(key)
    end,

    update = function(dt)
        world:update(dt)

        for component, _ in pairs(components) do
            local r = component.update and component:update(dt)
        end
    end,

    draw = function(self)
        for c, _ in pairs(components) do
            local r = c.draw and c:draw()
        end

        love.graphics.setColor(1, 1, 0, 1)
        local cells = world:count_Cells()
        love.graphics.print("Quant. Cells: " .. tostring(cells), 200, 50)

        local cl, ct, cw, ch = world:rect_to_cell(player.body:rect())

        love.graphics.print("left - " ..
            cl .. ", right - " .. cw .. ", top: " ..
            ct .. ", bottom: " .. ch, 200, 80)

        love.graphics.print(tostring(world.debug.block.body.x), 200, 100)
    end
})

return Game

local package = require("/JM_love2d_package/init")
local Scene = package.Scene
local Physics = package.Physics
local Font = package.Font
local GUI = package.GUI

local Game = Scene:new()

local button_1 = GUI.Button:new({
    x = 200, y = 100, w = 100, h = 50
})

Game:implements({
    draw = function()
        button_1:draw()
    end
})

return Game

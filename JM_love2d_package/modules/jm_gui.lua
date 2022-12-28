---@type string
local path = ...
path = path:gsub("jm_gui", "")

---@type JM.GUI.Button
local Button = require(path .. "gui.button")

---@class JM.GUI
local GUI = {}

GUI.Button = Button

return GUI

local path = (...)

local JM = {}

---@type JM.Anima
JM.Anima = require(string.gsub(path, "init", "modules.jm_animation"))

---@type JM.Font.Font
JM.Font = require(string.gsub(path, "init", "modules.jm_font"))

---@type JM.EffectManager
JM.EffectManager = require(string.gsub(
    path, "init", "modules.jm_effect_manager"
))

---@type JM.Camera.Camera
JM.Camera = require(string.gsub(path, "init", "modules.jm_camera"))

---@type JM.Scene
JM.Scene = require(string.gsub(path, "init", "modules.jm_scene"))

---@type JM.Physics
JM.Physics = require(string.gsub(path, "init", "modules.jm_physics"))

---@type JM.Affectable
JM.Affectable = require(string.gsub(path, "init", "modules.templates.Affectable"))

return JM

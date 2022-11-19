local path = (...)

local JM = {}

---@type JM.Anima
JM.Anima = require(string.gsub(path, "JM_package", "modules.jm_animation"))

---@type JM.Font.Font
JM.Font = require(string.gsub(path, "JM_package", "modules.jm_font"))

---@type JM.EffectManager
JM.EffectGenerator = require(string.gsub(
    path, "JM_package", "modules.classes.EffectManager"
))

return JM

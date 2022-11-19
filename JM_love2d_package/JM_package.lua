local path = (...)

local JM = {}

JM.Anima = require(string.gsub(path, "JM_package", "modules.jm_animation"))
JM.Font = require(string.gsub(path, "JM_package", "modules.jm_font"))
JM.EffectGenerator = require(string.gsub(
    path, "JM_package", "modules.classes.EffectManager"
))

return JM

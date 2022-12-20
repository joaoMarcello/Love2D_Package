local EffectManager = require("JM_love2d_package.modules.jm_effect_manager")

local EffectGenerator = {}

--- Get a specific Effect object by his name.
---@param effect_type JM.Effect.id_string
---@param args any
---@return JM.Effect
function EffectGenerator:generate(effect_type, args)
    return EffectManager:generate_effect(effect_type, args)
end

return EffectGenerator

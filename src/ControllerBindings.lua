-- Stable numeric IDs stored by Mod Settings. Append new choices; never reorder.
local M = {default = 0, values = {}}
local keys = {
    'Gamepad_FaceButton_Right', -- 0: B / Circle
    'Gamepad_FaceButton_Bottom', -- 1: A / Cross
    'Gamepad_FaceButton_Left', -- 2: X / Square
    'Gamepad_FaceButton_Top', -- 3: Y / Triangle
    'Gamepad_LeftShoulder', -- 4: LB / L1
    'Gamepad_RightShoulder', -- 5: RB / R1
    'Gamepad_LeftTrigger', -- 6: LT / L2 (digital)
    'Gamepad_RightTrigger', -- 7: RT / R2 (digital)
    'Gamepad_LeftThumbstick', -- 8: Left stick click / L3
    'Gamepad_RightThumbstick', -- 9: Right stick click / R3
    'Gamepad_DPad_Up', -- 10: D-pad Up
    'Gamepad_DPad_Down', -- 11: D-pad Down
    'Gamepad_DPad_Left', -- 12: D-pad Left
    'Gamepad_DPad_Right', -- 13: D-pad Right
}
local ids = {}
for index, key in ipairs(keys) do
    M.values[index] = index - 1
    ids[key] = index - 1
end
function M.key(id) return keys[id + 1] end
function M.id(key) return ids[key] end
return M

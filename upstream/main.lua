-- Gather nearby harvestables on demand through UHarvestableComponent:StartInteraction.
-- Tweak settings in the config.lua file.

local UEHelpers = require("UEHelpers")

local MOD_NAME = "TBODAutoGather"
-- FindAllOf form
local HARVESTABLE_CLASS = "Harvestable"
-- EInteractableState.Interactable is the only state the prompt accepts
local STATE_INTERACTABLE = 4

-- 1 Unreal Unit = 1cm; 200u = 2m
local UU_PER_M = 100

-- Settings-related values
local DEFAULT_RADIUS_M = 50.0
local MIN_RADIUS_M = 1.0
local MAX_RADIUS_M = 50.0
local DEFAULT_GATHER_KEY = "O"

---@param message string
local function log(message)
    print(string.format("[%s] %s\n", MOD_NAME, message))
end

-- Settings ---------------------------------------------------------------

---@class AutoGatherSettings
---@field radius_uu number gather radius in Unreal Units
---@field gather_key string UE4SS Key table entry

---@param config table?
---@return AutoGatherSettings settings, string? problem
local function load_settings(config)
    local problems = {}
    local radius_value = nil
    local key_value = nil

    if config ~= nil then
        radius_value = config.GatherRadiusMeters
        key_value = config.GatherKey
    end

    ---@param value any raw value from config
    ---@param min number lower bound
    ---@param max number upper bound
    ---@param default number fallback
    ---@param key string config key for messages
    ---@return number picked value
    local function pick_number(value, min, max, default, key)
        if type(value) ~= "number" then
            if value ~= nil then
                problems[#problems + 1] = key .. ": expected number"
            end
            return default
        end

        if value < min then
            problems[#problems + 1] = key .. " clamped to " .. tostring(min)
            return min
        end

        if value > max then
            problems[#problems + 1] = key .. " clamped to " .. tostring(max)
            return max
        end

        return value
    end

    local radius_m = pick_number(
        radius_value,
        MIN_RADIUS_M,
        MAX_RADIUS_M,
        DEFAULT_RADIUS_M,
        "GatherRadiusMeters"
    )

    local gather_key = DEFAULT_GATHER_KEY
    if type(key_value) == "string" and Key[key_value] ~= nil then
        gather_key = key_value
    elseif key_value ~= nil then
        problems[#problems + 1] = "GatherKey invalid; using " .. DEFAULT_GATHER_KEY
    end

    local problem = nil
    if #problems > 0 then
        problem = " " .. table.concat(problems, ", ")
    end

    return {
        radius_uu = math.floor(radius_m * UU_PER_M),
        gather_key = gather_key,
    }, problem
end

local config_ok, config = pcall(require, "config")
if not config_ok then
    config = nil
end

local settings, config_problem = load_settings(config)
local RADIUS_UU = settings.radius_uu
local GATHER_KEY_NAME = settings.gather_key
local GATHER_KEY = Key[GATHER_KEY_NAME]

local controller = nil ---@type UObject? cached, the lookup walks all controllers

---@param a table position with X/Y/Z
---@param b table position with X/Y/Z
---@return number squared distance in square Unreal Units
local function dist2(a, b)
    local dx = a.X - b.X
    local dy = a.Y - b.Y
    local dz = a.Z - b.Z
    return dx * dx + dy * dy + dz * dz
end

---@return UObject? cached controller, re-resolved when invalid
local function resolve_controller()
    if controller ~= nil and controller:IsValid() then
        return controller
    end

    local player_controller = UEHelpers.GetPlayerController()
    if player_controller ~= nil and player_controller:IsValid() then
        controller = player_controller
        return controller
    end

    return nil
end


---@param actor UObject harvestable actor in radius
---@return UObject? comp eligible component, or nil
---@return string|nil itemName item name when eligible
local function eligible_comp(actor)
    -- Only use genuine HarvestableComponents.
    -- LootableComponents are intentionally ignored so the mod cannot
    -- automatically pick up owned/stolen world loot.
    local comp = actor.HarvestableComponent

    if comp == nil or not comp:IsValid() then
        return nil
    end

    -- InteractionState is userdata
    if tonumber(tostring(comp:GetInteractionState())) ~= STATE_INTERACTABLE then
        return nil
    end

    if comp:IsInteractionEnabled() ~= true then
        return nil
    end

    local item = comp.HarvestableConfig.Item
    if item == nil or not item:IsValid() then
        return nil
    end

    return comp, item:GetFullName()
end

---@param comp UObject gathered component
---@param itemName string
---@param d2 number squared distance at selection time
local function gather(comp, itemName, d2)
    comp:StartInteraction()

    local dist = math.sqrt(d2)
    if tonumber(tostring(comp:GetInteractionState())) ~= STATE_INTERACTABLE then
        log(string.format("Gathered %s at %.0fu", itemName, dist))
    end
end

-- Gathers every eligible harvestable currently inside the configured radius.
-- Resolve a fresh list on every key press so stale UObject references from
-- streaming, save loads, or map transitions cannot break future gathers.
local function gather_nearby()
    ExecuteInGameThread(function()
        local player_controller = resolve_controller()
        if player_controller == nil then
            log("No player controller found")
            return
        end

        local pawn = player_controller.Pawn
        if pawn == nil or not pawn:IsValid() then
            log("No player pawn found")
            return
        end

        local playerLoc = pawn:K2_GetActorLocation()
        local radius2 = RADIUS_UU * RADIUS_UU
        local gathered = 0
        local skipped = 0

        local actors = FindAllOf(HARVESTABLE_CLASS) or {}

        for _, actor in ipairs(actors) do
            if actor ~= nil and actor:IsValid() then
                local ok_loc, actorLoc = pcall(function()
                    return actor:K2_GetActorLocation()
                end)

                if ok_loc and actorLoc ~= nil then
                    local d2 = dist2(playerLoc, actorLoc)

                    if d2 <= radius2 then
                        local ok_eligible, comp, itemName = pcall(eligible_comp, actor)

                        if ok_eligible and comp ~= nil then
                            local ok_gather = pcall(gather, comp, itemName, d2)
                            if ok_gather then
                                gathered = gathered + 1
                            else
                                skipped = skipped + 1
                            end
                        elseif not ok_eligible then
                            skipped = skipped + 1
                        end
                    end
                else
                    skipped = skipped + 1
                end
            end
        end

        log(string.format(
            "Gather key pressed: gathered %d harvestable(s) within %.1fm; skipped %d stale/invalid object(s)",
            gathered,
            RADIUS_UU / UU_PER_M,
            skipped
        ))
    end)
end

if config_problem ~= nil then
    log("config.lua issues (defaults used):" .. config_problem)
end

RegisterKeyBind(GATHER_KEY, gather_nearby)

log(string.format(
    "Loaded v1.1.0 (radius %.1fm, press %s to gather nearby harvestables)",
    RADIUS_UU / UU_PER_M,
    GATHER_KEY_NAME
))

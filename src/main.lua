-- Based on Toggleable Auto Gather by Tic0311, script v1.1.0.
-- Keeps original HarvestableComponent eligibility and StartInteraction behavior.
local MOD_NAME, HARVESTABLE_CLASS = "TBODAutoGather", "Harvestable"
local STATE_INTERACTABLE, UU_PER_M = 4, 100
local function log(message) print("["..MOD_NAME.."] "..message.."\n") end
local ok, config = pcall(require, "config")
if not ok or type(config) ~= 'table' then
    log('config.lua could not be read; using defaults.')
    config = {}
end
local function number(value, fallback, minimum, maximum, name)
    if value == nil then return fallback end
    if type(value) ~= 'number' or value ~= value or value == math.huge or value == -math.huge then
        log(name..' is invalid; using '..fallback)
        return fallback
    end
    if value < minimum or value > maximum then
        log(name..' clamped to '..minimum..'–'..maximum)
    end
    return math.max(minimum, math.min(maximum, value))
end
local nativeKey = config.GatherKey or 'Gamepad_RightShoulder'
if type(nativeKey) ~= 'string' or not nativeKey:match('^Gamepad_[%w_]+$') then
    log('GatherKey is invalid; using Gamepad_RightShoulder.')
    nativeKey = 'Gamepad_RightShoulder'
end
local keyboardName = config.KeyboardGatherKey
if keyboardName == nil then keyboardName = 'O' end
local keyboardKey = keyboardName ~= false and type(keyboardName)=='string' and Key[keyboardName] or nil
if keyboardName ~= false and not keyboardKey then log('Invalid KeyboardGatherKey; keyboard shortcut disabled.') end
local settings = {
    radius_uu = math.floor(number(config.GatherRadiusMeters,100,10,200,'GatherRadiusMeters')/10+0.5)*10*UU_PER_M,
    hold_seconds = number(config.GatherHoldSeconds,0.6,0.2,5,'GatherHoldSeconds'),
    gather_key = nativeKey,
    keyboard_key = keyboardKey,
    debugLogging = config.debugLogging == true,
}
local directory=debug.getinfo(1,'S').source:match('^@(.+[/\\])[^/\\]+$')
if directory then
    local menuOK,menuError=pcall(function() require('SettingsMenu').bind(directory,settings,log) end)
    if not menuOK then log('Mod Settings could not initialize: '..tostring(menuError)) end
else
    log('Mod Settings could not resolve the script directory; using config.lua defaults.')
end
local function dist2(a,b)
    local x,y,z = a.X-b.X,a.Y-b.Y,a.Z-b.Z
    return x*x+y*y+z*z
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
    local state = tonumber(tostring(comp:GetInteractionState()))
    local changed = state ~= nil and state ~= STATE_INTERACTABLE
    if settings.debugLogging and changed then
        log(string.format("Gathered %s at %.0fu", itemName, dist))
    end
    return changed
end

-- One requested gather job at a time. World discovery occurs once per request.
-- Process at most eight actors or one millisecond per 16ms continuation; an
-- indivisible FindAllOf scan remains inherited from upstream and needs live timing.
local activeJob
local firstGatherReport = true
local function gather_nearby(scope)
    if activeJob then return end
    local job = {scope=scope, radius=settings.radius_uu, index=1, gathered=0, requested=0, near=0, skipped=0}
    activeJob = job
    if settings.debugLogging then job.started = os.clock() end
    local function finish(status)
        if activeJob ~= job then return end
        activeJob = nil
        if firstGatherReport or settings.debugLogging then
            firstGatherReport=false
            log(string.format('Gather %s: scanned %d; within %.0fm %d; interaction requests %d; immediate state changes %d; skipped %d.',
                status or 'complete',job.actors and #job.actors or 0,job.radius/UU_PER_M,
                job.near,job.requested,job.gathered,job.skipped))
        end
        if settings.debugLogging then
            log(string.format('Gather elapsed %.3fs.',os.clock()-job.started))
        end
    end
    local function step()
        if activeJob ~= job then return end
        local worked, err = pcall(function()
            if not scope.isCurrent() then finish('interrupted'); return end
            if not job.actors then
                local position = scope.pawn:K2_GetActorLocation()
                -- Copy returned struct fields; never retain the borrowed wrapper.
                job.position = {X=position.X,Y=position.Y,Z=position.Z}
                job.actors = FindAllOf(HARVESTABLE_CLASS) or {}
                -- Never add actor interactions to the same frame as the global scan.
                ExecuteInGameThreadWithDelay(16,step)
                return
            end
            local started, count = os.clock(), 0
            while job.index <= #job.actors and count < 8 do
                if count > 0 and os.clock()-started >= 0.001 then break end
                local actor=job.actors[job.index]
                job.index, count=job.index+1,count+1
                local okActor, failure=pcall(function()
                    if not actor or not actor:IsValid() then job.skipped=job.skipped+1; return end
                    local actorWorld = actor:GetWorld()
                    if not actorWorld or not actorWorld:IsValid() or actorWorld:GetAddress() ~= scope.world:GetAddress() then
                        job.skipped=job.skipped+1; return
                    end
                    local distance=dist2(job.position,actor:K2_GetActorLocation())
                    if distance <= job.radius*job.radius then
                        job.near=job.near+1
                        local comp,itemName=eligible_comp(actor)
                        if comp then
                            job.requested=job.requested+1
                            if gather(comp,itemName,distance) then job.gathered=job.gathered+1 end
                        end
                    end
                end)
                if not okActor then
                    job.skipped=job.skipped+1
                    if settings.debugLogging and not job.firstError then
                        job.firstError=true;log('Gather skipped an invalid object: '..tostring(failure))
                    end
                end
            end
            if job.index <= #job.actors then ExecuteInGameThreadWithDelay(16,step)
            else finish() end
        end)
        if not worked then activeJob=nil;log('Gather stopped: '..tostring(err)) end
    end
    ExecuteInGameThreadWithDelay(16,step)
end

if require('ControllerHold').start(settings,gather_nearby,log) then
    log(string.format('Configured v1.1.0: hold %s for %.1fs to gather within %.0fm%s; waiting for local player.',
        settings.gather_key,settings.hold_seconds,settings.radius_uu/UU_PER_M,
        keyboardKey and ('; keyboard '..keyboardName) or ''))
end

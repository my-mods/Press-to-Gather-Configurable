local Log=require('ModLog')
local logDirectory=assert(debug.getinfo(1,'S').source:match('^@(.+[\\/])'))
Log.initialize(logDirectory)
-- Based on Toggleable Auto Gather by Tic0311, script v1.1.0.
-- Keeps original harvestables and adds explicitly listed, unowned botanical lootables.
local MOD_NAME, HARVESTABLE_CLASS = "PressToGather", "Harvestable"
local Plants = require('PlantGather')
local Harvestables = require('HarvestableCache')
local STATE_INTERACTABLE, UU_PER_M = 4, 100
local function log(message) Log.warning(message) end
Plants.start(log)
Harvestables.start()
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
local Bindings = require('ControllerBindings')
local nativeKey = config.GatherKey
if nativeKey == nil then nativeKey = Bindings.key(Bindings.default) end
if type(nativeKey) ~= 'string' or Bindings.id(nativeKey) == nil then
    log('GatherKey is invalid; using Gamepad_FaceButton_Right (B / Circle).')
    nativeKey = Bindings.key(Bindings.default)
end
local keyboardName = config.KeyboardGatherKey
if keyboardName == nil then keyboardName = 'O' end
local keyboardKey = keyboardName ~= false and type(keyboardName)=='string' and Key[keyboardName] or nil
if keyboardName ~= false and not keyboardKey then log('Invalid KeyboardGatherKey; keyboard shortcut disabled.') end
local settings = {
    radius_uu = math.floor(number(config.GatherRadiusMeters,20,10,200,'GatherRadiusMeters')/10+0.5)*10*UU_PER_M,
    hold_seconds = number(config.GatherHoldSeconds,0.6,0.2,5,'GatherHoldSeconds'),
    gather_key = nativeKey,
    keyboard_key = keyboardKey,
    debugLogging = config.debugLogging == true,
    gather_rare_plants = config.GatherRarePlants == true,
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
local function eligible_comp(actor, gatherRarePlants)
    -- Only use genuine HarvestableComponents.
    -- Botanical lootables use their separate, explicit eligibility rules.
    local comp = actor.HarvestableComponent

    if comp == nil or not comp:IsValid() then
        return nil,nil,'missing harvestable component'
    end

    -- InteractionState is userdata
    if tonumber(tostring(comp:GetInteractionState())) ~= STATE_INTERACTABLE then
        return nil,nil,'not interactable'
    end

    if comp:IsInteractionEnabled() ~= true then
        return nil,nil,'interaction disabled'
    end

    local item = comp.HarvestableConfig.Item
    if item == nil or not item:IsValid() then
        return nil,nil,'missing item'
    end

    local permitted,reason=Plants.itemAllowed(item,gatherRarePlants)
    if not permitted then return nil,item:GetFullName(),reason end
    return comp, item:GetFullName()
end

---@param comp UObject gathered component
---@param itemName string
---@param d2 number squared distance at selection time
local function gather(comp, itemName, d2)
    comp:StartInteraction()

    local state = tonumber(tostring(comp:GetInteractionState()))
    local changed = state ~= nil and state ~= STATE_INTERACTABLE
    if settings.debugLogging and changed then
        Log.debug(string.format("Gathered %s at %.0fu", itemName, math.sqrt(d2)))
    end
    return changed
end

-- One requested gather job at a time. Discovery is seeded once per world and
-- refreshed after missed candidates or capacity overflow; construction supplies new actors.
-- Process at most eight actors or one millisecond per 16ms continuation; an
-- initial/recovery FindAllOf remains indivisible and needs live timing.
-- UE4SS AActor:GetWorld walks Outer. Streamed world-partition actors can have
-- an external package World there; Level.OwningWorld is their gameplay world.
local function actor_world(actor, botanical)
    local ok,owner=pcall(function()
        local level=actor:GetLevel()
        if level and level:IsValid() then
            local world=level.OwningWorld
            if world and world:IsValid() then return world end
        end
    end)
    if ok and owner then return owner end
    -- Preserve ordinary native harvestables on older/unavailable level wrappers;
    -- botanical actors fail closed rather than accepting uncertain ownership.
    if not botanical then return actor:GetWorld() end
end
local activeJob
local firstGatherReport = true
local plantQueryWarning = false
local function gather_nearby(scope)
    if activeJob then return end
    local job = {scope=scope, radius=settings.radius_uu, index=1, gathered=0, requested=0, near=0, skipped=0,
        plantFound=0,plantNear=0,plantRequests=0,classCache={},seen={},reasons={},examples=0}
    activeJob = job
    if settings.debugLogging then job.started = os.clock() end
    local function finish(status)
        if activeJob ~= job then return end
        activeJob = nil
        Plants.finish(status==nil or status=='complete')
        Harvestables.finish(status==nil or status=='complete')
        if Log.allows(3) and (firstGatherReport or settings.debugLogging) then
            firstGatherReport=false
            Log.info(string.format('Gather %s: scanned %d; within %.0fm %d; interaction requests %d; immediate state changes %d; skipped %d.',
                status or 'complete',job.total or (job.actors and #job.actors or 0),job.radius/UU_PER_M,
                job.near,job.requested,job.gathered,job.skipped))
        end
        if settings.debugLogging then
            Log.debug(string.format('Botanical plants: matched %d; nearby %d; interaction requests %d%s.',
                job.plantFound,job.plantNear,job.plantRequests,
                job.plantScanReason and ('; '..job.plantScanReason) or ''))
            local reasons={}
            for reason,count in pairs(job.reasons) do reasons[#reasons+1]=reason..'='..count end
            table.sort(reasons)
            if #reasons>0 then Log.debug('Gather eligibility: '..table.concat(reasons,'; ')..'.') end
        end
        if settings.debugLogging and job.started then
            Log.debug(string.format('Gather elapsed %.3fs.',os.clock()-job.started))
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
                job.actors = Harvestables.find(scope)
                -- Never add actor interactions to the same frame as the global scan.
                ExecuteInGameThreadWithDelay(16,step)
                return
            end
            if not job.plants then
                -- Initial/recovery discovery gets its own later frame. Repeated
                -- requests reuse plant actors collected through construction events.
                local okPlants,actors,reason=pcall(Plants.find,scope)
                job.plants=okPlants and actors or {}
                job.plantScanReason=okPlants and reason or 'plant query unavailable'
                if not okPlants and not plantQueryWarning then
                    plantQueryWarning=true
                    log('Botanical plant query unavailable; ordinary harvestables remain enabled: '..tostring(actors))
                end
                job.total=#job.actors+#job.plants
                ExecuteInGameThreadWithDelay(16,step)
                return
            end
            local started, count = os.clock(), 0
            while job.index <= job.total and count < 8 do
                if count > 0 and os.clock()-started >= 0.001 then break end
                local botanical=job.index>#job.actors
                local actor=botanical and job.plants[job.index-#job.actors] or job.actors[job.index]
                job.index, count=job.index+1,count+1
                local okActor, failure=pcall(function()
                    if not actor or not actor:IsValid() then job.skipped=job.skipped+1; return end
                    local actorWorld = actor_world(actor,botanical)
                    if not actorWorld or not actorWorld:IsValid() then
                        if botanical then Plants.retry() else Harvestables.retry() end
                    end
                    if not actorWorld or not actorWorld:IsValid() or actorWorld:GetAddress() ~= scope.world:GetAddress() then
                        job.skipped=job.skipped+1
                        if settings.debugLogging then
                            local reason=(botanical and 'plant: ' or 'harvestable: ')..
                                ((not actorWorld or not actorWorld:IsValid()) and 'world unavailable' or 'different world')
                            job.reasons[reason]=(job.reasons[reason] or 0)+1
                            if job.examples<3 then
                                job.examples=job.examples+1
                                Log.debug('Actor not requested: '..actor:GetFullName()..'; '..reason..
                                    '; actor world '..tostring(actorWorld and actorWorld:IsValid() and actorWorld:GetAddress() or 'invalid')..
                                    '; player world '..tostring(scope.world:GetAddress())..'.')
                            end
                        end
                        return
                    end
                    local address=actor:GetAddress()
                    if job.seen[address] then return end
                    job.seen[address]=true
                    local plantEntry
                    if botanical then
                        -- Keep known plants outside today's radius for later presses
                        -- after the player moves; never cache unlisted world loot.
                        plantEntry=Plants.observe(actor,job.classCache)
                        if not plantEntry then
                            if settings.debugLogging then
                                job.reasons['plant: unlisted or invalid class']=(job.reasons['plant: unlisted or invalid class'] or 0)+1
                            end
                            return
                        end
                        job.plantFound=job.plantFound+1
                    else Harvestables.observe(actor) end
                    local distance=dist2(job.position,actor:K2_GetActorLocation())
                    if distance <= job.radius*job.radius then
                        job.near=job.near+1
                        if botanical then job.plantNear=job.plantNear+1 end
                        local comp,itemName,reason
                        if botanical then comp,itemName,reason=Plants.eligible(actor,plantEntry,settings.gather_rare_plants)
                        else comp,itemName,reason=eligible_comp(actor,settings.gather_rare_plants) end
                        if comp then
                            job.requested=job.requested+1
                            if botanical then job.plantRequests=job.plantRequests+1 end
                            if gather(comp,itemName,distance) then job.gathered=job.gathered+1 end
                        elseif settings.debugLogging then
                            local key=(botanical and 'plant: ' or 'harvestable: ')..(reason or 'ineligible')
                            job.reasons[key]=(job.reasons[key] or 0)+1
                            if botanical and itemName and job.examples<3 then
                                job.examples=job.examples+1
                                Log.debug(string.format('Plant not requested: %s at %.1fm; %s.',itemName,math.sqrt(distance)/UU_PER_M,reason or 'ineligible'))
                            end
                        end
                    end
                end)
                if not okActor then
                    if botanical then Plants.retry() else Harvestables.retry() end
                    job.skipped=job.skipped+1
                    if settings.debugLogging and not job.firstError then
                        job.firstError=true;Log.debug('Gather skipped an invalid object: '..tostring(failure))
                    end
                end
            end
            if job.index <= job.total then ExecuteInGameThreadWithDelay(16,step)
            else finish() end
        end)
        if not worked then finish('stopped');Log.error('Gather stopped: '..tostring(err)) end
    end
    ExecuteInGameThreadWithDelay(16,step)
end

if require('ControllerHold').start(settings,gather_nearby,log) and Log.allows(3) then
    Log.info(string.format('Configured: hold %s for %.1fs to gather within %.0fm%s; waiting for local player.',
        settings.gather_key,settings.hold_seconds,settings.radius_uu/UU_PER_M,
        keyboardKey and ('; keyboard '..keyboardName) or ''))
end

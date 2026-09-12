-- Controller hold input. EngineTick timers; no Blueprint dispatch dependency.
local M = {}

function M.start(settings, gather, log)
    local POLL_MS, RETRY_MS, MAX_ATTEMPTS = 50, 250, 40
    local engine, gameplay, inputKey
    local owner, pollHandle, pending, wakeHandle, generation = nil, nil, nil, nil, 0
    local holdStart, armed, fired = nil, false, false
    local warnings, hookIds = {}, {}
    local firstReady, firstDown, firstHold = true, true, true
    local loading = false
    local lastLoadingState, reloadRequested
    local function valid(object) return object ~= nil and object:IsValid() end
    local function same(a, b)
        return valid(a) and valid(b) and a:GetAddress() == b:GetAddress()
    end
    local function trace(message)
        if settings.debugLogging then log(message) end
    end
    local function warn(key, message)
        if warnings[key] then return end
        warnings[key] = true
        log(message)
    end
    local function report_blocked(reason)
        if warnings[reason] then return end
        warnings[reason]=true
        log('Gather input blocked: '..reason..'. Release the button before trying again in gameplay.')
    end
    local function reset_hold()
        holdStart, armed, fired = nil, false, false
    end
    local function reload_settings()
        if loading or not reloadRequested then return end
        reloadRequested=false
        if type(settings.reload)=='function' then
            local ok,err=pcall(settings.reload)
            if not ok then warn('settingsReload', 'Mod Settings reload failed: '..tostring(err)) end
        end
    end
    local function stop_poll()
        if pollHandle then CancelDelayedAction(pollHandle); pollHandle = nil end
        owner = nil
        reset_hold()
    end
    local function current(scope)
        if loading or owner ~= scope or scope.generation ~= generation then return false end
        if not valid(engine) or not valid(gameplay) then return false end
        local viewport = engine.GameViewport
        if not valid(viewport) or not same(viewport:GetWorld(), scope.world) then return false end
        return valid(scope.controller) and same(scope.controller:GetWorld(), scope.world)
            and same(scope.controller.Pawn, scope.pawn) and same(scope.pawn:GetWorld(), scope.world)
    end
    local function blocked_reason(scope)
        local pc = scope.controller
        if gameplay:IsGamePaused(scope.world) then return 'game paused' end
        -- bCinematicMode is not a reflected PlayerController property. UE4SS
        -- returns a truthy invalid UObject for that lookup, blocking every input.
        -- Use the exposed pause/cursor/movement state; cutscenes that lock
        -- movement are covered by IsMoveInputIgnored below.
        if pc.bShowMouseCursor == true then return 'mouse cursor visible' end
        if pc:IsMoveInputIgnored() then return 'movement input disabled' end
    end
    local function playable(scope)
        return blocked_reason(scope) == nil
    end
    local function request_gather(scope)
        if not current(scope) then return end
        local blocked=blocked_reason(scope)
        if blocked then report_blocked(blocked);return end
        gather(scope)
    end
    local wake
    local function poll()
        local ok, err = pcall(function()
            if loading then stop_poll(); return end
            local scope = owner
            if not scope or not current(scope) then
                stop_poll()
                wake('player changed')
                return
            end
            local down = scope.controller:IsInputKeyDown(inputKey)
            if not down then
                holdStart, armed, fired = nil, true, false
                return
            end
            if firstDown then
                firstDown=false
                log('Controller button detected: '..settings.gather_key..'.')
            end
            local blocked = blocked_reason(scope)
            if blocked then
                report_blocked(blocked)
                reset_hold()
                return
            end
            -- A release is required after startup/loading/menus before a hold.
            if not armed or fired then return end
            local now = gameplay:GetRealTimeSeconds(scope.world)
            if holdStart == nil or now < holdStart then holdStart = now end
            if now - holdStart >= settings.hold_seconds then
                fired = true
                if firstHold then
                    firstHold=false
                    log('Controller hold accepted; gathering requested.')
                end
                request_gather(scope)
            end
        end)
        if not ok then
            stop_poll()
            warn('input', 'Controller input stopped: '..tostring(err)..'. It will retry after a player lifecycle event.')
        end
    end
    local function discover(job)
        -- At most one Engine search and one static-object lookup per finite window.
        if not valid(engine) and not job.engineLooked then
            job.engineLooked = true
            engine = FindFirstOf('Engine')
        end
        if not valid(gameplay) and not job.gameplayLooked then
            job.gameplayLooked = true
            gameplay = StaticFindObject('/Script/Engine.Default__GameplayStatics')
        end
        if not valid(engine) or not valid(gameplay) then return nil,'engine services unavailable' end
        local viewport = engine.GameViewport
        if not valid(viewport) then return nil,'viewport unavailable' end
        local world = viewport:GetWorld()
        if not valid(world) then return nil,'world unavailable' end
        local pc = gameplay:GetPlayerController(world, 0)
        if not valid(pc) or not pc:IsLocalController() or not same(pc:GetWorld(), world) then
            return nil,'local player controller unavailable'
        end
        local pawn = pc.Pawn
        -- Input and gathering need a possessed pawn, not the separate stats object.
        if not valid(pawn) or not same(pawn:GetWorld(), world) then return nil,'local player pawn unavailable' end
        local scope = {controller=pc, pawn=pawn, world=world, generation=generation}
        function scope.isCurrent() return current(scope) and playable(scope) end
        return scope
    end
    local function attempt(job)
        if pending ~= job then return end
        job.handle = nil
        if loading then pending=nil; return end
        reload_settings()
        job.attempts = job.attempts + 1
        local ok, scope, reason = pcall(discover, job)
        if not ok then
            pending = nil
            warn('setup', 'Controller setup stopped: '..tostring(scope))
            return
        end
        if scope then
            pending, owner = nil, scope
            reset_hold()
            local registered, handle = pcall(LoopInGameThreadWithDelay, POLL_MS, poll)
            if not registered then
                owner = nil
                warn('timer', 'Controller timer could not start: '..tostring(handle))
                return
            end
            pollHandle = handle
            if firstReady then
                firstReady=false
                log('Local player ready; controller hold input active.')
            end
            if settings.debugLogging then
                trace(string.format('Controller ready after %d attempt(s); hold %.2fs, poll %dms.', job.attempts, settings.hold_seconds, POLL_MS))
            end
        elseif job.attempts < MAX_ATTEMPTS then
            job.handle = ExecuteInGameThreadWithDelay(RETRY_MS, function() attempt(job) end)
        else
            pending = nil
            warn('readiness:'..tostring(reason), 'Controller setup waiting: '..tostring(reason)..
                '. Discovery stopped after 40 attempts; a player lifecycle event or keyboard O will retry.')
        end
    end
    local function begin_window(reason)
        generation = generation + 1
        stop_poll()
        if pending then
            if pending.handle then CancelDelayedAction(pending.handle) end
            pending = nil
        end
        local job = {attempts=0}
        pending = job
        attempt(job)
    end
    wake = function(reason)
        -- Construction notifications only schedule work: no UObject reads here.
        -- Events inside an active finite discovery window need no additional timer.
        if pending then return end
        if wakeHandle then return end
        wakeHandle = ExecuteInGameThreadWithDelay(50, function()
            wakeHandle = nil
            if loading then
                stop_poll()
                if pending and pending.handle then CancelDelayedAction(pending.handle) end
                pending = nil
                return
            end
            reload_settings()
            -- Coalesce construction bursts without extending an active retry window.
            if pending then return end
            begin_window(reason)
        end)
    end
    for _, name in ipairs({'ExecuteInGameThreadWithDelay','LoopInGameThreadWithDelay','CancelDelayedAction'}) do
        if type(_G[name]) ~= 'function' then
            log('Cannot start controller input: required UE4SS API '..name..' is unavailable.')
            return false
        end
    end
    inputKey = {KeyName=FName(settings.gather_key)}
    -- Native restart hook is available with Framecore's Blueprint hooks disabled.
    local function hook(path, pre, post)
        local ok, before, after = pcall(RegisterHook, path, pre, post)
        if ok and before and after then hookIds[path]={before,after}
        else warn(path, 'Lifecycle hook unavailable: '..path..': '..tostring(before)) end
    end
    hook('/Script/Engine.PlayerController:ClientRestart',
        function() generation=generation+1; reset_hold() end,
        function() wake('client restart') end)
    hook('/Script/DogwoodCombat.CombatSubsystem:OnLoadingScreenStateChanged',
        function() end, function(_, state)
            local value=tonumber(type(state)=='number' and state or state:get())
            if value and value >= 0 and value <= 4 and value~=lastLoadingState then
                lastLoadingState=value
                if value==0 then reloadRequested=true end
                loading=value~=0
                generation=generation+1
                reset_hold()
                wake('loading screen')
            end
        end)
    for _, path in ipairs({'/Script/Dawnwalker.DawnwalkerPlayerCharacter'}) do
        local ok, err = pcall(NotifyOnNewObject, path, function() wake('player construction') end)
        if not ok then warn(path, 'Player notification unavailable: '..tostring(err)) end
    end
    if settings.keyboard_key then
        local ok, err = pcall(RegisterKeyBind, settings.keyboard_key, function()
            ExecuteInGameThread(function()
                local scope = owner
                if not scope then
                    warn('keyboardNotReady', 'Keyboard gather: local player is not ready; retrying controller setup.')
                    wake('keyboard request')
                    return
                end
                local worked, failure = pcall(request_gather, scope)
                if not worked then warn('keyboard', 'Keyboard gather failed: '..tostring(failure)) end
            end)
        end)
        if not ok then warn('keyboardRegistration', 'Keyboard shortcut unavailable: '..tostring(err)) end
    end
    wake('startup')
    return true
end

return M

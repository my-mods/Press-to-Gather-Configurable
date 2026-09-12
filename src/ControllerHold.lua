-- Controller hold input. EngineTick timers; no Blueprint dispatch dependency.
local M = {}

function M.start(settings, gather, log)
    local POLL_MS, RETRY_MS, MAX_ATTEMPTS = 50, 250, 40
    local engine, gameplay, inputKey
    local owner, pollHandle, pending, wakeHandle, generation = nil, nil, nil, nil, 0
    local holdStart, armed, fired = nil, false, false
    local warnings, hookIds = {}, {}
    local loading = false
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
    local function reset_hold()
        holdStart, armed, fired = nil, false, false
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
    local function playable(scope)
        local pc = scope.controller
        return not gameplay:IsGamePaused(scope.world)
            and not pc.bCinematicMode and not pc.bShowMouseCursor and not pc:IsMoveInputIgnored()
    end
    local function request_gather(scope)
        if current(scope) and playable(scope) then gather(scope) end
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
            if not playable(scope) then reset_hold(); return end
            -- A release is required after startup/loading/menus before a hold.
            if not armed or fired then return end
            local now = gameplay:GetRealTimeSeconds(scope.world)
            if holdStart == nil or now < holdStart then holdStart = now end
            if now - holdStart >= settings.hold_seconds then
                fired = true
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
        if not valid(engine) or not valid(gameplay) then return end
        local viewport = engine.GameViewport
        if not valid(viewport) then return end
        local world = viewport:GetWorld()
        if not valid(world) then return end
        local pc = gameplay:GetPlayerController(world, 0)
        if not valid(pc) or not pc:IsLocalController() or not same(pc:GetWorld(), world) then return end
        local pawn = pc.Pawn
        if not valid(pawn) or not same(pawn:GetWorld(), world) or not valid(pawn.CharDevAttributeSet) then return end
        local scope = {controller=pc, pawn=pawn, world=world, generation=generation}
        function scope.isCurrent() return current(scope) and playable(scope) end
        return scope
    end
    local function attempt(job)
        if pending ~= job then return end
        job.handle = nil
        if loading then pending=nil; return end
        job.attempts = job.attempts + 1
        local ok, scope = pcall(discover, job)
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
            if settings.debugLogging then
                trace(string.format('Controller ready after %d attempt(s); hold %.2fs, poll %dms.', job.attempts, settings.hold_seconds, POLL_MS))
            end
        elseif job.attempts < MAX_ATTEMPTS then
            job.handle = ExecuteInGameThreadWithDelay(RETRY_MS, function() attempt(job) end)
        else
            pending = nil
            trace('Player not ready; discovery stopped until the next lifecycle event.')
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
        if wakeHandle then return end
        wakeHandle = ExecuteInGameThreadWithDelay(50, function()
            wakeHandle = nil
            if loading then
                stop_poll()
                if pending and pending.handle then CancelDelayedAction(pending.handle) end
                pending = nil
                return
            end
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
            if value and value >= 0 and value <= 4 then
                loading=value~=0
                generation=generation+1
                reset_hold()
                wake('loading screen')
            end
        end)
    for _, path in ipairs({'/Script/Dawnwalker.DawnwalkerPlayerCharacter','/Script/DogwoodStats.CharDevAttributeSet'}) do
        local ok, err = pcall(NotifyOnNewObject, path, function() wake('player construction') end)
        if not ok then warn(path, 'Player notification unavailable: '..tostring(err)) end
    end
    if settings.keyboard_key then
        local ok, err = pcall(RegisterKeyBind, settings.keyboard_key, function()
            ExecuteInGameThread(function()
                local scope = owner
                if not scope then return end
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

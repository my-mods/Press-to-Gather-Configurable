-- Explicit support for botanical lootables. General world loot is never selected.
local M = {}
local ROOT = '/Game/_Dawnwalker/WorldActors/BP_Harvestable.BP_Harvestable_C'
local PREFIX = '/Game/_Dawnwalker/WorldActors/Lootables/BP_Lootable_'
local ITEM_PREFIX = '/Game/_Dawnwalker/Inventory/Items/'
local plants = {
    Aconite = {'Aconite', 'ITM_Ingredient_Herbs6'},
    Blueberry = {'Blueberry', 'ITM_Consumable_Berrys3'},
    CaveFungus = {'Cave Fungus', 'ITM_Ingredient_Mushrooms6'},
    Chanterelle = {'Chanterelle', 'ITM_Ingredient_Mushrooms3'},
    Comfrey = {'Comfrey', 'ITM_Ingredient_Herbs4'},
    CommonYarrowHerb = {'Common Yarrow', 'ITM_Ingredient_Herbs7'},
    GreenGilledMushroom = {'Green-Gilled Mushroom', 'ITM_Ingredient_Mushrooms2'},
    ParasolMushroom = {'Parasol Mushroom', 'ITM_Ingredient_Mushrooms1'},
    Perilla = {'Perilla', 'ITM_Ingredient_Herbs5'},
    Raspberry = {'Raspberry', 'ITM_Consumable_Berrys1'},
    RibwortPlantain = {'Ribwort Plantain', 'ITM_Ingredient_Herbs2'},
    SaffronMilkCap = {'Saffron Milk Cap', 'ITM_Ingredient_Mushrooms4'},
    SlipperyJack = {'Slippery Jack', 'ITM_Ingredient_Mushrooms5'},
    StJohnsWort = {"St John's Wort", 'ITM_Ingredient_Herbs3'},
    Tansy = {'Tansy', 'ITM_Ingredient_Herbs8'},
    WildStrawberry = {'Wild Strawberry', 'ITM_Consumable_Berrys2'},
    YellowSweetClover = {'Yellow Sweet Clover', 'ITM_Ingredient_Herbs1'},
}
local allowed = {}
for suffix, entry in pairs(plants) do
    allowed['BlueprintGeneratedClass '..PREFIX..suffix..'.BP_Lootable_'..suffix..'_C'] = {
        label=entry[1], item=ITEM_PREFIX..entry[2]..'.'..entry[2],
    }
end
local function valid(object) return object ~= nil and object:IsValid() end
local function enum(value) return tonumber(tostring(value)) end
local LIMIT=4096
local ready, started, world, cache, pending, dirty, active = false,false,nil,{}, {},true,nil
local warnedCapacity=false
local report

function M.start(log)
    if started then return end
    started,report=true,log
    local ok,err=pcall(NotifyOnNewObject,ROOT,function(actor)
        -- Construction may be early. Capture only; inspect on an explicit gather.
        if #pending<LIMIT then pending[#pending+1]=actor
        else dirty=true end
    end)
    ready=ok
    if not ok then log('Botanical plant discovery unavailable; ordinary harvestables remain enabled: '..tostring(err)) end
end

-- A view of at most three fixed arrays, without a synchronous concatenation.
local function view(a,b,c)
    local na,nb,nc=#a,#b,#c
    return setmetatable({}, {
        __len=function() return na+nb+nc end,
        __index=function(_,i)
            if i<=na then return a[i] end
            if i<=na+nb then return b[i-na] end
            return c[i-na-nb]
        end,
    })
end

-- Seed on the first request in a world; subsequent requests use the cache and
-- construction notifications. Missing notifications fail this feature closed.
-- FindAllOf's ambiguous short Blueprint name is filtered by exact class paths.
function M.find(scope)
    if not ready then return {}, 'plant notifications unavailable' end
    local address=scope.world:GetAddress()
    if not world or not valid(world) or world:GetAddress()~=address then
        world,cache,pending,dirty=scope.world,{}, {},true
    end
    local seed={}
    local seeded=dirty
    if dirty then seed=FindAllOf('BP_Harvestable_C') or {};dirty=false end
    local queue=pending
    pending={}
    active={next={},seen={}}
    return view(cache,queue,seed),seeded and 'cache seeded' or 'cached discovery'
end

function M.finish(completed)
    if active then
        if completed then cache=active.next
        else dirty=true end -- Retry interrupted/missed candidates on the next press.
        active=nil
    end
end

function M.retry() dirty=true end

local function remember(actor)
    if not active then return end
    local address=actor:GetAddress()
    if active.seen[address] then return end
    active.seen[address]=true
    if #active.next<LIMIT then active.next[#active.next+1]=actor
    else
        dirty=true
        if not warnedCapacity then
            warnedCapacity=true
            report('Botanical plant cache reached its limit; the next Gather press will refresh discovery.')
        end
    end
end

-- Class decisions belong to this request only. Cached actors are checked for
-- validity and current world by the caller; ownership is checked on every press.
function M.observe(actor, classCache)
    local class=actor:GetClass()
    if not valid(class) then return nil end
    local address=class:GetAddress()
    local cached=classCache[address]
    if cached==nil or not valid(cached.class) then
        cached={class=class,entry=allowed[class:GetFullName()] or false}
        classCache[address]=cached
    end
    local entry=cached.entry
    if not entry then return nil end
    remember(actor)
    return entry
end

function M.eligible(actor, entry)
    local label=entry.label
    local comp=actor.LootableComponent
    if not valid(comp) then return nil,label,'missing lootable component' end
    local owner=comp:GetOwner()
    if not valid(owner) or owner:GetAddress()~=actor:GetAddress() then return nil,label,'component owner mismatch' end
    if enum(comp:GetInteractionState())~=4 then return nil,label,'not interactable' end
    if comp:IsInteractionEnabled()~=true then return nil,label,'interaction disabled' end
    -- Unknown/missing flags reject only this plant, without affecting harvestables.
    if comp:IsQuestInteractable()~=false or comp:IsQuestImportantInteractable()~=false then
        return nil,label,'quest interaction'
    end
    -- The game's risk query refreshes its stealable-volume information.
    local risk=enum(comp:GetInteractionRiskType())
    if comp.bIsStealable~=false then return nil,label,'owned or ownership unavailable' end
    local volumes=comp.StealableVolumeAffection.StealableVolumeCount
    if type(volumes)~='number' or volumes~=0 then return nil,label,'stealable volume or ownership unavailable' end
    if risk~=0 then return nil,label,'risky interaction' end
    local item=comp.Item
    if not valid(item) then return nil,label,'missing item' end
    local name=item:GetFullName()
    if name:match('^[^ ]+ (.+)$')~=entry.item then return nil,label,'item mismatch' end
    return comp,label
end

return M

-- Ordinary Harvestable actors. Discovery stays on explicit Gather requests.
local M={}
local LIMIT=8192
local world,cache,pending,active
local ready,dirty=false,true
pending={};cache={}
local function valid(o)return o and o:IsValid()end
function M.start()
    ready=pcall(NotifyOnNewObject,'/Script/DogwoodWorld.Harvestable',function(actor)
        -- Construction can precede BeginPlay: retain only, inspect on Gather.
        if #pending<LIMIT then pending[#pending+1]=actor else dirty=true end
    end)
end
function M.find(scope)
    if not valid(world) or world:GetAddress()~=scope.world:GetAddress()then
        world=scope.world;cache={};pending={};dirty=true
    end
    local seed={}
    if dirty or not ready then seed=FindAllOf('Harvestable') or {};dirty=false end
    local old,queue=cache,pending;pending={};active={next={},seen={}}
    local a,b,c=#old,#queue,#seed
    return setmetatable({},{__len=function()return a+b+c end,__index=function(_,i)
        if i<=a then return old[i]elseif i<=a+b then return queue[i-a]else return seed[i-a-b]end
    end})
end
function M.observe(actor)
    if not active then return end
    local address=actor:GetAddress()
    if active.seen[address]then return end
    active.seen[address]=true
    if #active.next<LIMIT then active.next[#active.next+1]=actor else dirty=true end
end
function M.retry()dirty=true end
function M.finish(completed)
    if active then
        if completed then cache=active.next else dirty=true end
        active=nil
    end
end
return M

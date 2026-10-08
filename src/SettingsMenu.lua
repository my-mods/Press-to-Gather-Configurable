-- Read preferences at configuration boundaries; menu Apply supplies saved values.
-- Storage is the pinned MIT SettingsStore from ue4ss-common.
local M = {}
local Store = require('SettingsStore')
local Bindings = require('ControllerBindings')
local distances = {}
for value=10,200,10 do distances[#distances+1]=value end
local schema = {
    {key='GatherRadiusMeters',values=distances,default=20},
    {key='GatherButton',values=Bindings.values,default=Bindings.default},
    {key='GatherRarePlants',values={0,1},default=0},
    {key='logLevel',values={0,1,2,3,4},default=2},
}
function M.bind(directory,settings,log)
    local Log=require('ModLog')
    local initialButton=Bindings.id(settings.gather_key) or Bindings.default
    schema[1].default=settings.radius_uu/100;schema[2].default=initialButton
    schema[3].default=settings.gather_rare_plants and 1 or 0
    schema[4].default=settings.debugLogging and 4 or 2
    local function apply(values)
        Log.setLevel(values.logLevel)
        local gatherKey=Bindings.key(values.GatherButton)
        if settings.gather_key~=gatherKey and settings.changeBinding then settings.changeBinding(gatherKey) end
        settings.radius_uu=values.GatherRadiusMeters*100
        settings.gather_key=gatherKey
        settings.gather_rare_plants=values.GatherRarePlants==1
        settings.logLevel=values.logLevel
        settings.debugLogging=values.logLevel==4
        Log.info('Settings applied.')
    end
    local live=require('UE4SSDawnwalkerSettings').new({modId='PressToGather',schema=schema,
        ids={GatherRadiusMeters='GatherRadiusMeters',GatherButton='GatherButton',GatherRarePlants='GatherRarePlants',logLevel='logLevel'},report=Log.warning})
    settings.live=live
    live.attach(apply)
    settings.reload=function()
        local values,err=require('LogSettings').load(Store.path(directory),schema)
        if not values then Log.warning('Settings: '..tostring(err)..'; current values retained.');return false end
        live.seed(values);apply(values);return true
    end
    settings.reload()
    live.start(function(id,callback) return Log.subscribe(directory,id,callback) end)
end
return M

-- Menu preferences are loaded at startup and on completed save loading only.
-- Storage is the pinned MIT SettingsStore from ue4ss-common.
local M = {}
local Store = require('SettingsStore')
local distances = {}
for value=10,200,10 do distances[#distances+1]=value end
local schema = {
    {key='GatherRadiusMeters',values=distances,default=100},
    {key='debugLogging',values={0,1},default=0},
}

function M.bind(directory, settings, log)
    local path = Store.path(directory)
    local lastError
    local function report(message)
        if lastError == message then return end
        lastError=message
        log('Mod Settings: '..tostring(message)..'; keeping the current values.')
    end
    local function apply(values)
        local radius=values.GatherRadiusMeters*100
        local debugLogging=values.debugLogging==1
        local changed=settings.radius_uu~=radius or settings.debugLogging~=debugLogging
        settings.radius_uu,settings.debugLogging=radius,debugLogging
        lastError=nil
        if changed then log(string.format('Mod Settings applied: distance %dm, Logging %s.',values.GatherRadiusMeters,debugLogging and 'On' or 'Off')) end
    end
    local values,err=Store.load(directory,schema,function()
        -- Import initial defaults only. Never supply legacy files for deletion.
        return {GatherRadiusMeters=settings.radius_uu/100,debugLogging=settings.debugLogging and 1 or 0}
    end)
    if values then apply(values) else report(err) end
    settings.reload=function()
        local text,readError=Store.read(path)
        if not text then report(readError);return false end
        local saved,parseError=Store.parse(text,schema)
        if not saved then report(parseError);return false end
        apply(saved)
        return true
    end
end

return M

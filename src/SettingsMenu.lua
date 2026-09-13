-- Menu preferences are loaded at startup and on completed save loading only.
-- Storage is the pinned MIT SettingsStore from ue4ss-common.
local M = {}
local Store = require('SettingsStore')
local Bindings = require('ControllerBindings')
local distances = {}
for value=10,200,10 do distances[#distances+1]=value end
local schema = {
    {key='GatherRadiusMeters',values=distances,default=20},
    {key='GatherButton',values=Bindings.values,default=Bindings.default},
    {key='debugLogging',values={0,1},default=0},
}
local distanceAndLogging = {schema[1],schema[3]}

function M.bind(directory, settings, log)
    local path = Store.path(directory)
    local initialButton = Bindings.id(settings.gather_key) or Bindings.default
    local lastError
    local function parse(text)
        local values,err=Store.parse(text,schema)
        -- Earlier settings for this same mod have no button field.
        if not values and err=='Missing setting: GatherButton' then
            values,err=Store.parse(text,distanceAndLogging)
            if values then values.GatherButton=initialButton end
        end
        return values,err
    end
    local function report(message)
        if lastError == message then return end
        lastError=message
        log('Mod Settings: '..tostring(message)..'; keeping the current values.')
    end
    local function add_button(text)
        -- The menu requires an existing assignment. Append only the new field;
        -- preserve every existing byte, including other sections and comments.
        local extra='\n[Settings]\nGatherButton = '..initialButton..'\n'
        if #text+#extra>1048576 then return nil,'Settings exceed 1 MiB' end
        local file,err=io.open(path,'a+b')
        if not file then return nil,err end
        local position=file:seek('set',0)
        local current=position and file:read(1048577)
        if current~=text then file:close();return nil,'Settings changed while adding GatherButton' end
        local written,writeError=file:write(extra)
        local closed,closeError=file:close()
        if not written or not closed then return nil,writeError or closeError end
        if Store.read(path)~=text..extra then return nil,'Could not verify GatherButton addition' end
        return true
    end
    local function apply(values)
        local radius=values.GatherRadiusMeters*100
        local debugLogging=values.debugLogging==1
        local gatherKey=Bindings.key(values.GatherButton)
        local changed=settings.radius_uu~=radius or settings.debugLogging~=debugLogging or settings.gather_key~=gatherKey
        settings.radius_uu,settings.debugLogging,settings.gather_key=radius,debugLogging,gatherKey
        lastError=nil
        if changed then log(string.format('Mod Settings applied: distance %dm, button %s, Logging %s.',values.GatherRadiusMeters,gatherKey,debugLogging and 'On' or 'Off')) end
    end
    local values,err=Store.load(directory,schema,function()
        -- Import initial defaults only. Never supply legacy files for deletion.
        return {GatherRadiusMeters=settings.radius_uu/100,GatherButton=initialButton,debugLogging=settings.debugLogging and 1 or 0}
    end)
    if not values and err=='Missing setting: GatherButton' then
        local text,readError=Store.read(path)
        if text then
            values,err=Store.parse(text,schema)
            if not values and err=='Missing setting: GatherButton' then
                values,err=parse(text)
                if values then
                    local added,addError=add_button(text)
                    if not added then log('Mod Settings could not add GatherButton: '..tostring(addError)) end
                end
            end
        else err=readError end
    end
    if values then apply(values) else report(err) end
    settings.reload=function()
        local text,readError=Store.read(path)
        if not text then report(readError);return false end
        local saved,parseError=parse(text)
        if not saved then report(parseError);return false end
        apply(saved)
        return true
    end
end

return M

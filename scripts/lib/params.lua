-- @noindex
params = {}

params.set = function(obj)
    for parameter, d in pairs(obj.parameters) do
        reaper.SetExtState(obj.info.ext_name, d.name, d.value, true)
    end
end

params.get = function(obj)
    for parameter, d in pairs(obj.parameters) do
        if reaper.HasExtState(obj.info.ext_name, d.name) then
            d.value = reaper.GetExtState(obj.info.ext_name, d.name)
        end
    end
end

return params
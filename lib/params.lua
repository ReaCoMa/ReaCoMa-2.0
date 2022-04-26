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

params.store_defaults = function(obj)
    idx = 1
    defaults = {}
    for parameter, d in pairs(obj.parameters) do
        defaults[idx] = d.value
        idx = idx + 1
    end
    obj.defaults = defaults
end

params.restore_defaults = function(obj)
    idx = 1
    for parameter, d in pairs(obj.parameters) do
        d.value = obj.defaults[idx]
        idx = idx + 1
    end
end


return params
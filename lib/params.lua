params = {}

-- So we don't have to figure out what the index of a table is
-- for any given default parameters. We can encapsulate it into
-- a function that just does it for us.
-- TODO: one day genercise all the functions into a table utilities module...
params.find_index = function(tbl, value)
	for i, v in ipairs(tbl) do
	  if v == value then
		return i
	  end
	end
	return nil
end

params.set = function(obj)
    for _, param in pairs(obj.parameters) do
        -- Handle custom parameters
        if reacoma.utils.table_has(reacoma.widgets, param.widget) then
            reaper.SetExtState(reacoma.settings.version..obj.info.ext_name, param.name, param.index, true)
        else
            reaper.SetExtState(reacoma.settings.version..obj.info.ext_name, param.name, param.value, true)
        end
    end
end

params.get = function(obj)
    for _, param in pairs(obj.parameters) do
        if reaper.HasExtState(reacoma.settings.version..obj.info.ext_name, param.name) then
            -- Test if parameter is a custom widget
            if reacoma.utils.table_has(reacoma.widgets, param.widget) then
                param.index = reaper.GetExtState(reacoma.settings.version..obj.info.ext_name, param.name)
            else
                param.value = reaper.GetExtState(reacoma.settings.version..obj.info.ext_name, param.name)
            end
        end
    end
end

-- TODO store the default parameters
-- This function is currently not being used for anything
params.store_defaults = function(obj)
    idx = 1
    defaults = {}
    for _, param in pairs(obj.parameters) do
        defaults[idx] = param.value
        idx = idx + 1
    end
    obj.defaults = defaults
end

params.restore_defaults = function(obj)
    idx = 1
    for _, param in pairs(obj.parameters) do
        param.value = obj.defaults[idx]
        idx = idx + 1
    end
end


return params
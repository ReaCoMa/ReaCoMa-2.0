local r = reaper

local params = {}

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

params.find_by_name = function(param_tbl, query_name)
    for _, param in ipairs(param_tbl) do
        if param.name == query_name then
            return param.value
        end
    end
    r.ShowConsoleMsg(query_name.. ' not found')
    return nil
end

params.set = function(obj)
    for _, param in pairs(obj.parameters) do
        -- Handle custom parameters
        if reacoma.utils.table_has(reacoma.imgui.widgets, param.widget) then
            r.SetExtState(reacoma.settings.version..obj.info.ext_name, param.name, param.index, true)
        else
            r.SetExtState(reacoma.settings.version..obj.info.ext_name, param.name, param.value, true)
        end
    end
end

params.get = function(obj)
    for _, param in pairs(obj.parameters) do
        if r.HasExtState(reacoma.settings.version..obj.info.ext_name, param.name) then
            -- Test if parameter is a custom widget
            if reacoma.utils.table_has(reacoma.imgui.widgets, param.widget) then
                param.index = r.GetExtState(reacoma.settings.version..obj.info.ext_name, param.name)
            else
                param.value = r.GetExtState(reacoma.settings.version..obj.info.ext_name, param.name)
            end
        end
    end
end

-- TODO store the default parameters
-- This function is currently not being used for anything
params.store_defaults = function(obj)
    local idx = 1
    local defaults = {}
    for _, param in pairs(obj.parameters) do
        defaults[idx] = param.value
        idx = idx + 1
    end
    obj.defaults = defaults
end

params.restore_defaults = function(obj)
    local idx = 1
    for _, param in pairs(obj.parameters) do
        param.value = obj.defaults[idx]
        idx = idx + 1
    end
end

-- stores a parameter into an extended storagein reaper
-- namespaces by slot, algorithm name

local function create_slot_identifier(name, slot)
    return string.format('preset.%s.%d', name, slot)
end

params.store_preset = function(obj, slot)
    for _, param in pairs(obj.parameters) do
        r.SetExtState(
            obj.info.ext_name,
            create_slot_identifier(param.name, slot),
            param.value,
            true
        )
    end
end

params.get_preset = function(obj, slot)
    for _, param in pairs(obj.parameters) do
        local id = create_slot_identifier(param.name, slot)
        if r.HasExtState(obj.info.ext_name, id) then
            local v = r.GetExtState(obj.info.ext_name, id)
            param.value = v
        end
    end
end

return params
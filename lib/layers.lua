local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "OrderedTables.lua")
floor = math.floor
abs = math.abs

layers = {}

layers.container = {
    full_path = {},
    item_pos = {},
    item_pos_samples = {},
    take_ofs = {},
    take_ofs_samples = {},
    item_len = {},
    item_len_samples = {},
    cmd = {},
    slice_points_string = {},
    tmp = {},
    item = {},
    reverse = {},
    sr = {},
    playrate = {},
    take = {},
    path = {},
    playtype = {},
    outputs = {}
}

layers.get_data = function (item_index, data)    
    local info = reacoma.utils.get_item_info(item_index)
    for k, v in pairs(info) do
        table.insert(data[tostring(k)], v)
    end
end

layers.exist = function(item_index, data)
    for k, _ in pairs(data.outputs) do
        if not reacoma.paths.file_exists(data.outputs[k][item_index]) then
            reacoma.utils.DEBUG(data.outputs[k][item_index].." failed to be made by the command line.")
            reacoma.utils.assert(false)
        end
    end
end

layers.process = function(item_index, data)
    if item_index > 1 then reaper.SetMediaItemSelected(data.item[item_index-1], false) end
    reaper.SetMediaItemSelected(data.item[item_index], true)
    for k, v in orderedPairs(data.outputs) do
        reaper.InsertMedia(data.outputs[k][item_index], 3)
        local item = reaper.GetSelectedMediaItem(0, 0)
        local take = reaper.GetActiveTake(item)
        local src = reaper.GetMediaItemTake_Source(take)
        reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", data.playrate[item_index])
        reaper.SetMediaItemTakeInfo_Value(take, "I_PITCHMODE", data.playtype[item_index])
        if data.reverse[item_index] then reaper.Main_OnCommand(41051, 0) end
    end
end

return layers
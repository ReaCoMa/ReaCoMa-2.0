local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "fluidUtils.lua")
dofile(script_path .. "OrderedTables.lua")

fluidLayers = {}
fluidLayers.container = {
    full_path = {},
    take = {},
    item_pos = {},
    item_pos_samples = {},
    take_ofs = {},
    take_ofs_samples = {},
    item_len = {},
    item_len_samples = {},
    cmd = {},
    item = {},
    sr = {},
    playrate = {},
    playtype = {},
    reverse = {},
    outputs = {},
}

fluidLayers.get_data = function (item_index, data)
    local item = reaper.GetSelectedMediaItem(0, item_index-1)
    local take = reaper.GetActiveTake(item)
    local src = reaper.GetMediaItemTake_Source(take)
    local src_parent = reaper.GetMediaSourceParent(src)
    local sr = nil
    local full_path = nil

    if src_parent ~= nil then
        sr = reaper.GetMediaSourceSampleRate(src_parent)
        full_path = reaper.GetMediaSourceFileName(src_parent, "")
        table.insert(data.reverse, true)
    else
        sr = reaper.GetMediaSourceSampleRate(src)
        full_path = reaper.GetMediaSourceFileName(src, "")
        table.insert(data.reverse, false)
    end

    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local src_len = reaper.GetMediaSourceLength(src)
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") * playrate
    local playtype  = reaper.GetMediaItemTakeInfo_Value(take, "I_PITCHMODE")
    
    if data.reverse[item_index] then
        take_ofs = math.abs(src_len - (item_len + take_ofs))
    end

    -- This line caps the analysis at one loop
    if (item_len + take_ofs) > (src_len * (1 / playrate)) then 
        item_len = (src_len * (1 / playrate))
    end

    local take_ofs_samples = fluidUtils.stosamps(take_ofs, sr)
    local item_len_samples = math.floor(fluidUtils.stosamps(item_len, sr))
    
    table.insert(data.item, item)
    table.insert(data.take, take)
    table.insert(data.sr, sr)
    table.insert(data.full_path, full_path)
    table.insert(data.take_ofs, take_ofs)
    table.insert(data.take_ofs_samples, take_ofs_samples)
    table.insert(data.item_len, item_len)
    table.insert(data.item_len_samples, item_len_samples)
    table.insert(data.playrate, playrate)
    table.insert(data.playtype, playtype)
end


fluidLayers.perform_layers = function(item_index, data)
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
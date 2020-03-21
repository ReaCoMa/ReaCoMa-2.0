local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "FluidUtils.lua")
dofile(script_path .. "OrderedTables.lua")

LayersContainer = {
    full_path = {},
    take = {},
    item_pos = {},
    item_pos_samples = {},
    take_ofs = {},
    take_ofs_samples = {},
    item_len_samples = {},
    cmd = {},
    item = {},
    sr = {},
    playrate = {},
    playtype = {},
    reverse = {},
    outputs = {},
}

function get_layers_data(item_index, data)
    -- Function to grab all essential information from media item --
    -- item_index is passed from num_selected_items
    -- data_table is a container for the tables of data

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

    local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local src_len = reaper.GetMediaSourceLength(src)
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local playtype  = reaper.GetMediaItemTakeInfo_Value(take, "I_PITCHMODE")

    -- This line caps the analysis at one loop
    if (item_len + take_ofs) > src_len then item_len = src_len end

    -- Convert everything to samples for CLI --
    local take_ofs_samples = stosamps(take_ofs, sr)
    local item_pos_samples = stosamps(item_pos, sr)
    local item_len_samples = math.floor(stosamps(item_len, sr) * playrate)

    table.insert(data.item, item)
    table.insert(data.take, take)
    table.insert(data.sr, sr)
    table.insert(data.full_path, full_path)
    table.insert(data.take_ofs, take_ofs)
    table.insert(data.take_ofs_samples, take_ofs_samples)
    table.insert(data.item_pos, item_pos)
    table.insert(data.item_pos_samples, item_pos_samples)
    table.insert(data.item_len_samples, item_len_samples)
    table.insert(data.playrate, playrate)
    table.insert(data.playtype, playtype)
end


function perform_layers(item_index, data)
    if item_index > 1 then reaper.SetMediaItemSelected(data.item[item_index-1], false) end
    reaper.SetMediaItemSelected(data.item[item_index], true)
    for k, v in orderedPairs(data.outputs) do
        reaper.InsertMedia(data.outputs[k][item_index], 3)
        local item = reaper.GetSelectedMediaItem(0, 0)
        local take = reaper.GetActiveTake(item)
        reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", data.playrate[item_index])
        reaper.SetMediaItemTakeInfo_Value(take, "I_PITCHMODE", data.playtype[item_index])
    end
end
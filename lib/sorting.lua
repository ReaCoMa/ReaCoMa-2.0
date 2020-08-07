sorting = {}

sorting.container = {
    item = {}, -- table of selected items
    full_path = {},
    descr_cmd = {}, -- command line arguments for spectralshape
    stats_cmd = {}, -- command line arguments for stats
    take_ofs = {},
    take_ofs_samples = {},
    item_len = {},
    item_len_samples = {},
    item_pos = {},
    chans = {},
    descriptor_data = {},
    string_data = {}, -- all the output data as raw strings   
    tmp_descr = {}, -- analysis files made by processor
    tmp_stats = {}, -- stats files made by fluid.bufstats~
    reverse = {},
    sorted_items = {}
}

sorting.get_data = function(item_index, data)
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

    reacoma.utils.check_extension(full_path)
    
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_pos_samples = utils.stosamps(item_pos, sr)
    local src_len = reaper.GetMediaSourceLength(src)
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") * playrate
    local item_len_samples = utils.stosamps(item_len, sr)

    if data.reverse[item_index] then
        take_ofs = math.abs(src_len - (item_len + take_ofs))
    end
    
    -- This line caps the analysis at one loop
    if (item_len + take_ofs) > (src_len * (1 / playrate)) then 
        item_len = (src_len * (1 / playrate))
    end

    local take_ofs_samples = utils.stosamps(take_ofs, sr)
    local item_pos_samples = utils.stosamps(item_pos, sr)
    local item_len_samples = math.floor(utils.stosamps(item_len, sr))
    
    local tmp_descr = full_path .. utils.uuid(item_index) .. "descriptor" .. ".wav"
    local tmp_stats = full_path .. utils.uuid(item_index) .. "stat" .. ".csv"

    table.insert(data.chans, reaper.GetMediaSourceNumChannels(src))
    table.insert(data.item, item)
    table.insert(data.full_path, full_path)
    table.insert(data.tmp_descr, tmp_descr)
    table.insert(data.tmp_stats, tmp_stats)
    table.insert(data.take_ofs, take_ofs)
    table.insert(data.item_len, item_len)
    table.insert(data.item_pos, item_pos)
    table.insert(data.item_len_samples, item_len_samples)
    table.insert(data.take_ofs_samples, take_ofs_samples)
end

return sorting

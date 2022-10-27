container = {}

container.generic = {
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
    take_markers = {},
    path = {},
    playtype = {},
    outputs = {}
}

container.get_data = function(i, data)
    local info = container.get_item_info(i)
    for k, v in pairs(info) do
        table.insert(data[tostring(k)], v)
    end
end

container.get_item_info = function(item_index)
    local info = {}
    local item = reaper.GetSelectedMediaItem(0, item_index-1)
    return container.get_take_info_from_item(item)
    
end

container.get_take_info_from_item = function(item)
    local take = reaper.GetActiveTake(item)
    local take_markers = reaper.GetNumTakeMarkers(take)
    local src = reaper.GetMediaItemTake_Source(take)
    local src_parent = reaper.GetMediaSourceParent(src)
    local sr = nil
    local full_path = nil
    local reverse = nil
    
    if src_parent ~= nil then
        sr = reaper.GetMediaSourceSampleRate(src_parent)
        full_path = reaper.GetMediaSourceFileName(src_parent, "")
        reverse = true
    else
        sr = reaper.GetMediaSourceSampleRate(src)
        full_path = reaper.GetMediaSourceFileName(src, "")
        reverse = false
    end
    
    -- Now check the full path works
    reacoma.utils.check_extension(full_path)

    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local src_len = reaper.GetMediaSourceLength(src)
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") * playrate
    local playtype  = reaper.GetMediaItemTakeInfo_Value(take, "I_PITCHMODE")

    if reverse then
        take_ofs = abs(src_len - (item_len + take_ofs))
    end
    
    if (item_len + take_ofs) > (src_len * (1 / playrate)) then 
        item_len = ((src_len-take_ofs) * (1 / playrate))
    end

    local take_ofs_samples = utils.stosamps(take_ofs, sr)
    local item_pos_samples = utils.stosamps(item_pos, sr)
    local item_len_samples = floor(utils.stosamps(item_len, sr))

    -- Yeah this is verbose but it makes it cleaner
    local info = {

    }
    info.item = item
    info.take = take
    info.take_markers = take_markers
    info.sr = sr
    info.full_path = full_path
    info.take_ofs = take_ofs
    info.take_ofs_samples = take_ofs_samples
    info.item_len = item_len
    info.item_len_samples = item_len_samples
    info.item_pos = item_pos
    info.item_pos_samples = item_pos_samples
    info.playrate = playrate
    info.reverse = reverse
    -- Layers specific stuff
    info.playtype = playtype
    info.path = reacoma.utils.form_path(full_path)
    -- Slicing specific stuff
    info.tmp = full_path .. utils.uuid(item_index or -1) .. "fs.csv"

    return info
end

return container
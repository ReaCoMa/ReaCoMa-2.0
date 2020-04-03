local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "fluidUtils.lua")

fluidSlicing = {}

fluidSlicing.container = {
    full_path = {},
    item_pos = {},
    item_pos_samples = {},
    take_ofs = {},
    take_ofs_samples = {},
    item_len_samples = {},
    cmd = {},
    slice_points_string = {},
    tmp = {},
    item = {},
    reverse = {},
    sr = {},
    playrate = {}
}

fluidSlicing.get_data = function (item_index, data)
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
    
    local tmp = full_path .. fluidUtils.uuid(item_index) .. "fs.csv"
    local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") * playrate
    local src_len = reaper.GetMediaSourceLength(src)

    
    if data.reverse[item_index] then
        take_ofs = math.abs(src_len - (item_len + take_ofs))
    end
    
    -- This line caps the analysis at one loop
    if (item_len + take_ofs) > src_len then 
        item_len = src_len 
    end

    local take_ofs_samples = fluidUtils.stosamps(take_ofs, sr)
    local item_pos_samples = fluidUtils.stosamps(item_pos, sr)
    local item_len_samples = math.floor(fluidUtils.stosamps(item_len, sr) * playrate)

    table.insert(data.item, item)
    table.insert(data.sr, sr)
    table.insert(data.full_path, full_path)
    table.insert(data.take_ofs, take_ofs)
    table.insert(data.take_ofs_samples, take_ofs_samples)
    table.insert(data.item_pos, item_pos)
    table.insert(data.item_pos_samples, item_pos_samples)
    table.insert(data.item_len_samples, item_len_samples)
    table.insert(data.tmp, tmp)
    table.insert(data.playrate, playrate)
end

fluidSlicing.perform_splitting = function (item_index, data)
    local slice_points = fluidUtils.commasplit(data.slice_points_string[item_index])
    if tonumber(slice_points[1]) == data.take_ofs_samples[item_index] then table.remove(slice_points, 1) end

    for j=1, #slice_points do
        local slice_index = j
        slice_pos = fluidUtils.sampstos(
            tonumber(slice_points[slice_index]), 
            data.sr[item_index]
        )
        slice_pos = (data.item_pos[item_index] + slice_pos - data.take_ofs[item_index]) * (1 / data.playrate[item_index]) -- account for playback rate
        data.item[item_index] = reaper.SplitMediaItem(
            data.item[item_index], 
            slice_pos
        )
    end
end

fluidSlicing.perform_gate_splitting = function(item_index, data, init_state)
    local state = init_state
    local slice_points = fluidUtils.commasplit(data.slice_points_string[item_index])

    for j=1, #slice_points do

        if tonumber(slice_points[1]) == data.take_ofs_samples[item_index] then table.remove(slice_points, 1) end

        local slice_index = j
        slice_pos = fluidUtils.sampstos(
            tonumber(slice_points[slice_index]), 
            data.sr[item_index]
        )
        
        slice_pos = (data.item_pos[item_index] + slice_pos - data.take_ofs[item_index]) * (1 / data.playrate[item_index]) -- account for playback rate
        reaper.SetMediaItemInfo_Value(data.item[item_index], "B_MUTE", state)
        data.item[item_index] = reaper.SplitMediaItem(
            data.item[item_index], 
            slice_pos
        )
        if state == 1 then state = 0 else state = 1 end
    end
    reaper.SetMediaItemInfo_Value(data.item[item_index], "B_MUTE", state)
end

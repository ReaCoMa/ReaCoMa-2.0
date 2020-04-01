local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "FluidUtils.lua")

FluidSlicing = {}

FluidSlicing.container = {
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

FluidSlicing.get_data = function (item_index, data)
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
    
    local tmp = full_path .. uuid(item_index) .. "fs.csv"
    local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local src_len = reaper.GetMediaSourceLength(src)
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

    
    if data.reverse[item_index] then
        take_ofs = math.abs((src_len - (item_len * playrate)) + take_ofs)
    end
    
    -- This line caps the analysis at one loop
    if (item_len + take_ofs) > src_len then 
        item_len = src_len 
    end

    local take_ofs_samples = stosamps(take_ofs, sr)
    local item_pos_samples = stosamps(item_pos, sr)
    local item_len_samples = math.floor(stosamps(item_len, sr) * playrate)

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

FluidSlicing.perform_splitting = function (item_index, data)
    slice_points = commasplit(data.slice_points_string[item_index])
    -- Invert the points if they are reverse
    -- Containerise this into a function

    for j=2, #slice_points do
        local slice_index = j
        slice_pos = sampstos(
            tonumber(slice_points[slice_index]), 
            data.sr[item_index]
        )

        -- slice_pos = slice_pos * (1.0 / data.playrate[item_index]) - data.take_ofs[item_index] -- account for playback rate
        slice_pos = (slice_pos - data.take_ofs[item_index]) * (1 / data.playrate[item_index]) -- account for playback rate

        data.item[item_index] = reaper.SplitMediaItem(
            data.item[item_index], 
            data.item_pos[item_index] + (slice_pos - (data.take_ofs[item_index] * (1 / data.playrate[item_index])))
        )
    end
end

FluidSlicing.perform_gate_splitting = function(item_index, data, init_state)
    local state = init_state
    slice_points = commasplit(data.slice_points_string[item_index])
    for j=2, #slice_points do
        local slice_index = j
        slice_pos = sampstos(
            tonumber(slice_points[slice_index]), 
            data.sr[item_index]
        )

        slice_pos = (slice_pos - data.take_ofs[item_index]) * (1 / data.playrate[item_index]) -- account for playback rate

        reaper.SetMediaItemInfo_Value(data.item[item_index], "B_MUTE", state)
        data.item[item_index] = reaper.SplitMediaItem(
            data.item[item_index], 
            data.item_pos[item_index] + (slice_pos - (data.take_ofs[item_index] * (1 / data.playrate[item_index])))
        )
        if state == 1 then state = 0 else state = 1 end
        -- invert the state
    end
    reaper.SetMediaItemInfo_Value(data.item[item_index], "B_MUTE", state)
end
